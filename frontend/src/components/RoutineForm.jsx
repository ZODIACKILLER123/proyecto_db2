import {useEffect,useState} from 'react'
import {api} from '../api.js'
import {Filas} from './DataTable.jsx'

function Campo({p,valor,onChange}){
 const [opciones,setOpciones]=useState([])
 useEffect(()=>{if(p.tabla)api.get(`/opciones/${p.tabla}`).then(setOpciones).catch(()=>setOpciones([]))},[p.tabla])
 return <label className="field"><span>{p.label} {p.requerido&&<em>*</em>}</span>
 {p.tabla&&opciones.length>0?<select required={p.requerido} value={valor} onChange={e=>onChange(e.target.value)}><option value="">Selecciona una opción...</option>{opciones.map(o=><option key={o.id} value={o.id}>{o.id} · {o.nombre}</option>)}</select>:
 <input type={p.tipo==='number'?'number':p.tipo==='date'?'date':p.tipo==='time'?'time':p.tipo==='datetime-local'?'datetime-local':'text'} step={p.tipo==='number'?'any':undefined} required={p.requerido} placeholder={p.tipo==='number'?'Introduce una cantidad':p.tabla?'Introduce el ID':'Escribe aquí'} value={valor} onChange={e=>onChange(e.target.value)}/>}
 </label>
}
function Resultado({datos}){
 if(!datos)return null
 let result=datos.resultado
 if(typeof result==='string'&&(result.startsWith('{')||result.startsWith('['))){try{result=JSON.parse(result)}catch{}}
 if(typeof result==='object'&&result!==null){return <div className="result-panel"><div className="result-heading">✓ Análisis realizado</div><div className="result-grid">{Object.entries(result).map(([k,v])=><div className="result-metric" key={k}><span>{k.replaceAll('_',' ')}</span><strong>{v===null?'Sin datos':typeof v==='object'?JSON.stringify(v):String(v)}</strong></div>)}</div></div>}
 if('resultado' in datos)return <div className="result-panel"><div className="result-heading">✓ Resultado</div><strong>{String(result??'Sin información')}</strong></div>
 if(datos.resultados)return <div className="result-panel"><div className="result-heading">✓ Consulta finalizada</div>{datos.resultados.length?datos.resultados.map((filas,i)=><div key={i}>{datos.resultados.length>1&&<p>Conjunto {i+1}</p>}<Filas filas={filas}/></div>):<p>Operación realizada sin filas de retorno.</p>}</div>
 return null
}
export default function RoutineForm({item,onDone}){
 const [valores,setValores]=useState(()=>Object.fromEntries(item.params.map(p=>[p.name,p.tipo==='date'?p.name.includes('desde')?'2026-09-01':p.name.includes('hasta')?'2026-09-30':'':p.tipo==='number'?'':''])))
 const [estado,setEstado]=useState({cargando:false,error:'',resultado:null})
 async function enviar(e){e.preventDefault();setEstado({cargando:true,error:'',resultado:null});try{const r=await api.ejecutar(item,valores);setEstado({cargando:false,error:'',resultado:r});onDone?.(r)}catch(err){setEstado({cargando:false,error:err.message,resultado:null})}}
 return <div className="routine-wrap"><div className="modal-title-area"><span className="eyebrow">{item.kind==='funcion'?'ANÁLISIS':item.kind==='cursor'?'REPORTE':'NUEVA OPERACIÓN'}</span><h2>{item.titulo}</h2><p>{item.descripcion}</p></div><form className="routine-form" onSubmit={enviar}><div className="field-grid">{item.params.map(p=><Campo key={p.name} p={p} valor={valores[p.name]??''} onChange={v=>setValores(old=>({...old,[p.name]:v}))}/>)}</div><div className="form-foot"><span><span className="required-mark">*</span> Campos obligatorios</span><button type="submit" disabled={estado.cargando}>{estado.cargando?'Procesando…':item.kind==='cursor'?'Generar reporte':item.kind==='funcion'?'Consultar análisis':'Guardar operación'} <span>↗</span></button></div></form>{estado.error&&<div className="message error">⚠ {estado.error}</div>}<Resultado datos={estado.resultado}/></div>
}
