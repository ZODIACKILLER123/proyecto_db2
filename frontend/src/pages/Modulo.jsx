import { useState } from 'react'
import DataTable from '../components/DataTable.jsx'
import RoutineForm from '../components/RoutineForm.jsx'
import Modal from '../components/Modal.jsx'

export default function Modulo({modulo,catalogo}){
 const [tabla,setTabla]=useState(modulo.tablas[0]);const [abierta,setAbierta]=useState(null);const [version,setVersion]=useState(0);const [mensaje,setMensaje]=useState('')
 const acciones=catalogo.filter(x=>x.kind==='procedimiento'&&modulo.acciones.includes(x.key))
 const funciones=catalogo.filter(x=>x.kind==='funcion'&&modulo.funciones.includes(x.key))
 const operacion=[...acciones,...funciones].find(x=>x.kind+':'+x.key===abierta)
 function completado(resultado){setVersion(n=>n+1); if(operacion?.kind==='procedimiento'){setMensaje(resultado?.resultados?.[0]?.[0]?.mensaje||'La operación se realizó correctamente.');setAbierta(null)} }
 return <>
  <div className="page-heading"><div><span className="eyebrow">GESTIÓN OPERATIVA</span><h1>{modulo.titulo}</h1><p>{modulo.descripcion}</p></div><span className="page-heading-symbol">{modulo.icono}</span></div>
  <div className="section-row"><div><h2>Acciones disponibles</h2><p className="section-subtitle">Selecciona una operación para abrir su formulario.</p></div></div>
  <div className="action-grid">{[...acciones,...funciones].map((r)=><button key={r.kind+r.key} className="action-card" onClick={()=>setAbierta(r.kind+':'+r.key)}><span className={'action-icon '+(r.kind==='funcion'?'blue':'green')}>{r.kind==='funcion'?'▥':'✳'}</span><span className="action-content"><strong>{r.titulo}</strong><small>{r.descripcion}</small><em>{r.kind==='funcion'?'Consultar análisis':'Abrir formulario'} ↗</em></span></button>)}{!acciones.length&&!funciones.length&&<div className="empty-actions">Este módulo es de consulta. Explora los registros debajo.</div>}</div>
  <div className="records-card"><div className="records-header"><div><span className="eyebrow">BASE DE DATOS</span><h2>Registros y tablas</h2><p>Selecciona una tabla para consultar sus datos actualizados.</p></div><span className="records-badge">{modulo.tablas.length} tablas</span></div>
   <div className="table-tabs" role="tablist">{modulo.tablas.map(t=><button role="tab" aria-selected={tabla===t} className={tabla===t?'active':''} key={t} onClick={()=>setTabla(t)}>{t.replaceAll('_',' ')}</button>)}</div>
   <DataTable tabla={tabla} refrescar={version}/>
  </div>
  {mensaje&&<div className="toast" role="status"><span>✓</span>{mensaje}<button onClick={()=>setMensaje('')}>×</button></div>}
  {operacion&&<Modal titulo={operacion.titulo} onClose={()=>setAbierta(null)}><RoutineForm key={operacion.kind+operacion.key} item={operacion} onDone={completado}/></Modal>}
 </>
}
