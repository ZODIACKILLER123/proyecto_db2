"""Instala rutinas del SQL original sin tocar las tablas ni los registros.

MySQL Docker ejecuta /docker-entrypoint-initdb.d únicamente la primera vez que
crea su volumen. Este instalador repara instalaciones con tablas, pero sin rutinas.
"""
import logging
from pathlib import Path

from .db import get_conn

LOG = logging.getLogger(__name__)
SQL_DIR = Path('/app/sql')
SCRIPTS = ('02_funciones.sql', '03_procedimientos.sql',
           '04_triggers_empresa_recolectora.sql', '05_cursores_empresa_recolectora.sql')
LAST_STATUS = {'estado': 'pendiente', 'archivos': [], 'errores': []}


def separar_sql(archivo):
    """Interpreta DELIMITER de mysql CLI (PyMySQL no lo soporta directamente)."""
    delimiter = ';'
    partes = []
    for line in archivo.read_text(encoding='utf-8-sig').splitlines(keepends=True):
        stripped = line.strip()
        if stripped.upper().startswith('DELIMITER '):
            delimiter = stripped.split(None, 1)[1]
            continue
        if not partes and (not stripped or stripped.startswith('--') or stripped.startswith('#')):
            continue
        partes.append(line)
        joined = ''.join(partes).rstrip()
        if joined.endswith(delimiter):
            stmt = joined[:-len(delimiter)].strip()
            if stmt:
                yield stmt
            partes = []
    resto = ''.join(line for line in partes if line.strip() and not line.lstrip().startswith(('--', '#'))).strip()
    if resto:
        raise ValueError(f'Sentencia incompleta en {archivo.name}: {resto[:100]}')


def instalar_rutinas():
    """Reaplica rutinas desde el SQL, sin ejecutar 01_schema_y_datos.sql.

    DDL MySQL auto-confirma; un error se registra, nunca se ignora silenciosamente.
    """
    status = {'estado': 'correcto', 'archivos': [], 'errores': []}
    try:
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ZONA'")
            if not cur.fetchone()['n']:
                status['estado'] = 'sin_esquema'
                status['errores'].append('No existe ZONA. Revisa la inicialización de 01_schema_y_datos.sql.')
                LAST_STATUS.update(status)
                return status
            for filename in SCRIPTS:
                path = SQL_DIR / filename
                if not path.is_file():
                    status['errores'].append(f'No se encontró {path}')
                    continue
                numero = 0
                try:
                    for stmt in separar_sql(path):
                        # No ejecutar SELECT de demostración al instalar; solo DDL.
                        if stmt.lstrip().upper().startswith(('SELECT ', 'CALL ')):
                            continue
                        cur.execute(stmt)
                        while cur.nextset():
                            pass
                        numero += 1
                    status['archivos'].append({'archivo': filename, 'sentencias': numero, 'ok': True})
                except Exception as e:
                    detalle = f'{filename}: sentencia {numero + 1}: {e}'
                    status['errores'].append(detalle)
                    status['archivos'].append({'archivo': filename, 'sentencias': numero, 'ok': False})
                    LOG.exception('Fallo al instalar rutina: %s', detalle)
    except Exception as e:
        status['errores'].append(f'No se pudo instalar: {e}')
        LOG.exception('Error al verificar el esquema')
    if status['errores']:
        status['estado'] = 'con_errores'
    LAST_STATUS.update(status)
    return status


if __name__ == '__main__':
    import json
    logging.basicConfig(level=logging.INFO)
    print(json.dumps(instalar_rutinas(), ensure_ascii=False, indent=2))
