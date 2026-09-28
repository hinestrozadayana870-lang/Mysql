-- ============================================================
-- ACTIVIDAD COMPLETA MYSQL - UNIVERSIDAD
-- Funciones, procedimientos almacenados y triggers
-- Basado en el PDF de la actividad y universidad.sql
-- ============================================================

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

USE universidad;

-- ============================================================
-- ACTIVIDAD COMPLETA: FUNCIONES, PROCEDIMIENTOS Y TRIGGERS
-- Base: universidad.sql
-- ============================================================

DROP TABLE IF EXISTS historial_calificaciones;
CREATE TABLE historial_calificaciones (
    id_historial INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT UNSIGNED NOT NULL,
    parcial_1_anterior DECIMAL(5,2),
    parcial_1_nuevo DECIMAL(5,2),
    parcial_2_anterior DECIMAL(5,2),
    parcial_2_nuevo DECIMAL(5,2),
    parcial_final_anterior DECIMAL(5,2),
    parcial_final_nuevo DECIMAL(5,2),
    trabajo_practico_anterior DECIMAL(5,2),
    trabajo_practico_nuevo DECIMAL(5,2),
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 1. FUNCIONES
-- ============================================================

DROP FUNCTION IF EXISTS fnc_calcular_nota_final;
DROP FUNCTION IF EXISTS fnc_obtener_estado_academico;
DROP FUNCTION IF EXISTS fnc_total_creditos_matriculados;
DROP FUNCTION IF EXISTS fnc_promedio_general_asignatura;
DROP FUNCTION IF EXISTS fnc_contar_asignaturas_aprobadas;

DELIMITER $$

CREATE FUNCTION fnc_calcular_nota_final(p_id_calificacion INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_p1 DECIMAL(5,2);
    DECLARE v_p2 DECIMAL(5,2);
    DECLARE v_pf DECIMAL(5,2);
    DECLARE v_tp DECIMAL(5,2);

    SELECT parcial_1, parcial_2, parcial_final, trabajo_practico
    INTO v_p1, v_p2, v_pf, v_tp
    FROM calificacion
    WHERE id = p_id_calificacion;

    IF v_tp IS NULL THEN
        RETURN ROUND((v_p1 * 0.20) + (v_p2 * 0.35) + (v_pf * 0.45), 2);
    END IF;

    RETURN ROUND((v_p1 * 0.20) + (v_p2 * 0.35)
                 + (v_pf * 0.35) + (v_tp * 0.10), 2);
END$$

CREATE FUNCTION fnc_obtener_estado_academico(p_id_calificacion INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    IF fnc_calcular_nota_final(p_id_calificacion) >= 3.00 THEN
        RETURN 'APROBADO';
    END IF;

    RETURN 'REPROBADO';
END$$

CREATE FUNCTION fnc_total_creditos_matriculados(
    p_id_alumno INT,
    p_id_curso_escolar INT
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT COALESCE(SUM(a.creditos), 0)
    INTO v_total
    FROM alumno_se_matricula_asignatura m
    INNER JOIN asignatura a ON a.id = m.id_asignatura
    WHERE m.id_alumno = p_id_alumno
      AND m.id_curso_escolar = p_id_curso_escolar;

    RETURN v_total;
END$$

CREATE FUNCTION fnc_promedio_general_asignatura(p_id_asignatura INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(5,2);

    SELECT ROUND(AVG(fnc_calcular_nota_final(c.id)), 2)
    INTO v_promedio
    FROM calificacion c
    WHERE c.id_asignatura = p_id_asignatura;

    RETURN COALESCE(v_promedio, 0.00);
END$$

CREATE FUNCTION fnc_contar_asignaturas_aprobadas(p_id_alumno INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT;

    SELECT COUNT(*)
    INTO v_total
    FROM calificacion c
    WHERE c.id_alumno = p_id_alumno
      AND fnc_calcular_nota_final(c.id) >= 3.00;

    RETURN v_total;
END$$

DELIMITER ;

-- ============================================================
-- 2. PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DROP PROCEDURE IF EXISTS sp_guardar_calificacion;
DROP PROCEDURE IF EXISTS sp_generar_acta_curso;
DROP PROCEDURE IF EXISTS sp_matricular_alumno;
DROP PROCEDURE IF EXISTS sp_reasignar_docente;
DROP PROCEDURE IF EXISTS sp_reporte_historico_estudiante;

DELIMITER $$

CREATE PROCEDURE sp_guardar_calificacion(
    IN p_id_alumno INT,
    IN p_id_asignatura INT,
    IN p_id_curso_escolar INT,
    IN p_parcial_1 DECIMAL(5,2),
    IN p_parcial_2 DECIMAL(5,2),
    IN p_parcial_final DECIMAL(5,2),
    IN p_trabajo_practico DECIMAL(5,2)
)
BEGIN
    INSERT INTO calificacion (
        id_alumno, id_asignatura, id_curso_escolar,
        parcial_1, parcial_2, parcial_final, trabajo_practico
    )
    VALUES (
        p_id_alumno, p_id_asignatura, p_id_curso_escolar,
        p_parcial_1, p_parcial_2, p_parcial_final, p_trabajo_practico
    )
    ON DUPLICATE KEY UPDATE
        parcial_1 = VALUES(parcial_1),
        parcial_2 = VALUES(parcial_2),
        parcial_final = VALUES(parcial_final),
        trabajo_practico = VALUES(trabajo_practico);
END$$

CREATE PROCEDURE sp_generar_acta_curso(
    IN p_id_asignatura INT,
    IN p_id_curso_escolar INT
)
BEGIN
    SELECT
        p.nif AS documento,
        CONCAT(p.nombre, ' ', p.apellido1, ' ',
               COALESCE(p.apellido2, '')) AS estudiante,
        c.parcial_1,
        c.parcial_2,
        c.parcial_final,
        c.trabajo_practico,
        fnc_calcular_nota_final(c.id) AS nota_final,
        fnc_obtener_estado_academico(c.id) AS estado
    FROM calificacion c
    INNER JOIN persona p ON p.id = c.id_alumno
    WHERE c.id_asignatura = p_id_asignatura
      AND c.id_curso_escolar = p_id_curso_escolar
    ORDER BY p.apellido1, p.apellido2, p.nombre;
END$$

CREATE PROCEDURE sp_matricular_alumno(
    IN p_id_alumno INT,
    IN p_id_asignatura INT,
    IN p_id_curso_escolar INT
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM alumno_se_matricula_asignatura
        WHERE id_alumno = p_id_alumno
          AND id_asignatura = p_id_asignatura
          AND id_curso_escolar = p_id_curso_escolar
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El alumno ya esta matriculado en esta asignatura.';
    ELSE
        INSERT INTO alumno_se_matricula_asignatura
            (id_alumno, id_asignatura, id_curso_escolar)
        VALUES
            (p_id_alumno, p_id_asignatura, p_id_curso_escolar);
    END IF;
END$$

CREATE PROCEDURE sp_reasignar_docente(
    IN p_id_asignatura INT,
    IN p_id_profesor INT,
    IN p_id_departamento INT,
    IN p_id_curso_escolar INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM profesor
        WHERE id_profesor = p_id_profesor
          AND id_departamento = p_id_departamento
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El profesor no pertenece al departamento indicado.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM asignatura WHERE id = p_id_asignatura
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La asignatura no existe.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM curso_escolar WHERE id = p_id_curso_escolar
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El curso escolar no existe.';
    END IF;

    UPDATE asignatura
    SET id_profesor = p_id_profesor
    WHERE id = p_id_asignatura;
END$$

CREATE PROCEDURE sp_reporte_historico_estudiante(IN p_id_alumno INT)
BEGIN
    SELECT
        p.nif AS documento,
        CONCAT(p.nombre, ' ', p.apellido1, ' ',
               COALESCE(p.apellido2, '')) AS estudiante,
        a.nombre AS asignatura,
        ce.anyo_inicio,
        ce.anyo_fin,
        CONCAT(COALESCE(pd.nombre, ''), ' ',
               COALESCE(pd.apellido1, ''), ' ',
               COALESCE(pd.apellido2, '')) AS profesor,
        c.parcial_1,
        c.parcial_2,
        c.parcial_final,
        c.trabajo_practico,
        fnc_calcular_nota_final(c.id) AS nota_final,
        fnc_obtener_estado_academico(c.id) AS estado
    FROM calificacion c
    INNER JOIN persona p ON p.id = c.id_alumno
    INNER JOIN asignatura a ON a.id = c.id_asignatura
    INNER JOIN curso_escolar ce ON ce.id = c.id_curso_escolar
    LEFT JOIN profesor pr ON pr.id_profesor = a.id_profesor
    LEFT JOIN persona pd ON pd.id = pr.id_profesor
    WHERE c.id_alumno = p_id_alumno
    ORDER BY ce.anyo_inicio, a.nombre;
END$$

DELIMITER ;

-- ============================================================
-- 3. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS trg_calificacion_validar_insert;
DROP TRIGGER IF EXISTS trg_calificacion_validar_update;
DROP TRIGGER IF EXISTS trg_calificacion_auditoria;
DROP TRIGGER IF EXISTS trg_matricula_evitar_duplicado;
DROP TRIGGER IF EXISTS trg_calificacion_fecha;

DELIMITER $$

-- Trigger 1: normaliza el trabajo practico y valida rangos al insertar.
CREATE TRIGGER trg_calificacion_validar_insert
BEFORE INSERT ON calificacion
FOR EACH ROW
BEGIN
    IF NEW.trabajo_practico = 0 THEN
        SET NEW.trabajo_practico = NULL;
    END IF;

    IF NEW.parcial_1 NOT BETWEEN 0 AND 5
       OR NEW.parcial_2 NOT BETWEEN 0 AND 5
       OR NEW.parcial_final NOT BETWEEN 0 AND 5
       OR (NEW.trabajo_practico IS NOT NULL
           AND NEW.trabajo_practico NOT BETWEEN 0 AND 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Las notas deben estar entre 0.00 y 5.00.';
    END IF;
END$$

-- Trigger 2: normaliza el trabajo practico y valida rangos al actualizar.
CREATE TRIGGER trg_calificacion_validar_update
BEFORE UPDATE ON calificacion
FOR EACH ROW
BEGIN
    IF NEW.trabajo_practico = 0 THEN
        SET NEW.trabajo_practico = NULL;
    END IF;

    IF NEW.parcial_1 NOT BETWEEN 0 AND 5
       OR NEW.parcial_2 NOT BETWEEN 0 AND 5
       OR NEW.parcial_final NOT BETWEEN 0 AND 5
       OR (NEW.trabajo_practico IS NOT NULL
           AND NEW.trabajo_practico NOT BETWEEN 0 AND 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Las notas deben estar entre 0.00 y 5.00.';
    END IF;
END$$

-- Trigger 3: guarda historial cuando una calificacion cambia.
CREATE TRIGGER trg_calificacion_auditoria
AFTER UPDATE ON calificacion
FOR EACH ROW
BEGIN
    IF NOT (NEW.parcial_1 <=> OLD.parcial_1)
       OR NOT (NEW.parcial_2 <=> OLD.parcial_2)
       OR NOT (NEW.parcial_final <=> OLD.parcial_final)
       OR NOT (NEW.trabajo_practico <=> OLD.trabajo_practico) THEN

        INSERT INTO historial_calificaciones (
            id_matricula,
            parcial_1_anterior, parcial_1_nuevo,
            parcial_2_anterior, parcial_2_nuevo,
            parcial_final_anterior, parcial_final_nuevo,
            trabajo_practico_anterior, trabajo_practico_nuevo
        )
        VALUES (
            NEW.id,
            OLD.parcial_1, NEW.parcial_1,
            OLD.parcial_2, NEW.parcial_2,
            OLD.parcial_final, NEW.parcial_final,
            OLD.trabajo_practico, NEW.trabajo_practico
        );
    END IF;
END$$

-- Trigger 4: evita una matricula duplicada.
CREATE TRIGGER trg_matricula_evitar_duplicado
BEFORE INSERT ON alumno_se_matricula_asignatura
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM alumno_se_matricula_asignatura
        WHERE id_alumno = NEW.id_alumno
          AND id_asignatura = NEW.id_asignatura
          AND id_curso_escolar = NEW.id_curso_escolar
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite duplicar la matricula.';
    END IF;
END$$

-- Trigger 5: fecha automatica de registro.
CREATE TRIGGER trg_calificacion_fecha
BEFORE INSERT ON calificacion
FOR EACH ROW
BEGIN
    IF NEW.fecha_registro IS NULL THEN
        SET NEW.fecha_registro = NOW();
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 4. PRUEBAS DE LA ACTIVIDAD
-- ============================================================

SELECT id, id_alumno, id_asignatura,
       fnc_calcular_nota_final(id) AS nota_final,
       fnc_obtener_estado_academico(id) AS estado
FROM calificacion;

SELECT fnc_total_creditos_matriculados(1, 1) AS creditos_alumno_1;

SELECT fnc_promedio_general_asignatura(1) AS promedio_asignatura_1;

SELECT fnc_contar_asignaturas_aprobadas(1) AS aprobadas_alumno_1;

CALL sp_generar_acta_curso(1, 1);

CALL sp_reporte_historico_estudiante(1);

CALL sp_reasignar_docente(1, 14, 1, 1);

SELECT * FROM historial_calificaciones;


-- ============================================================
-- FIN DE LA ACTIVIDAD
-- ============================================================
