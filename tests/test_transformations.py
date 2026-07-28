"""Testes offline do pipeline: rodam sem Spark, sem credencial e sem workspace.

Cobrem a classe de erro que o `bundle deploy` NAO pega: o deploy fica verde e o
pipeline so quebra quando roda -- ou pior, roda no ambiente errado.

DESCOBERTA DINAMICA (importante para o workshop): nada aqui depende de o agente ter
escolhido um nome de arquivo especifico. O recurso de pipeline e achado varrendo
`resources/*.yml`, e o SQL e achado varrendo `src/**/*.sql`. Assim, se a IA gerar
`pipelines.yml` em vez de `bakehouse_pipeline.yml`, os testes continuam valendo.
"""

import re
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parent.parent
LAYERS = ("bronze", "silver", "gold")

PLACEHOLDER = re.compile(r"\$\{([a-zA-Z_][\w.]*)\}")
CREATE = re.compile(
    r"CREATE\s+OR\s+(?:REFRESH|REPLACE)\s+(?:STREAMING\s+TABLE|MATERIALIZED\s+VIEW)\s+([^\s(;]+)",
    re.IGNORECASE,
)
SCHEMA_RESOURCE = re.compile(r"resources\.schemas\.(\w+)\.name")


# --------------------------------------------------------------------------- descoberta


def _pipeline() -> dict:
    """Primeiro recurso de pipeline declarado em resources/*.yml."""
    for yml in sorted((REPO / "resources").glob("*.yml")):
        doc = yaml.safe_load(yml.read_text()) or {}
        pipelines = (doc.get("resources") or {}).get("pipelines") or {}
        for spec in pipelines.values():
            return spec or {}
    raise AssertionError("nenhum recurso 'pipelines:' encontrado em resources/*.yml")


def _catalogos_de_ambiente() -> set[str]:
    """Catalogos concretos usados pelos targets do databricks.yml (ex.: bakehouse_dev)."""
    doc = yaml.safe_load((REPO / "databricks.yml").read_text()) or {}
    nomes = set()
    for target in (doc.get("targets") or {}).values():
        valor = ((target or {}).get("variables") or {}).get("catalog")
        if isinstance(valor, str) and "${" not in valor:
            nomes.add(valor)
    return nomes


SQL_FILES = sorted((REPO / "src").rglob("*.sql"))
CONFIG = _pipeline().get("configuration") or {}
CATALOGOS = _catalogos_de_ambiente()


def ids(p: Path) -> str:
    return str(p.relative_to(REPO))


def catalogos_vazados(texto: str) -> set[str]:
    """Catalogo de ambiente escrito como QUALIFICADOR RAIZ de um nome.

    O lookbehind evita o falso positivo classico: o catalogo de prod se chama `bakehouse`
    e a fonte e `samples.bakehouse.sales_customers` -- ali `bakehouse` e schema da fonte,
    vem depois de um ponto, e nao e hardcode nenhum.
    """
    return {c for c in CATALOGOS if re.search(rf"(?<![\w.${{]){re.escape(c)}\b", texto)}


def resolve_camada(token: str) -> str | None:
    """'${silver_schema}' | 'silver' -> 'silver'. Devolve None se nao for uma camada."""
    chave = token.strip("${}").strip('`"')
    valor = str(CONFIG.get(chave, chave))
    achado = SCHEMA_RESOURCE.search(valor)
    if achado:
        valor = achado.group(1)
    valor = valor.strip("${}").removesuffix("_schema")
    return valor if valor in LAYERS else None


# --------------------------------------------------------------------------- testes


def test_existe_sql_para_o_pipeline_carregar():
    assert SQL_FILES, "nenhum .sql em src/ -- o pipeline nao tem o que carregar"


def test_as_tres_camadas_existem_como_schema_do_bundle():
    """O desenho do workshop: o schema E a camada, declarada como recurso do bundle."""
    declarados = set()
    for yml in sorted((REPO / "resources").glob("*.yml")):
        doc = yaml.safe_load(yml.read_text()) or {}
        declarados |= set((doc.get("resources") or {}).get("schemas") or {})
    faltando = set(LAYERS) - {s.lower() for s in declarados}
    assert not faltando, f"schemas nao declarados como recurso do bundle: {faltando}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_placeholder_do_sql_esta_declarado_no_pipeline(sql):
    """${bronze_shema} com typo deploya sem erro e so morre em runtime."""
    usados = set(PLACEHOLDER.findall(sql.read_text()))
    nao_declarados = usados - set(CONFIG)
    assert not nao_declarados, f"nao declarados em configuration: {nao_declarados}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_camada_bate_com_a_pasta(sql):
    """gold/ so pode escrever em gold. Aceita nome de 2 ou 3 partes, literal ou ${}."""
    pasta = sql.parent.name.lower()
    if pasta not in LAYERS:
        pytest.skip(f"'{pasta}' nao e uma pasta de camada")

    escritas = set()
    for alvo in CREATE.findall(sql.read_text()):
        partes = alvo.split(".")
        token = partes[-2] if len(partes) >= 2 else str(_pipeline().get("schema") or "")
        camada = resolve_camada(token)
        if camada:
            escritas.add(camada)

    if not escritas:
        pytest.skip("sem CREATE de tabela/MV neste arquivo")
    assert escritas == {pasta}, f"arquivo em {pasta}/ escreve em {escritas}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_sem_catalogo_de_ambiente_hardcoded(sql):
    """O catalogo vem do bundle. Hardcode faz o prod escrever no dev -- silenciosamente."""
    vazados = catalogos_vazados(sql.read_text())
    assert not vazados, f"catalogo de ambiente hardcoded: {vazados} -- parametrize com ${{...}}"


def _valores(no) -> list[str]:
    """Todos os valores string de uma arvore YAML."""
    if isinstance(no, dict):
        return [v for filho in no.values() for v in _valores(filho)]
    if isinstance(no, list):
        return [v for filho in no for v in _valores(filho)]
    return [no] if isinstance(no, str) else []


@pytest.mark.parametrize("yml", sorted((REPO / "resources").glob("*.yml")), ids=lambda p: str(p.relative_to(REPO)))
def test_recurso_sem_catalogo_de_ambiente_hardcoded(yml):
    """`catalog_name: bakehouse_dev` num recurso faz o deploy de PROD gravar no DEV.

    Silencioso: o deploy fica verde, o pipeline roda verde, e as tabelas aparecem no
    catalogo errado. O catalogo tem que vir de ${var.catalog}.
    """
    vazados = set()
    for valor in _valores(yaml.safe_load(yml.read_text()) or {}):
        raiz = valor.split(".")[0].strip()
        if raiz in CATALOGOS:
            vazados.add(raiz)
    assert not vazados, f"catalogo de ambiente hardcoded no recurso: {vazados} -- use ${{var.catalog}}"


@pytest.mark.parametrize("dash", sorted((REPO / "src").rglob("*.lvdash.json")), ids=lambda p: str(p.relative_to(REPO)))
def test_dashboard_sem_catalogo_hardcoded(dash):
    """Dashboard com catalogo no JSON quebra ao trocar de target. Use dataset_catalog/schema."""
    vazados = catalogos_vazados(dash.read_text())
    assert not vazados, f"catalogo de ambiente hardcoded no dashboard: {vazados}"
