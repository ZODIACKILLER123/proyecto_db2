"""Pruebas de integracion contra la BD real.
Ejecutar:  docker compose exec backend pytest -q
"""
import pytest
from fastapi.testclient import TestClient

from app.catalogo import TABLAS
from app.main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["base"] == "empresa_recolectora"


@pytest.mark.parametrize("tabla", list(TABLAS))
def test_tablas_existen(tabla):
    r = client.get(f"/tablas/{tabla}?limit=1")
    assert r.status_code == 200, r.text


def test_datos_base_cargados():
    assert client.get("/tablas/ZONA?limit=1").json()["total"] == 100
    assert client.get("/tablas/PERSONA?limit=1").json()["total"] == 200


def test_tabla_no_permitida():
    assert client.get("/tablas/mysql.user").status_code == 404


def test_catalogo_tiene_las_cuatro_clases():
    tipos = {i["kind"] for i in client.get("/logica/catalogo").json()}
    assert tipos == {"procedimiento", "funcion", "cursor", "dml"}


def test_rutina_inexistente_da_501_o_200():
    # 501 mientras no la crees en la BD; 200 cuando ya exista
    r = client.get("/funciones/estado_operativo_transporte?p_idTransporte=1")
    assert r.status_code in (200, 501)


def test_estado_operativo_transporte_no_depende_de_la_fecha_actual():
    r = client.get("/funciones/estado_operativo_transporte?p_idTransporte=1")
    if r.status_code == 200:
        assert r.json()["resultado"] == "OPERATIVO"


def test_parametro_obligatorio():
    assert client.get("/funciones/capacidad_total_botadero").status_code == 422


def test_capacidad_total_botadero_no_depende_de_la_fecha_actual():
    r = client.get("/funciones/capacidad_total_botadero?p_idBotadero=1")
    if r.status_code == 200:
        assert float(r.json()["resultado"]) == 22.0
