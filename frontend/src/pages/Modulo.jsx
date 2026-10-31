import { useState } from 'react'
import DataTable from '../components/DataTable.jsx'
import RoutineForm from '../components/RoutineForm.jsx'

// Un modulo de la capa 1 = tablas para consultar + rutinas de la BD para ejecutar
export default function Modulo({ modulo, catalogo }) {
  const [tabla, setTabla] = useState(modulo.tablas[0])
  const [version, setVersion] = useState(0)
  const rutinas = modulo.rutinas.map((k) => catalogo.find((c) => c.key === k)).filter(Boolean)

  return (
    <section>
      <h2>{modulo.titulo}</h2>
      <p className="nota">{modulo.descripcion}</p>

      <div className="pestanas" role="tablist">
        {modulo.tablas.map((t) => (
          <button key={t} role="tab" aria-selected={t === tabla}
                  className={t === tabla ? 'activa' : ''} onClick={() => setTabla(t)}>
            {t}
          </button>
        ))}
      </div>
      <DataTable tabla={tabla} refrescar={version} />

      {rutinas.length > 0 && <h3 className="separador">Operaciones</h3>}
      <div className="rejilla">
        {rutinas.map((r) => (
          <RoutineForm key={r.key} item={r} onDone={() => setVersion((v) => v + 1)} />
        ))}
      </div>
    </section>
  )
}
