# Base de datos MySQL - Universidad

Repositorio de la actividad de base de datos trabajada sobre el modelo **universidad**.

## Archivos

### 1. `01_tabla_calificacion.sql`
Agrega la tabla `calificacion` que no aparece en el `universidad.sql` original. La tabla queda relacionada directamente con:

- `persona`
- `asignatura`
- `curso_escolar`
- `alumno_se_matricula_asignatura`

El modelo original define las tablas de personas, profesores, asignaturas, cursos y matrículas con sus llaves primarias y foráneas. 

### 2. `Funciones_Procedimientos_Triggers.sql`
Contiene la actividad completa:

**5 funciones**
1. Calcular nota final.
2. Obtener estado académico.
3. Calcular créditos matriculados.
4. Calcular promedio de una asignatura.
5. Contar asignaturas aprobadas.

**5 procedimientos**
1. Guardar o actualizar calificación.
2. Generar acta de un curso.
3. Matricular alumno.
4. Reasignar docente.
5. Generar reporte histórico del estudiante.

**5 triggers**
1. Normalizar trabajo práctico.
2. Validar notas.
3. Registrar cambios en historial.
4. Evitar matrículas duplicadas.
5. Colocar fecha automática.

## Orden para ejecutar en MySQL Workbench

1. Ejecuta primero tu archivo original `universidad.sql`.
2. Ejecuta `01_tabla_calificacion.sql`.
3. Ejecuta `Funciones_Procedimientos_Triggers.sql`.
4. Revisa los SELECT y CALL de prueba al final del archivo.

## Nota final

La función de nota usa la ponderación indicada para la actividad:

- Sin trabajo práctico: 20% + 35% + 45%.
- Con trabajo práctico: 20% + 35% + 35% + 10%.

El script fue adaptado a los nombres de tablas y columnas del archivo `universidad.sql` proporcionado.
