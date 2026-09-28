USE universidad;

-- ============================================================
-- FUNCIONES, PROCEDIMIENTOS Y TRIGGERS
-- Basado en la actividad del PDF
-- ============================================================

-- PREPARACION
ALTER TABLE calificacion ADD COLUMN fecha_registro DATETIME NULL;

CREATE TABLE IF NOT EXISTS historial_calificaciones (
 id_historial INT AUTO_INCREMENT PRIMARY KEY,
 id_matricula INT NOT NULL,
 parcial_1_anterior DECIMAL(5,2), parcial_1_nuevo DECIMAL(5,2),
 parcial_2_anterior DECIMAL(5,2), parcial_2_nuevo DECIMAL(5,2),
 parcial_final_anterior DECIMAL(5,2), parcial_final_nuevo DECIMAL(5,2),
 trabajo_practico_anterior DECIMAL(5,2), trabajo_practico_nuevo DECIMAL(5,2),
 fecha_cambio DATETIME NOT NULL
);

DROP FUNCTION IF EXISTS fnc_calcular_nota_final;
DROP FUNCTION IF EXISTS fnc_obtener_estado_academico;
DROP FUNCTION IF EXISTS fnc_total_creditos_matriculados;
DROP FUNCTION IF EXISTS fnc_promedio_general_asignatura;
DROP FUNCTION IF EXISTS fnc_contar_asignaturas_aprobadas;

DELIMITER $$

