import { useEffect, useMemo, useState } from 'react'
import { api } from '../api.js'

const fmt = (v, digits=0) => new Intl.NumberFormat('es-BO',{maximumFractionDigits:digits}).format(Number(v || 0))
const corto = (s) => { if(!s) return ''; const [y,m,d]=String(s).slice(0,10).split('-');return `${d}/${m}` }
function Fecha({label,value,onChange}){return <label className="period-field"><span>{label}</span><input type="date" value={value} onChange={e=>onChange(e.target.value)} /></label>}
function Serie({filas}){
 const width=760,height=220,left=40,top=15,bottom=33
 const max=Math.max(1,...filas.map(x=>Number(x.kilos||0)))
 const pts=filas.map((d,i)=>({x:left+i*(width-left-12)/Math.max(1,filas.length-1),y:height-bottom-Number(d.kilos||0)/max*(height-bottom-top),d}))
 const path=pts.map((p,i)=>`${i?'L':'M'} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join(' ')
 const area=pts.length?`${path} L ${pts.at(-1).x} ${height-bottom} L ${pts[0].x} ${height-bottom} Z`:''
 const ticks=[0,.25,.5,.75,1]
 if(!filas.length)return <div className="chart-empty">Sin recolecciones en este rango de fechas. Prueba otro período.</div>
 return <svg className="line-graph" viewBox={`0 0 ${width} ${height}`} role="img" aria-label="Kilogramos recolectados por fecha">
  <defs><linearGradient id="graphFill" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stopColor="#42b4f2" stopOpacity=".28"/><stop offset="1" stopColor="#42b4f2" stopOpacity=".02"/></linearGradient></defs>
  {ticks.map(t=><g key={t}><line x1={left} x2={width-9} y1={height-bottom-t*(height-bottom-top)} y2={height-bottom-t*(height-bottom-top)} stroke="#e8edf5" strokeDasharray="4 5"/><text x="34" y={height-bottom-t*(height-bottom-top)+4} textAnchor="end" fontSize="11" fill="#9ba9bd">{fmt(max*t)}</text></g>)}
  {pts.length>1&&<path d={area} fill="url(#graphFill)"/>}{pts.length>1&&<path d={path} stroke="#3097dd" strokeWidth="3.2" fill="none" strokeLinejoin="round" strokeLinecap="round"/>}
  {pts.map((p,i)=><g key={i}><circle cx={p.x} cy={p.y} r="3.7" fill="#fff" stroke="#2f9add" strokeWidth="2.4"><title>{`${String(p.d.fecha).slice(0,10)}: ${fmt(p.d.kilos,2)} kg`}</title></circle></g>)}
  {pts.filter((_,i)=>i===0||i===pts.length-1||i%Math.max(1,Math.ceil(pts.length/7))===0).map((p,i)=><text key={i} x={p.x} y={height-9} textAnchor="middle" fontSize="11" fill="#9ba9bd">{corto(p.d.fecha)}</text>)}
 </svg>
}
function HorizontalBars({filas,color='#32bfb0',suffix='kg'}){
 if(!filas.length)return <div className="chart-empty small">No hay registros para este período.</div>
 const max=Math.max(1,...filas.map(r=>Number(r.kilos||0)))
 return <div className="horizontal-bars">{filas.map((r,i)=><div className="bar-row" key={i}><div className="bar-meta"><span title={r.nombre}>{r.nombre}</span><strong>{fmt(r.kilos,1)} {suffix}</strong></div><div className="bar-track"><div style={{width:`${Math.max(2,Number(r.kilos||0)/max*100)}%`,background:color}}/></div></div>)}</div>
}
function ChartCard({title,subtitle,children,detail}){return <section className="analytic-card"><div className="analytic-head"><div><h3>{title}</h3><p>{subtitle}</p></div>{detail&&<span className="analytic-chip">{detail}</span>}</div>{children}</section>}

export default function Dashboard({onNavigate}){
 const [limites,setLimites]=useState(null)
 const [desde,setDesde]=useState('');const [hasta,setHasta]=useState('')
 const [aplicado,setAplicado]=useState(null)
 const [datos,setDatos]=useState(null)
 const [error,setError]=useState('');const [cargando,setCargando]=useState(false)
 const [version,setVersion]=useState(0)
 useEffect(()=>{api.get('/dashboard/fechas').then(d=>{setLimites(d);if(d.primera&&d.ultima){setDesde(d.primera.slice(0,10));setHasta(d.ultima.slice(0,10));setAplicado({desde:d.primera.slice(0,10),hasta:d.ultima.slice(0,10)})}}).catch(e=>setError(`No se pudo consultar el período: ${e.message}`))},[])
 useEffect(()=>{if(!aplicado)return;let vivo=true;setCargando(true);setError('');api.get(`/dashboard/resumen?desde=${aplicado.desde}&hasta=${aplicado.hasta}`).then(r=>{if(vivo)setDatos(r)}).catch(e=>{if(vivo){setError(e.message);setDatos(null)}}).finally(()=>{if(vivo)setCargando(false)});return()=>{vivo=false}},[aplicado,version])
 const o=datos?.operacion||{},b=datos?.base||{},inv=datos?.inventario||{}
 const ocupacion=useMemo(()=>b.contenedores?Math.round(100*Number(o.contenedores_atendidos||0)/b.contenedores):0,[o,b])
 function filtrar(e){e.preventDefault();if(!desde||!hasta||desde>hasta){setError('Selecciona fechas válidas. La fecha inicial no puede superar a la final.');return}setAplicado({desde,hasta})}
 const metrics=[{icon:'♻',tone:'cyan',name:'Residuos recolectados',value:`${fmt(o.kilos,1)} kg`,note:`${fmt(o.recolecciones)} operaciones en el período`},{icon:'▤',tone:'violet',name:'Descargas en botaderos',value:fmt(o.descargas),note:`${fmt(o.kilos_descargados,1)} kg descargados`},{icon:'⌁',tone:'orange',name:'Rutas atendidas',value:fmt(o.rutas_atendidas),note:`De ${fmt(b.rutas)} rutas registradas`},{icon:'▣',tone:'mint',name:'Contenedores atendidos',value:fmt(o.contenedores_atendidos),note:`De ${fmt(b.contenedores)} disponibles` }]
 return <div className="dash-modern">
  <div className="dash-intro"><div><div className="mini-label">CENTRO DE MONITOREO <span className="label-dot"/></div><h1>Panel de control</h1><p>Indicadores operativos y seguimiento de la recolección urbana, calculados desde MySQL.</p></div><button className="refresh-button" onClick={()=>setVersion(v=>v+1)} disabled={cargando}>↻ Actualizar datos</button></div>
  <form className="filters-panel" onSubmit={filtrar}><div className="filters-label"><span>◷</span><div><strong>Período de análisis</strong><small>{limites?.primera?`Hay datos desde ${limites.primera.slice(0,10)} hasta ${limites.ultima.slice(0,10)}`:'Selecciona un rango con información disponible'}</small></div></div><div className="filter-controls"><Fecha label="Desde" value={desde} onChange={setDesde}/><Fecha label="Hasta" value={hasta} onChange={setHasta}/><button type="submit" disabled={cargando||!desde||!hasta}>Aplicar filtros <span>→</span></button></div></form>
  {error&&<div className="message error"><strong>Problema al cargar información:</strong> {error} <button className="inline-link" onClick={()=>onNavigate('estado')}>Revisar estado de MySQL</button></div>}
  {!limites?.primera&&!error&&<div className="notice-empty">No se encontraron fechas en RECOLECTA ni DESCARGA_BOTADERO. Revisa la carga de registros en Estado de MySQL.</div>}
  <div className="dash-section-label"><span>RESUMEN DEL PERÍODO</span><small>{cargando?'Consultando…':aplicado?`${aplicado.desde} — ${aplicado.hasta}`:'Sin período'}</small></div>
  <div className="metric-grid">{metrics.map(m=><div className="metric-tile" key={m.name}><div className="metric-head"><span className={'metric-picto '+m.tone}>{m.icon}</span><span className="metric-tag">Datos reales</span></div><div className="metric-value">{datos?m.value:'—'}</div><div className="metric-name">{m.name}</div><div className="metric-note">{datos?m.note:'Pendiente de cargar'}</div></div>)}</div>
  <div className="analytics-grid"><ChartCard title="Evolución de la recolección" subtitle="Peso total recogido por día" detail="Kilogramos"><Serie filas={datos?.serie_diaria||[]}/><div className="chart-foot">{fmt(o.recolectores_activos)} recolectores participaron durante el período</div></ChartCard><ChartCard title="Cobertura operativa" subtitle="Contenedores con recolecciones en el período"><div className="donut-wrap"><div className="donut-ring" style={{'--progress':Math.min(100,ocupacion)}}><div><strong>{datos?`${ocupacion}%`:'—'}</strong><span>Atendidos</span></div></div><div className="donut-summary"><div><i className="legend-dot done"/> Atendidos <strong>{fmt(o.contenedores_atendidos)}</strong></div><div><i className="legend-dot pending"/> Sin registro <strong>{fmt(Math.max(0,(b.contenedores||0)-(o.contenedores_atendidos||0)))}</strong></div><button onClick={()=>onNavigate('territorio')}>Explorar zonas →</button></div></div></ChartCard></div>
  <div className="analytics-grid lower"><ChartCard title="Zonas con mayor recolección" subtitle="Clasificación por kg recolectados"><HorizontalBars filas={datos?.zonas||[]} color="#3b9dd9"/></ChartCard><ChartCard title="Botaderos con más descargas" subtitle="Peso confirmado durante el período"><HorizontalBars filas={datos?.botaderos||[]} color="#2cc5b7"/></ChartCard></div>
  <div className="bottom-grid"><section className="analytic-card recent-card"><div className="analytic-head"><div><h3>Actividad reciente</h3><p>Últimas recolecciones dentro del período seleccionado</p></div><button className="text-action" onClick={()=>onNavigate('operaciones')}>Ver todas →</button></div>{datos?.recientes?.length?<div className="dash-table-wrap"><table className="dash-table"><thead><tr><th>Fecha</th><th>Zona</th><th>Recolector</th><th>Peso</th></tr></thead><tbody>{datos.recientes.map(r=><tr key={r.id}><td>{String(r.fecha).slice(0,10)}</td><td>{r.zona||'Sin zona'}</td><td>{r.recolector}</td><td><strong>{fmt(r.kilos,2)} kg</strong></td></tr>)}</tbody></table></div>:<div className="chart-empty small">Sin actividad durante este período.</div>}</section><section className="analytic-card shortcuts-card"><div className="analytic-head"><div><h3>Acciones rápidas</h3><p>Operaciones y consultas del sistema</p></div></div><div className="shortcut-list"><button onClick={()=>onNavigate('operaciones')}><span className="shortcut-icon cyan">♻</span><span><strong>Registrar recolección</strong><small>Programación y pesaje</small></span><b>→</b></button><button onClick={()=>onNavigate('flota')}><span className="shortcut-icon orange">▣</span><span><strong>Registrar descarga</strong><small>Transporte y botadero</small></span><b>→</b></button><button onClick={()=>onNavigate('materiales')}><span className="shortcut-icon violet">▤</span><span><strong>Gestionar materiales</strong><small>Asignaciones y devoluciones</small></span><b>→</b></button><button onClick={()=>onNavigate('reportes')}><span className="shortcut-icon mint">▥</span><span><strong>Generar reportes</strong><small>5 informes con cursores</small></span><b>→</b></button></div></section></div>
  <div className="dash-footnote"><span>◉</span> {datos?`${fmt(b.zonas)} zonas · ${fmt(b.transportes)} vehículos · ${fmt(b.recolectores)} recolectores · ${fmt(inv.unidades)} unidades de material en inventario`:'Los datos se obtienen directamente de la base de datos.'}<button onClick={()=>onNavigate('estado')}>Diagnóstico del sistema →</button></div>
 </div>
}
