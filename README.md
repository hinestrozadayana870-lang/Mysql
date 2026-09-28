# Actividad MySQL - Funciones, Procedimientos y Triggers

Actividad realizada a partir del PDF **Funciones, Procedimientos y Triggers**.

## Archivo principal

- `Funciones_Procedimientos_Triggers.sql`

## Contenido

### Funciones
1. `fnc_calcular_nota_final`
2. `fnc_obtener_estado_academico`
3. `fnc_total_creditos_matriculados`
4. `fnc_promedio_general_asignatura`
5. `fnc_contar_asignaturas_aprobadas`

La nota final aplica:
- Sin trabajo práctico: 20% + 35% + 45%.
- Con trabajo práctico: 20% + 35% + 35% + 10%.

### Procedimientos
1. `sp_guardar_calificacion`
2. `sp_generar_acta_curso`
3. `sp_matricular_alumno`
4. `sp_reasignar_docente`
5. `sp_reporte_historico_estudiante`

### Triggers
Se cubren las cinco reglas solicitadas por la actividad:
1. Normalización del trabajo práctico.
2. Auditoría de modificación de notas.
3. Validación de notas entre 0.00 y 5.00.
4. Prevención de matrículas duplicadas.
5. Fecha automática de registro.

Las reglas 1, 3 y 5 se agrupan en el trigger de inserción y la validación también se aplica en actualización para mantener compatibilidad con instalaciones de MySQL donde no conviene crear varios triggers con el mismo evento/tiempo.

## Importante

El script trabaja sobre la base de datos `universidad` y sobre el modelo que utiliza las tablas `calificacion`, `persona`, `profesor`, `asignatura`, `curso_escolar` y `alumno_se_matricula_asignatura`.

Antes de ejecutar el script, verifica que la base de datos y esas tablas ya estén creadas.

El `ALTER TABLE calificacion ADD COLUMN fecha_registro` se ejecuta una sola vez. Si la columna ya existe, omite esa línea.

Las pruebas de cada función y procedimiento están al final del archivo SQL.
