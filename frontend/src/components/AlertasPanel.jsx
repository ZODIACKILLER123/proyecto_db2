import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'

const ICONO = { CRITICO: '⛔', ADVERTENCIA: '⚠', INFO: 'ℹ' }

// Alertas que dejan los triggers en ALERTA_SISTEMA (un trigger no puede abrir ventanas).
// Se consulta cada 10 s y justo despues de cualquier operacion que escriba ("alertas:refrescar").
export default function AlertasPanel() {
  const [datos, setDatos] = useState({ pendientes: 0, alertas: [] })
  const [abierto, setAbierto] = useState(true)

  const cargar = useCallback(() => {
    api.get('/alertas?pendientes=true&limit=20').then(setDatos).catch(() => { })
  }, [])

  useEffect(() => {
    cargar()
    const t = setInterval(cargar, 10000)
    window.addEventListener('alertas:refrescar', cargar)
    return () => { clearInterval(t); window.removeEventListener('alertas:refrescar', cargar) }
  }, [cargar])

  async function leer(id) { await api.post(`/alertas/${id}/leer`, {}).catch(() => { }); cargar() }
  async function leerTodas() { await api.post('/alertas/leer_todas', {}).catch(() => { }); cargar() }

  if (datos.pendientes === 0) return null
  return (
    <section className="alertas-card" aria-live="polite">
      <header>
        <button type="button" className="alertas-titulo" onClick={() => setAbierto(!abierto)}>
          🔔 Alertas del sistema <span className="alertas-n">{datos.pendientes}</span>
        </button>
        {abierto && <button type="button" className="alertas-todas" onClick={leerTodas}>Marcar todas como leídas</button>}
      </header>
      {abierto && (
        <ul>
          {datos.alertas.map((a) => (
            <li key={a.idAlerta} className={`alerta alerta-${a.nivel.toLowerCase()}`}>
              <span className="alerta-icono">{ICONO[a.nivel] ?? 'ℹ'}</span>
              <div><strong>{a.tipo}</strong><p>{a.mensaje}</p></div>
              <button type="button" onClick={() => leer(a.idAlerta)} aria-label="Marcar como leída">✓</button>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
