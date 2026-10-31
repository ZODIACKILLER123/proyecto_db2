import { useEffect, useState } from 'react'
import { api } from '../api.js'

const LIMITE = 15

export function Filas({ filas }) {
  if (!filas?.length) return <p className="vacio">Sin filas.</p>
  const columnas = Object.keys(filas[0])
  return (
    <div className="tabla-scroll">
      <table>
        <thead>
          <tr>{columnas.map((c) => <th key={c}>{c}</th>)}</tr>
        </thead>
        <tbody>
          {filas.map((f, i) => (
            <tr key={i}>{columnas.map((c) => <td key={c}>{String(f[c] ?? '')}</td>)}</tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// Tabla de la BD con paginacion simple
export default function DataTable({ tabla, refrescar }) {
  const [pagina, setPagina] = useState(0)
  const [datos, setDatos] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => setPagina(0), [tabla])
  useEffect(() => {
    setError('')
    api.get(`/tablas/${tabla}?limit=${LIMITE}&offset=${pagina * LIMITE}`)
      .then(setDatos)
      .catch((e) => { setDatos(null); setError(e.message) })
  }, [tabla, pagina, refrescar])

  if (error) return <p className="error">{error}</p>
  if (!datos) return <p className="vacio">Cargando…</p>
  const paginas = Math.max(1, Math.ceil(datos.total / LIMITE))
  return (
    <div>
      <Filas filas={datos.filas} />
      <div className="paginacion">
        <button disabled={pagina === 0} onClick={() => setPagina(pagina - 1)}>Anterior</button>
        <span>{datos.total} filas · página {pagina + 1} de {paginas}</span>
        <button disabled={pagina + 1 >= paginas} onClick={() => setPagina(pagina + 1)}>Siguiente</button>
      </div>
    </div>
  )
}
