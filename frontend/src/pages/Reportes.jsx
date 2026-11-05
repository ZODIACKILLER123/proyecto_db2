import { useState } from 'react'
import Modal from '../components/Modal.jsx'
import RoutineForm from '../components/RoutineForm.jsx'
const icons=['◈','⌁','▣','♟','▤']
export default function Reportes({catalogo}){
 const [abierto,setAbierto]=useState(null)
 const reportes=catalogo.filter(x=>x.kind==='cursor');const elegido=reportes.find(x=>x.key===abierto)
 return <><div className="page-heading"><div><span className="eyebrow">INTELIGENCIA OPERATIVA</span><h1>Reportes y análisis</h1><p>Explora informes construidos con cursores de MySQL. Selecciona un período para generar cada reporte.</p></div><span className="page-heading-symbol">▥</span></div>
 <div className="report-intro"><div className="report-counter"><strong>05</strong><span>Reportes disponibles</span></div><div><strong>Información basada en tus registros</strong><p>Los resultados se calculan directamente desde tu base de datos, sin datos ficticios.</p></div></div>
 <div className="report-grid">{reportes.map((r,i)=><button className="report-card" key={r.key} onClick={()=>setAbierto(r.key)}><div className="report-card-top"><span className="report-icon">{icons[i]}</span><span className="report-number">REPORTE 0{i+1}</span></div><h3>{r.titulo}</h3><p>{r.descripcion}</p><div className="report-bottom">Generar reporte <span>↗</span></div></button>)}</div>
 {elegido&&<Modal titulo={elegido.titulo} onClose={()=>setAbierto(null)}><RoutineForm item={elegido}/></Modal>}
 </>
}
