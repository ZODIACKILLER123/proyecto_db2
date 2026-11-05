import { useEffect, useState } from 'react'
import { api } from './api.js'
import Modulo from './pages/Modulo.jsx'
import Reportes from './pages/Reportes.jsx'
import EstadoBD from './pages/EstadoBD.jsx'
import Dashboard from './pages/Dashboard.jsx'

const MODULOS = [
  { id:'inicio', titulo:'Panel general', icono:'▦', descripcion:'Visión general de la empresa', especial:'inicio' },
  { id:'operaciones', titulo:'Recolección', icono:'♻', descripcion:'Programa recorridos y registra las recolecciones realizadas.', tablas:['RECOLECTA','PASA_POR','TRABAJA','INTEGRA'], acciones:['programar_ruta','registrar_recoleccion'], funciones:['zona','rutas'] },
  { id:'flota', titulo:'Flota y botaderos', icono:'▣', descripcion:'Consulta camiones, destinos y registra las descargas.', tablas:['TRANSPORTE','BOTADERO','DESCARGA_BOTADERO','CONDUCTOR'], acciones:['registrar_descarga'], funciones:['botadero'] },
  { id:'personal', titulo:'Personal', icono:'♟', descripcion:'Conductores, recolectores, asignaciones y desempeño.', tablas:['PERSONA','RECOLECTOR','CONDUCTOR','HISTORIAL_ASIGNACION'], acciones:[], funciones:['personal'] },
  { id:'territorio', titulo:'Zonas y rutas', icono:'⌁', descripcion:'Zonas, vías, rutas y ubicación de los contenedores.', tablas:['ZONA','VIA','RUTA','CONTENEDOR','INTEGRA'], acciones:[], funciones:['zona','rutas'] },
  { id:'materiales', titulo:'Materiales', icono:'▤', descripcion:'Gestiona las entregas, devoluciones y existencias de material.', tablas:['MATERIAL_TRABAJO','DISPONE','COMPRA_MATERIAL','DEVOLUCION_MATERIAL'], acciones:['asignar_material','registrar_devolucion'], funciones:['materiales'] },
  { id:'reportes', titulo:'Reportes con cursores', icono:'▥', descripcion:'Cinco reportes analíticos', especial:'reportes' },
  { id:'estado', titulo:'Estado de MySQL', icono:'◉', descripcion:'Diagnóstico de tablas y rutinas', especial:'estado' },
]

export default function App(){
  const [actual,setActual]=useState('inicio')
  const [catalogo,setCatalogo]=useState([])
  const [error,setError]=useState('')
  const [menu,setMenu]=useState(false)
  useEffect(()=>{ api.get('/logica/catalogo').then(setCatalogo).catch(e=>setError(e.message)) },[])
  const modulo=MODULOS.find(x=>x.id===actual)
  const navegar=id=>{setActual(id);setMenu(false)}
  return <div className="app-shell">
    <aside className={'sidebar '+(menu?'sidebar-open':'')}>
      <div className="brand"><div className="brand-mark">♻</div><div><strong>ECOGESTIÓN</strong><small>Sistema de recolección</small></div></div>
      <div className="nav-caption">PLATAFORMA</div>
      <nav className="nav-links">{MODULOS.map(m=><button key={m.id} className={'nav-link '+(actual===m.id?'selected':'')} onClick={()=>navegar(m.id)}><span className="nav-icon">{m.icono}</span><span>{m.titulo}</span>{actual===m.id&&<span className="nav-active-dot"/>}</button>)}</nav>
      <div className="side-bottom"><div className="side-avatar">DB</div><div><strong>Base de Datos II</strong><span>MySQL 8.0 · FastAPI</span></div></div>
    </aside>
    <div className="workspace">
      <header className="topbar"><div className="top-left"><button className="mobile-toggle" onClick={()=>setMenu(!menu)}>☰</button><span className="crumb">Sistema de gestión</span><span className="crumb-sep">/</span><strong>{modulo.titulo}</strong></div><div className="top-right"><span className="header-tag"><span className="live-dot"/> Sistema de recolección</span></div></header>
      <main className="content">
        {error&&<div className="message error">No se pudo conectar al backend: {error}. Verifica los contenedores Docker.</div>}
        {modulo.especial==='inicio' ? <Dashboard catalogo={catalogo} onNavigate={navegar}/>:modulo.especial==='reportes'?<Reportes catalogo={catalogo}/>:modulo.especial==='estado'?<EstadoBD/>:<Modulo key={modulo.id} modulo={modulo} catalogo={catalogo}/>}
      </main>
      <footer className="app-footer">Ecogestión · Sistema de gestión de residuos sólidos <span>Proyecto académico · Base de Datos II</span></footer>
    </div>
    {menu&&<div className="sidebar-backdrop" onClick={()=>setMenu(false)}/>}
  </div>
}
