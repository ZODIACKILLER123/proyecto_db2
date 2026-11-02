import { useEffect } from 'react'

export default function Modal({ titulo, onClose, children }) {
  useEffect(() => {
    const onKey = (e) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('keydown', onKey)
    const previo = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = previo
    }
  }, [onClose])

  return (
    <div className="modal-fondo" onMouseDown={(e) => { if (e.target === e.currentTarget) onClose() }}>
      <div className="modal" role="dialog" aria-modal="true" aria-label={titulo}>
        <button type="button" className="modal-cerrar" onClick={onClose} aria-label="Cerrar">×</button>
        {children}
      </div>
    </div>
  )
}
