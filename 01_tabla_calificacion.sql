USE universidad;

-- ============================================================
-- TABLA DE CALIFICACIONES
-- Compatible con el modelo de universidad.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS calificacion (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_alumno INT UNSIGNED NOT NULL,
    id_asignatura INT UNSIGNED NOT NULL,
    id_curso_escolar INT UNSIGNED NOT NULL,
    parcial_1 DECIMAL(5,2) NOT NULL,
    parcial_2 DECIMAL(5,2) NOT NULL,
    parcial_final DECIMAL(5,2) NOT NULL,
    trabajo_practico DECIMAL(5,2) NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_calificacion_matricula
        FOREIGN KEY (id_alumno, id_asignatura, id_curso_escolar)
        REFERENCES alumno_se_matricula_asignatura
        (id_alumno, id_asignatura, id_curso_escolar),

    CONSTRAINT chk_parcial_1 CHECK (parcial_1 BETWEEN 0 AND 5),
    CONSTRAINT chk_parcial_2 CHECK (parcial_2 BETWEEN 0 AND 5),
    CONSTRAINT chk_parcial_final CHECK (parcial_final BETWEEN 0 AND 5),
    CONSTRAINT chk_trabajo_practico CHECK (
        trabajo_practico IS NULL OR trabajo_practico BETWEEN 0 AND 5
    ),

    UNIQUE KEY uk_calificacion_matricula
        (id_alumno, id_asignatura, id_curso_escolar)
);

-- Datos de ejemplo usando matrículas que existen en universidad.sql.
INSERT INTO calificacion
(id_alumno,id_asignatura,id_curso_escolar,parcial_1,parcial_2,parcial_final,trabajo_practico)
VALUES
(1,1,1,4.00,3.50,4.20,NULL),
(1,2,1,3.80,4.00,3.50,NULL),
(1,3,1,2.50,3.00,2.80,NULL),
(2,1,1,4.50,4.20,4.70,4.50),
(2,2,1,3.20,3.80,4.00,4.10),
(2,3,1,2.80,3.00,3.20,3.50),
(4,1,1,3.50,3.60,3.80,NULL),
(4,2,1,2.00,2.50,2.80,NULL),
(4,3,1,4.00,4.10,4.20,NULL);

SELECT 'Tabla calificacion creada y datos de prueba cargados.' AS resultado;