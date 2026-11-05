import { useEffect, useState } from 'react'
import { api } from '../api.js'

export default function EstadoBD(){
 const [pruebas,setPruebas]=useState(null)
 const [rutinas,setRutinas]=useState([])
 const [instalacion,setInstalacion]=useState(null)
 const [datos,setDatos]=useState(null)
 const [error,setError]=useState('')
 const [cargando,setCargando]=useState(false)
 function correr(){setError('');setCargando(true);Promise.all([api.get('/db/test'),api.get('/db/routines'),api.get('/db/instalacion'),api.get('/db/datos')]).then(([p,r,i,d])=>{setPruebas(p);setRutinas(r);setInstalacion(i);setDatos(d)}).catch(e=>setError(e.message)).finally(()=>setCargando(false))}
 useEffect(correr,[])
 const faltantes=rutinas.filter(r=>!r.existe)
 return <section className="db-status-page">
  <div className="page-heading"><div><span className="eyebrow">HERRAMIENTAS DEL SISTEMA</span><h1>Estado de MySQL</h1><p>Verifica tanto los registros cargados como los procedimientos, funciones, triggers y reportes.</p></div><button className="refresh-button" onClick={correr} disabled={cargando}>↻ {cargando?'Comprobando…':'Comprobar de nuevo'}</button></div>
  {error&&<div className="message error">{error}</div>}
  <div className="status-cards">{pruebas?.map(p=><div className={'status-card '+(p.ok?'okay':'warning')} key={p.prueba}><div><span className="status-symbol">{p.ok?'✓':'!'}</span><strong>{p.prueba}</strong></div><p>{p.detalle}</p></div>)}</div>
  {datos&&<div className="analytic-card"><div className="analytic-head"><div><h3>Datos cargados</h3><p>Si existen tablas pero no registros, la carga inicial no se completó o se creó un volumen anteriormente.</p></div></div><div className="dataset-grid">{Object.entries(datos.tablas_base).map(([k,v])=><div key={k}><small>{k}</small><strong>{v??'No existe'}</strong></div>)}</div>{datos.fechas_recoleccion?.desde&&<p className="nota">Recolecciones desde {datos.fechas_recoleccion.desde} hasta {datos.fechas_recoleccion.hasta}.</p>}{datos.vacias.length>0&&<p className="message error">Sin registros: {datos.vacias.join(', ')}.</p>}</div>}
  <div className="analytic-card"><div className="analytic-head"><div><h3>Instalación de rutinas SQL</h3><p>El backend comprueba e instala las rutinas originales al arrancar, sin recrear las tablas.</p></div><span className={'install-chip '+(faltantes.length?'bad':'good')}>{faltantes.length?`${faltantes.length} pendientes`:'Rutinas verificadas'}</span></div>{instalacion?.errores?.length>0&&<div className="message error"><strong>Errores encontrados:</strong>{instalacion.errores.map((e,i)=><p key={i}>{e}</p>)}</div>}{faltantes.length>0&&<div className="fix-instructions"><strong>Para reinstalar las rutinas sin borrar tus datos:</strong><code>docker compose exec backend python -m app.instalacion</code><p>Después pulsa «Comprobar de nuevo». Revisa los mensajes concretos en la sección superior si aparece un error SQL.</p></div>}
   <div className="routine-status-table"><table><thead><tr><th>Objeto SQL</th><th>Tipo</th><th>Estado</th></tr></thead><tbody>{rutinas.map(r=><tr key={r.nombre}><td><code>{r.nombre}</code></td><td>{r.tipo==='cursor'?'Reporte con cursor':r.tipo}</td><td><span className={r.existe?'status-green':'status-red'}>{r.existe?'✓ Creado':'✕ No encontrado'}</span></td></tr>)}</tbody></table></div>
  </div>
  <div className="recovery-help"><h3>¿Ves las tablas, pero no sus registros?</h3><p>El archivo <code>01_schema_y_datos.sql</code> contiene los datos iniciales. Docker lo ejecuta únicamente cuando crea un volumen MySQL nuevo. Antes de restaurarlo, respalda cualquier información que hayas añadido.</p><strong>Solo para una instalación nueva de demostración, que puede perder todos los registros actuales:</strong><code>docker compose down -v</code><code>docker compose up --build</code><p>Para conservar registros existentes, no uses <code>down -v</code>; diagnostica primero los errores de carga desde <code>docker compose logs db</code>.</p></div>
 </section>
}
