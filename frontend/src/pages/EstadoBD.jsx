import { useEffect, useState } from 'react'
import { api } from '../api.js'

export default function EstadoBD() {
  const [pruebas, setPruebas] = useState(null)
  const [rutinas, setRutinas] = useState([])
  const [error, setError] = useState('')

  function correr() {
    setError(''); setPruebas(null)
    api.get('/db/test').then(setPruebas).catch((e) => setError(e.message))
    api.get('/db/routines').then(setRutinas).catch(() => {})
  }
  useEffect(correr, [])

  return (
    <section>
      <h2>Estado de la base de datos</h2>
      <p className="nota">Comprueba la conexión, las tablas y qué lógica ya existe en MySQL.</p>
      <button onClick={correr}>Volver a probar</button>
      {error && <p className="error">{error}</p>}
      {!pruebas && !error && <p className="vacio">Probando…</p>}
      {pruebas && (
        <ul className="pruebas">
          {pruebas.map((p) => (
            <li key={p.prueba} className={p.ok ? 'bien' : 'mal'}>
              <strong>{p.ok ? 'Correcto' : 'Pendiente'}</strong>
              <span>{p.prueba}</span>
              <span className="nota">{p.detalle}</span>
            </li>
          ))}
        </ul>
      )}
      {rutinas.length > 0 && (
        <>
          <h3 className="separador">Lógica esperada</h3>
          <div className="tabla-scroll">
            <table>
              <thead><tr><th>Nombre</th><th>Tipo</th><th>Estado</th></tr></thead>
              <tbody>
                {rutinas.map((r) => (
                  <tr key={r.nombre}>
                    <td>{r.nombre}</td><td>{r.tipo}</td>
                    <td className={r.existe ? 'bien-txt' : 'mal-txt'}>{r.existe ? 'Creado' : 'Falta crear'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </section>
  )
}
