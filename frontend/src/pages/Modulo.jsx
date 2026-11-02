import { useEffect, useState } from 'react'
import DataTable from '../components/DataTable.jsx'
import RoutineForm from '../components/RoutineForm.jsx'
import Modal from '../components/Modal.jsx'

// Un modulo de la capa 1 = tablas para consultar + rutinas de la BD para ejecutar.
export default function Modulo({ modulo, catalogo }) {
  const [tabla, setTabla] = useState(modulo.tablas[0])
  const [version, setVersion] = useState(0)
  const [abierta, setAbierta] = useState(null)
  const [aviso, setAviso] = useState('')
  useEffect(() => {
    if (!aviso) return
    const t = setTimeout(() => setAviso(''), 5000)
    return () => clearTimeout(t)
  }, [aviso])
  function alGuardar(resultado) {
    setVersion((v) => v + 1)
    // Las funciones solo consultan: la ventana queda abierta para mostrar el resultado.
    if (rutinaAbierta?.kind === 'funcion') return
    setAviso(resultado?.resultados?.[0]?.[0]?.mensaje ?? 'Operación realizada.')
    setAbierta(null)
  }

  // Aspecto del boton segun el tipo de operacion
  function boton(r) {
    if (r.kind === 'funcion') return { clase: 'btn-anadir btn-consulta', prefijo: '' }
    if (r.key.startsWith('eliminar')) return { clase: 'btn-anadir btn-peligro', prefijo: '✕ ' }
    return { clase: 'btn-anadir', prefijo: '+ ' }
  }

  const conModal = Boolean(modulo.rutinasPorTabla)
  const claves = modulo.rutinasPorTabla?.[tabla] ?? modulo.rutinas ?? []
  const rutinas = claves.map((k) => catalogo.find((c) => c.key === k)).filter(Boolean)
  const rutinaAbierta = rutinas.find((r) => r.key === abierta)
  // Claves de App.jsx que no existen en backend/app/catalogo.py (sin esto el boton desaparece en silencio)
  const faltantes = catalogo.length > 0 ? claves.filter((k) => !catalogo.some((c) => c.key === k)) : []

  return (
    <section>
      <h2>{modulo.titulo}</h2>
      <p className="nota">{modulo.descripcion}</p>

      <div className="barra">
        <div className="pestanas" role="tablist">
          {modulo.tablas.map((t) => (
            <button key={t} role="tab" aria-selected={t === tabla}
              className={t === tabla ? 'activa' : ''} onClick={() => setTabla(t)}>
              {t}
            </button>
          ))}
        </div>
        {conModal && (
          <div className="acciones">
            {rutinas.map((r) => (
              <button key={r.key} type="button" className={boton(r).clase} onClick={() => setAbierta(r.key)}>
                {boton(r).prefijo}{r.titulo}
              </button>
            ))}
          </div>
        )}
      </div>

      {faltantes.length > 0 && (
        <p className="error">Falta en backend/app/catalogo.py: {faltantes.join(', ')}</p>
      )}
      {aviso && <p className="aviso" role="status">✓ {aviso}</p>}

      <DataTable tabla={tabla} refrescar={version} />

      {conModal && rutinaAbierta && (
        <Modal titulo={rutinaAbierta.titulo} onClose={() => setAbierta(null)}>
          <RoutineForm key={rutinaAbierta.key} item={rutinaAbierta} onDone={alGuardar} />
        </Modal>
      )}

      {!conModal && rutinas.length > 0 && <h3 className="separador">Operaciones</h3>}
      {!conModal && (
        <div className="rejilla">
          {rutinas.map((r) => (
            <RoutineForm key={r.key} item={r} onDone={() => setVersion((v) => v + 1)} />
          ))}
        </div>
      )}
    </section>
  )
}
