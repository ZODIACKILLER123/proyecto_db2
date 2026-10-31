import { useState } from 'react'
import { api } from '../api.js'
import { Filas } from './DataTable.jsx'

const TIPO_INPUT = { text: 'text', number: 'number', date: 'date' }

// Formulario generado desde el catalogo del backend (app/catalogo.py)
export default function RoutineForm({ item, onDone }) {
  const [valores, setValores] = useState({})
  const [estado, setEstado] = useState({ cargando: false, error: '', resultado: null })

  async function enviar(e) {
    e.preventDefault()
    setEstado({ cargando: true, error: '', resultado: null })
    try {
      const resultado = await api.ejecutar(item, valores)
      setEstado({ cargando: false, error: '', resultado })
      onDone?.()
    } catch (err) {
      setEstado({ cargando: false, error: err.message, resultado: null })
    }
  }

  const { resultado } = estado
  const accion = item.kind === 'funcion' ? 'Consultar' : item.kind === 'cursor' ? 'Generar reporte' : 'Ejecutar'

  return (
    <form className="rutina" onSubmit={enviar}>
      <h3>{item.titulo}</h3>
      <p className="nota">{item.descripcion}{item.routine && <> Llama a <code>{item.routine}</code>.</>}</p>
      {item.params.length > 0 && (
        <div className="campos">
          {item.params.map((p) => (
            <label key={p.name}>
              {p.label}{!p.requerido && ' (opcional)'}
              <input
                type={TIPO_INPUT[p.tipo]}
                step={p.tipo === 'number' ? 'any' : undefined}
                required={p.requerido}
                value={valores[p.name] ?? ''}
                onChange={(e) => setValores({ ...valores, [p.name]: e.target.value })}
              />
            </label>
          ))}
        </div>
      )}
      <button type="submit" disabled={estado.cargando}>{estado.cargando ? 'Ejecutando…' : accion}</button>

      {estado.error && <p className="error">{estado.error}</p>}
      {resultado && 'resultado' in resultado && (
        <p className="ok">Resultado: <strong>{String(resultado.resultado ?? 'NULL')}</strong></p>
      )}
      {resultado?.resultados && (
        resultado.resultados.length === 0
          ? <p className="ok">Ejecutado sin filas de retorno.</p>
          : resultado.resultados.map((filas, i) => (
              <div key={i}>
                {resultado.resultados.length > 1 && <p className="nota">Conjunto {i + 1}</p>}
                <Filas filas={filas} />
              </div>
            ))
      )}
      {resultado?.ok && <p className="ok">Cambio guardado.</p>}
    </form>
  )
}
