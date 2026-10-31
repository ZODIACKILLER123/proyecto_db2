import RoutineForm from '../components/RoutineForm.jsx'

// Cursores anidados: cada uno es un procedimiento sin parametros
export default function Reportes({ catalogo }) {
  const cursores = catalogo.filter((c) => c.kind === 'cursor')
  return (
    <section>
      <h2>Reportes BI</h2>
      <p className="nota">Cada reporte ejecuta un cursor anidado de la BD y muestra lo que devuelve.</p>
      <div className="rejilla">
        {cursores.map((c) => <RoutineForm key={c.key} item={c} />)}
      </div>
    </section>
  )
}
