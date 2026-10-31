"""Conexion a MySQL y helpers para tablas, funciones y procedimientos."""
import os
import time
from contextlib import contextmanager

import pymysql
from pymysql.cursors import DictCursor


def _config() -> dict:
    return dict(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "recolectora"),
        password=os.getenv("DB_PASSWORD", "recolectora"),
        database=os.getenv("DB_NAME", "empresa_recolectora"),
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=False,
        connect_timeout=5,
    )


@contextmanager
def get_conn():
    """Una conexion por peticion: commit si todo sale bien, rollback si falla."""
    conn = pymysql.connect(**_config())
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def wait_for_db(intentos: int = 30, espera: float = 2.0) -> None:
    """Reintenta al arrancar por si MySQL todavia esta inicializando."""
    for _ in range(intentos):
        try:
            with get_conn() as conn, conn.cursor() as cur:
                cur.execute("SELECT 1")
            return
        except pymysql.MySQLError:
            time.sleep(espera)


def fetch_all(sql: str, params=()) -> list[dict]:
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(sql, params)
        return list(cur.fetchall())


def fetch_one(sql: str, params=()) -> dict | None:
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def execute(sql: str, params=()) -> int:
    with get_conn() as conn, conn.cursor() as cur:
        return cur.execute(sql, params)


def call_function(nombre: str, args: list) -> object:
    """SELECT f(...). `nombre` siempre sale del catalogo, nunca del usuario."""
    marcas = ", ".join(["%s"] * len(args))
    fila = fetch_one(f"SELECT `{nombre}`({marcas}) AS resultado", args)
    return fila["resultado"] if fila else None


def call_procedure(nombre: str, args: list) -> list[list[dict]]:
    """CALL p(...). Devuelve todos los result sets (sirve para cursores)."""
    with get_conn() as conn, conn.cursor() as cur:
        cur.callproc(nombre, args)
        conjuntos = []
        while True:
            if cur.description:
                conjuntos.append(list(cur.fetchall()))
            if not cur.nextset():
                break
        return conjuntos
