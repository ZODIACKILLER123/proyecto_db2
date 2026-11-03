import { useEffect, useState } from 'react'
import { api } from './api.js'
import Modulo from './pages/Modulo.jsx'
import Reportes from './pages/Reportes.jsx'
import EstadoBD from './pages/EstadoBD.jsx'

// Capa 1 del modelo navegacional: cada modulo apunta a tablas y rutinas de la BD.
const MODULOS = [
  {
    id: 'personal', titulo: 'Registro de personal',
    descripcion: 'Personas, conductores y recolectores.',
    tablas: ['PERSONA', 'CONDUCTOR', 'RECOLECTOR'], rutinasPorTabla: {
      PERSONA: ['registrar_persona'],
      CONDUCTOR: ['registrar_conductor'],
      RECOLECTOR: ['registrar_recolector'],
    },
    rutinas: []
  },
  {
    id: 'rutas', titulo: 'Rutas y vías',
    descripcion: 'Zonas, vías, rutas y contenedores.',
    tablas: ['RUTA', 'VIA', 'ZONA', 'CONTENEDOR', 'INTEGRA'],
    rutinasPorTabla: {
      RUTA: ['asignar_transporte_ruta'],
      VIA: ['registrar_via'],
      ZONA: ['registrar_zona', 'eliminar_zona_segura'],
      CONTENEDOR: ['registrar_contenedor'],
    },
    rutinas: []
  },
  {
    id: 'flota', titulo: 'Flota y botaderos',
    descripcion: 'Transportes, botaderos y las rutas por las que pasan.',
    tablas: ['TRANSPORTE', 'BOTADERO', 'PASA_POR'],
    rutinasPorTabla: {
      TRANSPORTE: ['estado_operativo_transporte', 'reasignar_recolector_transporte'],
      BOTADERO: ['capacidad_total_botadero'],
    },
    rutinas: []
  },
  {
    id: 'recoleccion', titulo: 'Operaciones de recolección',
    descripcion: 'Recolectas realizadas y zonas de trabajo.',
    tablas: ['RECOLECTA', 'TRABAJA'],
    rutinasPorTabla: {
      RECOLECTA: ['registrar_recoleccion', 'recolectas_por_recolector'],
      TRABAJA: ['cobertura_zona'],
    },
    rutinas: []
  },
  {
    id: 'materiales', titulo: 'Materiales y costos',
    descripcion: 'Material entregado al personal y su precio.',
    tablas: ['MATERIAL_TRABAJO', 'DISPONE', 'HISTORIAL_PRECIO_MATERIAL'],
    rutinasPorTabla: {
      MATERIAL_TRABAJO: ['actualizar_precio_material'],
      DISPONE: ['costo_materiales_persona'],
    },
    rutinas: []
  },
  { id: 'reportes', titulo: 'Reportes BI', especial: 'reportes' },
  {
    id: 'auditoria', titulo: 'Auditoría e historiales',
    descripcion: 'Lo que registran los triggers y procedimientos.',
    tablas: ['AUDITORIA_RECOLECCION', 'HISTORIAL_PRECIO_MATERIAL', 'HISTORIAL_ASIGNACION_RECOLECTOR'],
    rutinas: []
  },
  { id: 'estado', titulo: 'Estado de la BD', especial: 'estado' },
]

export default function App() {
  const [actual, setActual] = useState(MODULOS[0].id)
  const [catalogo, setCatalogo] = useState([])
  const [errorApi, setErrorApi] = useState('')

  useEffect(() => {
    api.get('/logica/catalogo').then(setCatalogo).catch((e) => setErrorApi(e.message))
  }, [])

  const modulo = MODULOS.find((m) => m.id === actual)

  return (
    <div className="app">
      <nav>
        <h1>Empresa recolectora</h1>
        {MODULOS.map((m) => (
          <button key={m.id} className={m.id === actual ? 'activa' : ''} onClick={() => setActual(m.id)}>
            {m.titulo}
          </button>
        ))}
      </nav>
      <main>
        {errorApi && <p className="error">No se pudo conectar con el backend: {errorApi}</p>}
        {modulo.especial === 'estado' ? <EstadoBD />
          : modulo.especial === 'reportes' ? <Reportes catalogo={catalogo} />
            : <Modulo key={modulo.id} modulo={modulo} catalogo={catalogo} />}
      </main>
    </div>
  )
}
