import { useEffect, useState } from 'react'

// Ventana de rechazo: aparece cuando un trigger o procedimiento hace SIGNAL (el backend responde 400).
// Ej.: "Botadero lleno: ...", "Presupuesto excedido: ...", "Jornada cerrada: ...".
export default function RechazoModal() {
  const [mensaje, setMensaje] = useState('')

  useEffect(() => {
    const abrir = (e) => setMensaje(e.detail)
    window.addEventListener('bd:rechazo', abrir)
    return () => window.removeEventListener('bd:rechazo', abrir)
  }, [])

  useEffect(() => {
    if (!mensaje) return
    // Fase de captura: cierra solo esta ventana y no la que esta debajo.
    const onKey = (e) => {
      if (e.key === 'Escape') { e.stopImmediatePropagation(); setMensaje('') }
    }
    window.addEventListener('keydown', onKey, true)
    return () => window.removeEventListener('keydown', onKey, true)
  }, [mensaje])

  if (!mensaje) return null
  return (
    <div className="modal-fondo modal-rechazo" onMouseDown={(e) => { if (e.target === e.currentTarget) setMensaje('') }}>
      <div className="modal" role="alertdialog" aria-modal="true" aria-label="Operación rechazada">
        <div className="modal-title-area">
          <span className="eyebrow">VALIDACIÓN DE LA BASE DE DATOS</span>
          <h2>⛔ Operación rechazada</h2>
        </div>
        <p className="rechazo-texto">{mensaje}</p>
        <div className="form-foot"><span>Lo bloqueó un trigger o procedimiento de MySQL.</span>
          <button type="button" onClick={() => setMensaje('')}>Entendido</button></div>
      </div>
    </div>
  )
}
