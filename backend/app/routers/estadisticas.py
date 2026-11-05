"""Métricas y gráficas obtenidas de registros reales; nunca datos de muestra simulados."""
from datetime import date
from fastapi import APIRouter, HTTPException, Query
from ..db import fetch_all, fetch_one

router = APIRouter(prefix='/dashboard', tags=['Panel de estadísticas'])


@router.get('/fechas')
def fechas():
    d = fetch_one('''
        SELECT MIN(fecha) AS primera, MAX(fecha) AS ultima FROM (
          SELECT MIN(fecha) fecha FROM RECOLECTA
          UNION ALL SELECT MAX(fecha) fecha FROM RECOLECTA
          UNION ALL SELECT MIN(DATE(fecha)) fecha FROM DESCARGA_BOTADERO
          UNION ALL SELECT MAX(DATE(fecha)) fecha FROM DESCARGA_BOTADERO
        ) fechas
    ''')
    return {'primera': d['primera'], 'ultima': d['ultima']}


def comprobar(desde, hasta):
    if desde > hasta:
        raise HTTPException(422, 'La fecha inicial debe ser anterior o igual a la fecha final')
    if (hasta - desde).days > 3660:
        raise HTTPException(422, 'Selecciona un período máximo de 10 años')


@router.get('/resumen')
def resumen(desde: date = Query(...), hasta: date = Query(...)):
    comprobar(desde, hasta)
    dates = (desde, hasta)
    d = fetch_one('''SELECT COUNT(*) recolecciones,
          COALESCE(SUM(cantidad_kg),0) kilos,
          COUNT(DISTINCT idrecolector) recolectores_activos,
          COUNT(DISTINCT idRuta) rutas_atendidas,
          COUNT(DISTINCT idContenedor) contenedores_atendidos
          FROM RECOLECTA WHERE fecha BETWEEN %s AND %s''', dates)
    descargas = fetch_one('''SELECT COUNT(*) descargas, COALESCE(SUM(cantidad_kg),0) kilos_descargados
             FROM DESCARGA_BOTADERO WHERE fecha >= %s AND fecha < DATE_ADD(%s, INTERVAL 1 DAY)
               AND estado='Confirmada' ''', dates)
    base = fetch_one('''SELECT
      (SELECT COUNT(*) FROM ZONA) zonas,
      (SELECT COUNT(*) FROM RUTA) rutas,
      (SELECT COUNT(*) FROM TRANSPORTE) transportes,
      (SELECT COUNT(*) FROM RECOLECTOR) recolectores,
      (SELECT COUNT(*) FROM CONTENEDOR) contenedores,
      (SELECT COUNT(*) FROM BOTADERO) botaderos''')
    diario = fetch_all('''SELECT fecha, COUNT(*) recolecciones, ROUND(SUM(cantidad_kg),2) kilos
               FROM RECOLECTA WHERE fecha BETWEEN %s AND %s
               GROUP BY fecha ORDER BY fecha''', dates)
    destinos = fetch_all('''SELECT b.nombre, COUNT(*) operaciones, ROUND(SUM(d.cantidad_kg),2) kilos
            FROM DESCARGA_BOTADERO d JOIN BOTADERO b ON b.idBotadero=d.idBotadero
            WHERE d.fecha >= %s AND d.fecha < DATE_ADD(%s,INTERVAL 1 DAY)
              AND d.estado='Confirmada'
            GROUP BY b.idBotadero,b.nombre ORDER BY kilos DESC LIMIT 6''', dates)
    zonas = fetch_all('''SELECT z.nombre, COUNT(*) operaciones, ROUND(SUM(rc.cantidad_kg),2) kilos
             FROM RECOLECTA rc JOIN RUTA r ON r.idRuta=rc.idRuta
             JOIN ZONA z ON z.idZona=r.idZona
             WHERE rc.fecha BETWEEN %s AND %s
             GROUP BY z.idZona,z.nombre ORDER BY kilos DESC LIMIT 7''', dates)
    materiales = fetch_one('''SELECT COALESCE(SUM(stock_actual),0) unidades,
                     SUM(CASE WHEN stock_actual<=stock_minimo THEN 1 ELSE 0 END) alertas
                     FROM MATERIAL_TRABAJO''')
    recientes = fetch_all('''SELECT rc.idRecoleccion AS id, rc.fecha,
             z.nombre AS zona, rc.cantidad_kg AS kilos, p.nombre AS recolector
             FROM RECOLECTA rc
             LEFT JOIN RUTA r ON r.idRuta=rc.idRuta
             LEFT JOIN ZONA z ON z.idZona=r.idZona
             JOIN PERSONA p ON p.idPersona=rc.idrecolector
             WHERE rc.fecha BETWEEN %s AND %s
             ORDER BY rc.fecha DESC, rc.idRecoleccion DESC LIMIT 5''', dates)
    return {'periodo': {'desde': desde, 'hasta': hasta}, 'base': base,
            'operacion': {**d, **descargas}, 'inventario': materiales,
            'serie_diaria': diario, 'zonas': zonas, 'botaderos': destinos,
            'recientes': recientes}