CREATE FUNCTION fnc_calcular_nota_final(p_id_matricula INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
 DECLARE p1,p2,pf,tp DECIMAL(5,2);
 SELECT parcial_1,parcial_2,parcial_final,trabajo_practico
 INTO p1,p2,pf,tp FROM calificacion WHERE id=p_id_matricula;
 IF tp IS NULL THEN
   RETURN ROUND((p1*.20)+(p2*.35)+(pf*.45),2);
 END IF;
 RETURN ROUND((p1*.20)+(p2*.35)+(pf*.35)+(tp*.10),2);
END$$

CREATE FUNCTION fnc_obtener_estado_academico(p_id_matricula INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
 IF fnc_calcular_nota_final(p_id_matricula)>=3.00 THEN
   RETURN 'APROBADO';
 END IF;
 RETURN 'REPROBADO';
END$$

CREATE FUNCTION fnc_total_creditos_matriculados(p_id_alumno INT,p_id_curso_escolar INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
 DECLARE total DECIMAL(10,2);
 SELECT COALESCE(SUM(a.creditos),0) INTO total
 FROM alumno_se_matricula_asignatura m
 JOIN asignatura a ON a.id=m.id_asignatura
 WHERE m.id_alumno=p_id_alumno AND m.id_curso_escolar=p_id_curso_escolar;
 RETURN total;
END$$

CREATE FUNCTION fnc_promedio_general_asignatura(p_id_asignatura INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
 DECLARE promedio DECIMAL(5,2);
 SELECT ROUND(AVG(fnc_calcular_nota_final(id)),2) INTO promedio
 FROM calificacion WHERE id_asignatura=p_id_asignatura;
 RETURN COALESCE(promedio,0);
END$$

CREATE FUNCTION fnc_contar_asignaturas_aprobadas(p_id_alumno INT)
RETURNS INT
READS SQL DATA
BEGIN
 DECLARE total INT;
 SELECT COUNT(*) INTO total FROM calificacion
 WHERE id_alumno=p_id_alumno AND fnc_calcular_nota_final(id)>=3.00;
 RETURN total;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_guardar_calificacion;
DROP PROCEDURE IF EXISTS sp_generar_acta_curso;
DROP PROCEDURE IF EXISTS sp_matricular_alumno;
DROP PROCEDURE IF EXISTS sp_reasignar_docente;
DROP PROCEDURE IF EXISTS sp_reporte_historico_estudiante;

DELIMITER $$

CREATE PROCEDURE sp_guardar_calificacion(
 IN p_id_alumno INT, IN p_id_asignatura INT, IN p_id_curso_escolar INT,
 IN p_parcial_1 DECIMAL(5,2), IN p_parcial_2 DECIMAL(5,2),
 IN p_parcial_final DECIMAL(5,2), IN p_trabajo_practico DECIMAL(5,2))
BEGIN
 DECLARE v_id INT;
 SELECT MAX(id) INTO v_id FROM calificacion
 WHERE id_alumno=p_id_alumno AND id_asignatura=p_id_asignatura
 AND id_curso_escolar=p_id_curso_escolar;
 IF v_id IS NULL THEN
   INSERT INTO calificacion(id_alumno,id_asignatura,id_curso_escolar,
    parcial_1,parcial_2,parcial_final,trabajo_practico,fecha_registro)
   VALUES(p_id_alumno,p_id_asignatura,p_id_curso_escolar,
    p_parcial_1,p_parcial_2,p_parcial_final,p_trabajo_practico,NOW());
 ELSE
   UPDATE calificacion SET parcial_1=p_parcial_1,parcial_2=p_parcial_2,
    parcial_final=p_parcial_final,trabajo_practico=p_trabajo_practico
   WHERE id=v_id;
 END IF;
END$$

CREATE PROCEDURE sp_generar_acta_curso(IN p_id_asignatura INT,IN p_id_curso_escolar INT)
BEGIN
 SELECT p.nif documento,
 CONCAT(p.nombre,' ',p.apellido1,' ',COALESCE(p.apellido2,'')) nombre_completo,
 c.parcial_1,c.parcial_2,c.parcial_final,c.trabajo_practico,
 fnc_calcular_nota_final(c.id) nota_final
 FROM calificacion c JOIN persona p ON p.id=c.id_alumno
 WHERE c.id_asignatura=p_id_asignatura AND c.id_curso_escolar=p_id_curso_escolar
 ORDER BY p.apellido1,p.apellido2,p.nombre;
END$$

CREATE PROCEDURE sp_matricular_alumno(IN p_id_alumno INT,IN p_id_asignatura INT,IN p_id_curso_escolar INT)
BEGIN
 IF EXISTS(SELECT 1 FROM alumno_se_matricula_asignatura
  WHERE id_alumno=p_id_alumno AND id_asignatura=p_id_asignatura
  AND id_curso_escolar=p_id_curso_escolar) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El alumno ya esta matriculado.';
 ELSE
  INSERT INTO alumno_se_matricula_asignatura
  VALUES(p_id_alumno,p_id_asignatura,p_id_curso_escolar);
 END IF;
END$$

CREATE PROCEDURE sp_reasignar_docente(IN p_id_asignatura INT,IN p_id_profesor INT,IN p_id_departamento INT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM profesor
  WHERE id_profesor=p_id_profesor AND id_departamento=p_id_departamento) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El profesor no pertenece al departamento.';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM asignatura WHERE id=p_id_asignatura) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La asignatura no existe.';
 END IF;
 UPDATE asignatura SET id_profesor=p_id_profesor WHERE id=p_id_asignatura;
END$$

CREATE PROCEDURE sp_reporte_historico_estudiante(IN p_id_alumno INT)
BEGIN
 SELECT p.nif documento,
 CONCAT(p.nombre,' ',p.apellido1,' ',COALESCE(p.apellido2,'')) estudiante,
 a.nombre asignatura, ce.anyo_inicio,ce.anyo_fin,
 CONCAT(pd.nombre,' ',pd.apellido1,' ',COALESCE(pd.apellido2,'')) profesor,
 ca.parcial_1,ca.parcial_2,ca.parcial_final,ca.trabajo_practico,
 fnc_calcular_nota_final(ca.id) nota_final
 FROM calificacion ca
 JOIN persona p ON p.id=ca.id_alumno
 JOIN asignatura a ON a.id=ca.id_asignatura
 JOIN curso_escolar ce ON ce.id=ca.id_curso_escolar
 LEFT JOIN profesor pr ON pr.id_profesor=a.id_profesor
 LEFT JOIN persona pd ON pd.id=pr.id_profesor
 WHERE ca.id_alumno=p_id_alumno
 ORDER BY ce.anyo_inicio,a.nombre;
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_calificacion_before_insert;
DROP TRIGGER IF EXISTS trg_calificacion_before_update;
DROP TRIGGER IF EXISTS trg_calificacion_after_update;
DROP TRIGGER IF EXISTS trg_matricula_before_insert;

DELIMITER $$

-- TRIGGER 1, 3 y 5: normalizacion, rango y fecha.
CREATE TRIGGER trg_calificacion_before_insert
BEFORE INSERT ON calificacion FOR EACH ROW
BEGIN
 IF NEW.trabajo_practico=0 THEN SET NEW.trabajo_practico=NULL; END IF;
 IF NEW.parcial_1<0 OR NEW.parcial_1>5 OR NEW.parcial_2<0 OR NEW.parcial_2>5
 OR NEW.parcial_final<0 OR NEW.parcial_final>5
 OR (NEW.trabajo_practico IS NOT NULL AND
     (NEW.trabajo_practico<0 OR NEW.trabajo_practico>5)) THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Las notas deben estar entre 0.00 y 5.00.';
 END IF;
 IF NEW.fecha_registro IS NULL THEN SET NEW.fecha_registro=NOW(); END IF;
END$$

CREATE TRIGGER trg_calificacion_before_update
BEFORE UPDATE ON calificacion FOR EACH ROW
BEGIN
 IF NEW.trabajo_practico=0 THEN SET NEW.trabajo_practico=NULL; END IF;
 IF NEW.parcial_1<0 OR NEW.parcial_1>5 OR NEW.parcial_2<0 OR NEW.parcial_2>5
 OR NEW.parcial_final<0 OR NEW.parcial_final>5
 OR (NEW.trabajo_practico IS NOT NULL AND
     (NEW.trabajo_practico<0 OR NEW.trabajo_practico>5)) THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Las notas deben estar entre 0.00 y 5.00.';
 END IF;
END$$

-- TRIGGER 2: auditoria de cambios.
CREATE TRIGGER trg_calificacion_after_update
AFTER UPDATE ON calificacion FOR EACH ROW
BEGIN
 IF NOT(NEW.parcial_1 <=> OLD.parcial_1)
 OR NOT(NEW.parcial_2 <=> OLD.parcial_2)
 OR NOT(NEW.parcial_final <=> OLD.parcial_final)
 OR NOT(NEW.trabajo_practico <=> OLD.trabajo_practico) THEN
  INSERT INTO historial_calificaciones(
   id_matricula,parcial_1_anterior,parcial_1_nuevo,
   parcial_2_anterior,parcial_2_nuevo,parcial_final_anterior,
   parcial_final_nuevo,trabajo_practico_anterior,trabajo_practico_nuevo,
   fecha_cambio)
  VALUES(NEW.id,OLD.parcial_1,NEW.parcial_1,OLD.parcial_2,NEW.parcial_2,
   OLD.parcial_final,NEW.parcial_final,OLD.trabajo_practico,
   NEW.trabajo_practico,NOW());
 END IF;
END$$

-- TRIGGER 4: evita matriculas duplicadas.
CREATE TRIGGER trg_matricula_before_insert
BEFORE INSERT ON alumno_se_matricula_asignatura FOR EACH ROW
BEGIN
 IF EXISTS(SELECT 1 FROM alumno_se_matricula_asignatura
  WHERE id_alumno=NEW.id_alumno AND id_asignatura=NEW.id_asignatura
  AND id_curso_escolar=NEW.id_curso_escolar) THEN
  SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT='No se permite duplicar la matricula.';
 END IF;
END$$

DELIMITER ;

-- ============================================================
-- PRUEBAS
-- ============================================================
-- SELECT fnc_calcular_nota_final(1);
-- SELECT fnc_obtener_estado_academico(1);
-- SELECT fnc_total_creditos_matriculados(1,1);
-- SELECT fnc_promedio_general_asignatura(1);
-- SELECT fnc_contar_asignaturas_aprobadas(1);
-- CALL sp_guardar_calificacion(1,1,1,4,3.5,4.2,NULL);
-- CALL sp_generar_acta_curso(1,1);
-- CALL sp_matricular_alumno(1,1,1);
-- CALL sp_reasignar_docente(1,1,1);
-- CALL sp_reporte_historico_estudiante(1);
