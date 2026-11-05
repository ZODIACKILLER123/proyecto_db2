"""Pruebas de integración: ejecutar con la BD levantada (docker compose exec backend pytest -q)."""
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.catalogo import TABLAS, FUNCIONES, PROCEDIMIENTOS, CURSORES, TRIGGERS
client=TestClient(app)


def test_health():
    r=client.get('/health')
    assert r.status_code==200
    assert r.json()['base']=='empresa_recolectora'


@pytest.mark.parametrize('tabla',list(TABLAS))
def test_tablas_existen(tabla):
    r=client.get(f'/tablas/{tabla}?limit=1')
    assert r.status_code==200,r.text


def test_cuatro_tablas_nuevas():
    assert {'COMPRA_MATERIAL','DEVOLUCION_MATERIAL','DESCARGA_BOTADERO','HISTORIAL_ASIGNACION'} <= set(TABLAS)


def test_datos_originales():
    assert client.get('/tablas/ZONA?limit=1').json()['total'] == 100
    assert client.get('/tablas/PERSONA?limit=1').json()['total'] == 200


def test_solo_rutinas_actuales():
    items=client.get('/logica/catalogo').json()
    assert len(items)==15
    assert len(FUNCIONES)==len(PROCEDIMIENTOS)==len(CURSORES)==len(TRIGGERS)==5
    assert {x['kind'] for x in items}=={'funcion','procedimiento','cursor'}


def test_seguridad_tabla_no_permitida():
    assert client.get('/tablas/mysql.user').status_code==404
    assert client.get('/opciones/mysql.user').status_code==404


def test_opciones_para_formularios():
    r=client.get('/opciones/ZONA')
    assert r.status_code==200
    assert len(r.json())>0
    assert {'id','nombre'}<=set(r.json()[0])


def test_validacion_fechas():
    r=client.get('/funciones/zona?p_zona=1&p_desde=2026-10-30&p_hasta=2026-09-01')
    assert r.status_code==422


def test_funcion_operativa():
    r=client.get('/funciones/zona?p_zona=1&p_desde=2026-09-01&p_hasta=2026-09-30')
    assert r.status_code==200,r.text
    assert r.json()['routine']=='f_analisis_operativo_zona'


def test_cursor_reporte():
    r=client.get('/cursores/zonas?p_desde=2026-09-01&p_hasta=2026-09-30')
    assert r.status_code==200,r.text
    assert r.json()['resultados']
