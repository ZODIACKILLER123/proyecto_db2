const BASE = '/api'

async function pedir(ruta, opciones = {}) {
  const r = await fetch(BASE + ruta, {
    headers: { 'Content-Type': 'application/json' },
    ...opciones,
  })
  const datos = await r.json().catch(() => null)
  if (!r.ok) {
    const d = datos?.detail
    throw new Error(typeof d === 'string' ? d : JSON.stringify(d) || `Error ${r.status}`)
  }
  return datos
}

export const api = {
  get: (ruta) => pedir(ruta),
  post: (ruta, cuerpo) => pedir(ruta, { method: 'POST', body: JSON.stringify(cuerpo) }),
  // Ejecuta un item del catalogo (procedimiento, funcion, cursor o dml)
  ejecutar: (item, valores) => {
    if (item.metodo === 'GET') {
      const q = new URLSearchParams(
        Object.entries(valores).filter(([, v]) => v !== '' && v != null)
      ).toString()
      return pedir(item.ruta + (q ? `?${q}` : ''))
    }
    return pedir(item.ruta, { method: 'POST', body: JSON.stringify(valores) })
  },
}
