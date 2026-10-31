# Empresa Recolectora – FastAPI + React + MySQL 8 (Docker)

La **lógica vive en la BD** (procedimientos, funciones, cursores, triggers).
El backend solo las llama y el frontend solo muestra los resultados.

## Levantar todo

Requisito: Docker Desktop (o Docker + Compose).

```bash
docker compose up --build
```

| Servicio  | URL                         |
|-----------|-----------------------------|
| Frontend  | http://localhost:5173       |
| API docs  | http://localhost:8000/docs  |
| MySQL     | `localhost:3307` (usuario `recolectora` / clave `recolectora`, root / `root`) |

Al primer arranque MySQL ejecuta `db/init/*.sql` en orden alfabético:

1. `01_schema_y_datos.sql` – tus 15 tablas con datos
2. `02_auditoria_historiales.sql` – `AUDITORIA_RECOLECCION`, `HISTORIAL_PRECIO_MATERIAL`, `HISTORIAL_ASIGNACION_RECOLECTOR`
3. `03_logica.sql` – (opcional) tus procedimientos, funciones, cursores y triggers.
   Hay un ejemplo en `03_logica.sql.ejemplo`; quítale `.ejemplo` para activarlo.

> Esos scripts **solo corren cuando el volumen está vacío**. Para rehacer la BD:
> `docker compose down -v && docker compose up --build`

## Probar la BD

- Pantalla **Estado de la BD** en el frontend (conexión, tablas, qué lógica falta crear).
- `curl localhost:8000/db/test`
- Pruebas automáticas: `docker compose exec backend pytest -q`

## Dónde tocar cuando crees la lógica en MySQL

`backend/app/catalogo.py` es el único archivo que conoce los nombres y parámetros de tus
rutinas. Si tu procedimiento recibe otros parámetros, cámbialos ahí y el formulario del
frontend se actualiza solo. Convenciones:

- **Procedimientos** → `POST /procedimientos/{key}`. Para devolver datos termina con un `SELECT`
  (por ejemplo el "total del día").
- **Funciones** → `GET /funciones/{key}?param=valor`.
- **Cursores** → en MySQL viven dentro de un procedimiento. `c_*` debe ser un procedimiento sin
  parámetros que termine en uno o varios `SELECT` (puedes usar una tabla temporal).
- **Triggers** → se disparan solos; los `SIGNAL SQLSTATE '45000'` llegan al frontend como error 400
  con tu mensaje.
- Si una rutina aún no existe, la API responde **501** y el frontend lo muestra; no se rompe nada.

## Estructura

```
docker-compose.yml
db/init/            scripts SQL (se ejecutan al crear la BD)
backend/app/        main.py, db.py, catalogo.py, routers/ (health, tablas, logica)
backend/tests/      pruebas de integración contra la BD
frontend/src/       App.jsx, api.js, components/, pages/
```
