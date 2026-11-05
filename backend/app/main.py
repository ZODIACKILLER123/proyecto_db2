import os
from contextlib import asynccontextmanager

import pymysql
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .db import wait_for_db
from .instalacion import instalar_rutinas
from .routers import health, logica, tablas, estadisticas, alertas

@asynccontextmanager
async def lifespan(_: FastAPI):
    wait_for_db()  # reintenta por si MySQL todavia esta iniciando
    instalar_rutinas()  # repara volumen existente: no toca tablas ni datos
    yield


app = FastAPI(title="Empresa Recolectora API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:5173").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(pymysql.MySQLError)
async def error_mysql(_: Request, exc: pymysql.MySQLError):
    """Traduce errores de MySQL (incluidos SIGNAL de triggers/procedimientos)."""
    codigo = exc.args[0] if exc.args else 0
    mensaje = exc.args[1] if len(exc.args) > 1 else str(exc)
    if codigo == 1644:                                   # SIGNAL SQLSTATE '45000'
        estado = 400
    elif codigo in (1062, 1451, 1452, 3819, 4025):       # unique, FK, CHECK
        estado = 409
    elif codigo in (1146, 1305):                         # tabla / rutina no existe
        estado = 404 if codigo == 1146 else 501
        mensaje = f"No existe en la BD todavia: {mensaje}"
    elif codigo == 1318:                                 # numero de parametros
        estado = 422
        mensaje = f"La firma en la BD no coincide con app/catalogo.py: {mensaje}"
    elif codigo in (1045, 2002, 2003, 2006, 2013):       # conexion / credenciales
        estado = 503
    else:
        estado = 500
    return JSONResponse(status_code=estado, content={"detail": mensaje, "mysql_code": codigo})


app.include_router(health.router)
app.include_router(tablas.router)
app.include_router(logica.router)
app.include_router(estadisticas.router)
app.include_router(alertas.router)
