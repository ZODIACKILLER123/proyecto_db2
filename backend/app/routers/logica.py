"""Ejecuta solo rutinas permitidas por el catálogo; los triggers operan en MySQL."""
from datetime import date, datetime, time
from fastapi import APIRouter, HTTPException, Request
from .. import catalogo
from ..db import call_function, call_procedure, fetch_all

router=APIRouter(tags=['Operaciones y análisis'])


def valores(definicion,datos):
    salida=[]
    for p in definicion['params']:
        v=datos.get(p['name'])
        if v is None or v=='':
            if p['requerido']:
                raise HTTPException(422,f"Completa el campo: {p['label']}")
            salida.append(None); continue
        try:
            if p['tipo']=='number': v=float(v) if '.' in str(v) else int(v)
            elif p['tipo']=='date': v=date.fromisoformat(str(v)).isoformat()
            elif p['tipo']=='time': v=time.fromisoformat(str(v)).strftime('%H:%M:%S')
            elif p['tipo']=='datetime-local': v=datetime.fromisoformat(str(v)).strftime('%Y-%m-%d %H:%M:%S')
        except ValueError:
            raise HTTPException(422,f"Formato inválido: {p['label']}") from None
        salida.append(v)
    if 'p_desde' in datos and 'p_hasta' in datos and datos['p_desde'] > datos['p_hasta']:
        raise HTTPException(422,'La fecha inicial debe ser anterior o igual a la final')
    return salida


def definicion(grupo,key):
    if key not in grupo: raise HTTPException(404,'Operación no disponible')
    return grupo[key]

@router.get('/logica/catalogo')
def ver_catalogo(): return catalogo.catalogo_publico()

@router.post('/procedimientos/{key}')
async def procedimiento(key:str, request:Request):
    d=definicion(catalogo.PROCEDIMIENTOS,key)
    datos=await request.json()
    return {'routine':d['routine'],'resultados':call_procedure(d['routine'],valores(d,datos))}

@router.get('/funciones/{key}')
def funcion(key:str,request:Request):
    d=definicion(catalogo.FUNCIONES,key)
    return {'routine':d['routine'],'resultado':call_function(d['routine'],valores(d,dict(request.query_params)))}

@router.get('/cursores/{key}')
def cursor(key:str,request:Request):
    d=definicion(catalogo.CURSORES,key)
    return {'routine':d['routine'],'resultados':call_procedure(d['routine'],valores(d,dict(request.query_params)))}

@router.get('/opciones/{tabla}')
def opciones(tabla:str):
    tabla=tabla.upper()
    nombres={'PERSONA':('idPersona',"CONCAT(nombre,' ',paterno)",'nombre'),
      'RECOLECTOR':('idrecolector',"CONCAT(p.nombre,' ',p.paterno)",'nombre'),
      'RUTA':('idRuta',"CONCAT('Ruta ',idRuta,' · Zona ',idZona)",'nombre'),
      'ZONA':('idZona','nombre','nombre'), 'BOTADERO':('idBotadero','nombre','nombre'),
      'TRANSPORTE':('idTransporte',"CONCAT(placa,' · ',tipo_transporte)",'nombre'),
      'CONTENEDOR':('idContenedor',"CONCAT('Contenedor ',idContenedor,' · ',tipo)",'nombre'),
      'MATERIAL_TRABAJO':('idMaterial','nombre','nombre')}
    if tabla not in nombres: raise HTTPException(404,'Catálogo no permitido')
    idcol,display,_=nombres[tabla]
    if tabla=='RECOLECTOR':
        sql=f'SELECT r.idrecolector AS id, {display} AS nombre FROM RECOLECTOR r JOIN PERSONA p ON p.idPersona=r.idrecolector ORDER BY r.idrecolector LIMIT 500'
    else:
        sql=f'SELECT `{idcol}` AS id, {display} AS nombre FROM `{tabla}` ORDER BY `{idcol}` LIMIT 500'
    return fetch_all(sql)
