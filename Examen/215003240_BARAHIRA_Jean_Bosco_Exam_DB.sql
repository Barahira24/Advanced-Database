-- BARAHIRA Jean Bosco
-- STUDENT NUMBER: 215003240

CREATE SCHEMA IF NOT EXISTS node_a;
CREATE SCHEMA IF NOT EXISTS node_b;

-- A1:1 Create assessment tables on respective schemas
SET search_path = node_a, public;

CREATE TABLE IF NOT EXISTS assessment_a (
  assessment_id INTEGER PRIMARY KEY,
  student_id    INTEGER NOT NULL,
  course_id     INTEGER NOT NULL,
  assessment_type VARCHAR(50),
  score         NUMERIC(5,2) CHECK (score >= 0 AND score <= 100),
  taken_on      DATE
);

-- Node_A (even ids: 2,4,6,8,10)
INSERT INTO node_a.assessment_a (assessment_id, student_id, course_id, assessment_type, score, taken_on) VALUES
 (2, 101, 1001, 'Exam',    88.0, '2025-02-05'),
 (4, 102, 1003, 'Project', 91.5, '2025-02-12'),
 (6, 103, 1002, 'Exam',    79.0, '2025-02-22'),
 (8, 106, 1004, 'Quiz',    69.0, '2025-03-02'),
 (10,107,1001, 'Project', 95.0, '2025-03-07')
ON CONFLICT DO NOTHING;

SELECT * FROM node_a.assessment_a; 

-- 0. Setup schemas for simulated nodes
CREATE SCHEMA IF NOT EXISTS node_a;
CREATE SCHEMA IF NOT EXISTS node_b;

SET search_path = node_a, public;

-- 0.1 (optional) create a small students and courses table on node_b to support joins in A2
SET search_path = node_b, public;

CREATE TABLE IF NOT EXISTS student (
  student_id INTEGER PRIMARY KEY,
  full_name  TEXT NOT NULL,
  major      TEXT
);

CREATE TABLE IF NOT EXISTS course (
  course_id INTEGER PRIMARY KEY,
  course_code TEXT NOT NULL,
  title TEXT,
  dept TEXT
);

-- seed students and courses (these are small and will be used by distributed join)
INSERT INTO node_b.student(student_id, full_name, major) VALUES
 (101,'Alice Johnson','CompSci'),
 (102,'Bob Smith','Math'),
 (103,'Carol Li','Eng'),
 (104,'Dan K','Hist'),
 (105,'Eva R','CompSci')
ON CONFLICT DO NOTHING;

INSERT INTO node_b.course(course_id, course_code, title, dept) VALUES
 (1001,'CS101','Intro CS','CS'),
 (1002,'CS201','Data Structures','CS'),
 (1003,'MATH101','Calculus I','Math'),
 (1004,'ENG101','Intro Eng','Eng')
ON CONFLICT DO NOTHING;

SET search_path = node_b, public;

CREATE TABLE IF NOT EXISTS assessment_b (
  assessment_id INTEGER PRIMARY KEY,
  student_id    INTEGER NOT NULL,
  course_id     INTEGER NOT NULL,
  assessment_type VARCHAR(50),
  score         NUMERIC(5,2) CHECK (score >= 0 AND score <= 100),
  taken_on      DATE
);

-- 2.Insert a total of 10 committed rows split 5/5 (we will reuse these rows across all tasks)
-- Node_B (odd ids: 1,3,5,7,9)
INSERT INTO node_b.assessment_b (assessment_id, student_id, course_id, assessment_type, score, taken_on) VALUES
 (1, 101, 1001, 'Quiz',    78.5, '2025-02-01'),
 (3, 102, 1001, 'Exam',    85.0, '2025-02-10'),
 (5, 103, 1002, 'Project', 92.0, '2025-02-20'),
 (7, 104, 1003, 'Exam',    66.5, '2025-03-01'),
 (9, 105, 1002, 'Quiz',    74.0, '2025-03-05')
ON CONFLICT DO NOTHING;
select * from assessment_b;

SELECT* FROM node_b.assessment_b;
 
-- On Node_B, create course table and insert same data
-- Then join local + remote:
SELECT a.assessment_id, a.student_id, a.score, c.course_name
FROM assessment_a a
JOIN courseproj_link c ON a.course_id = c.course_id
WHERE a.score >= 70;  -- selective predicate to keep ≤10 rows

--3 FDW setup (on node_a)
SET search_path = node_a, public;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
DROP SERVER proj_link cascade;
CREATE SERVER proj_link FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'Node_B', port '5432');


CREATE USER MAPPING FOR CURRENT_USER SERVER proj_link
OPTIONS (user 'postgres', password 'postgres');
IMPORT FOREIGN SCHEMA public LIMIT TO (student, course, assessment_b)
FROM SERVER proj_link INTO public;

ROLLBACK;

DROP FOREIGN TABLE IF EXISTS public.assessment_b_fwd;

CREATE FOREIGN TABLE public.assessment_b_fwd (
  assessment_id INTEGER,
  student_id    INTEGER,
  course_id     INTEGER,
  assessment_type VARCHAR(50),
  score         NUMERIC(5,2),
  taken_on      DATE
)
SERVER proj_link
OPTIONS (schema_name 'node_b', table_name 'assessment_b');


SELECT * FROM public.assessment_b_fwd;

DROP VIEW IF EXISTS assessment_all;
CREATE VIEW assessment_all AS
SELECT * FROM assessment_a
UNION ALL
SELECT * FROM public.assessment_b_fwd;
select * from assessment_all;
-- Validation
SELECT COUNT(*) AS total_rows, SUM(assessment_id % 97) AS checksum
FROM assessment_all;

select * from node_b.assessment_b;
-- create foreign table that references node_b.assessment_b
DROP FOREIGN TABLE IF EXISTS assessment_b_foreign;
CREATE FOREIGN TABLE assessment_b_foreign (
  assessment_id INTEGER,
  student_id    INTEGER,
  course_id     INTEGER,
  assessment_type VARCHAR(50),
  score         NUMERIC(5,2),
  taken_on      DATE
) SERVER proj_link OPTIONS (schema_name 'node_b', table_name 'assessment_b');

SELECT *  FROM assessment_b;
SELECT *  FROM public.assessment_b;

--A2: Database Link & Cross-Node Join (3–10 rows result) 

--1. From Node_A, create database link 'proj_link' to Node_B. 
-- Sample Student table on Node_B
DROP FOREIGN TABLE IF EXISTS public.student_b;

CREATE FOREIGN TABLE public.student_b (
    student_id   INTEGER,
 full_name  TEXT NOT NULL,
  major      TEXT
)
SERVER proj_link
OPTIONS (schema_name 'node_b', table_name 'student');
----
SELECT * FROM public.student_b LIMIT 5;

--- Creating a table called course_foreign 
DROP FOREIGN TABLE IF EXISTS public.course_foreign;

CREATE FOREIGN TABLE public.course_foreign (
  course_id   INTEGER,
  course_name VARCHAR(100)
)
SERVER proj_link
OPTIONS (schema_name 'public', table_name 'course');


-- A2.2: distributed join: local assessment_a joined to remote course@proj_link
-- Use a selective predicate to return between 3 and 10 rows
-- We'll join local assessment_a to remote course_foreign on course_id and filter score >= 70
SELECT a.assessment_id, a.student_id, a.score, cf.course_name
FROM assessment_a a
JOIN course_foreign cf ON a.course_id = cf.course_id
WHERE a.score >= 70
ORDER BY a.assessment_id;

INSERT INTO course VALUES

=== A3 — Parallel vs Serial Aggregation (Node_A) ===
A3.1 SERIAL aggregation (planner chooses plan)
EXPLAIN ANALYZE
SELECT course_id, COUNT(*) AS cnt, ROUND(AVG(score)::numeric,2) AS avg_score
FROM assessment_all
GROUP BY course_id
ORDER BY course_id;

-- A3.2 Encourage a parallel plan (topic: set at session level)
-- Increase parallel workers per gather for the session (may require superuser to change GUC)
SET LOCAL max_parallel_workers_per_gather = 4;
-- Also allow parallel sequential scans (default allowed)
EXPLAIN ANALYZE
SELECT course_id, COUNT(*) AS cnt, ROUND(AVG(score)::numeric,2) AS avg_score
FROM assessment_all
GROUP BY course_id
ORDER BY course_id;

=== A4 — Two-Phase Commit & Recovery (manual two-phase across two DB sessions) ===
-- Session A (Node_A)
BEGIN;
INSERT INTO assessment_a (assessment_id, student_id, course_id, assessment_type, score, taken_on)
 VALUES (12, 108, 1003, 'Quiz', 80.0, '2025-03-10');
-- do NOT COMMIT; instead prepare the transaction
PREPARE TRANSACTION 'tx_node_a';

-- Session B (Node_B)
BEGIN;
INSERT INTO assessment_b (assessment_id, student_id, course_id, assessment_type, score, taken_on)
 VALUES (11, 109, 1004, 'Project', 85.0, '2025-03-12');
PREPARE TRANSACTION 'tx_node_b';
-- Now both nodes have prepared transactions.

-- On Node_A:
COMMIT PREPARED 'tx_node_a';

-- On Node_B:
COMMIT PREPARED 'tx_node_b';

-- On Node_A and Node_B:
SELECT * FROM pg_prepared_xacts;

-- On Node_A:
ROLLBACK PREPARED 'tx_node_a';
-- On Node_B:
ROLLBACK PREPARED 'tx_node_b';

-- On Node_A:
SELECT * FROM assessment_a WHERE assessment_id IN (12);

-- On Node_B:
SELECT * FROM assessment_b WHERE assessment_id IN (11);

=== A5 — Distributed Lock Conflict & Diagnosis (multi-session demo) ===

-- Session 1 (Node_A)
BEGIN;
UPDATE assessment_a SET score = score + 1 WHERE assessment_id = 2;
-- keep this transaction open; do NOT commit yet


------------------------SECTION B------------------------------------------

 1. Enrollment table
-- ---------------------------
CREATE TABLE Enrollment (
    enrollid SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    gpa NUMERIC(3,2) DEFAULT 0 CHECK (gpa >= 0 AND gpa <= 4)
);


-- 2. Assessment table
-- ---------------------------
CREATE TABLE Assessment (
    assessid SERIAL PRIMARY KEY,
    enrollment_id INT NOT NULL REFERENCES Enrollment(enrollid) ON DELETE CASCADE,
    score NUMERIC(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),
    weight NUMERIC(5,2) NOT NULL CHECK (weight > 0 AND weight <= 100)
);

-- ---------------------------
-- 3. HIER table for hierarchy
-- ---------------------------
CREATE TABLE HIER (
    parent_id INT NOT NULL,
    child_id INT NOT NULL
);

--B2
-- 1. Add NOT NULL and CHECK constraints to Enrollment and Assessment
ALTER TABLE Enrollment
    ALTER COLUMN student_id SET NOT NULL,
    ALTER COLUMN course_id SET NOT NULL,
    ADD CONSTRAINT chk_gpa_positive CHECK (gpa >= 0 AND gpa <= 4);

ALTER TABLE Assessment
    ALTER COLUMN enrollment_id SET NOT NULL,
    ALTER COLUMN score SET NOT NULL,
    ALTER COLUMN weight SET NOT NULL,
    ADD CONSTRAINT chk_score_weight CHECK (score >= 0 AND score <= 100),
    ADD CONSTRAINT chk_weight_positive CHECK (weight > 0 AND weight <= 100);

-- 2. Test inserts (2 passing, 2 failing per table)
BEGIN;

-- Passing Enrollment inserts
INSERT INTO Enrollment(student_id, course_id, gpa) VALUES (1, 101, 3.5);
INSERT INTO Enrollment(student_id, course_id, gpa) VALUES (2, 102, 4.0);

-- Failing Enrollment inserts
SAVEPOINT fail_enrollment;
INSERT INTO Enrollment(student_id, course_id, gpa) VALUES (3, 103, -1); -- Fails chk_gpa_positive
INSERT INTO Enrollment(student_id, course_id, gpa) VALUES (4, 104, 5);  -- Fails chk_gpa_positive
EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT fail_enrollment;

-- Passing Assessment inserts
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (1, 80, 20);
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (2, 90, 30);

-- Failing Assessment inserts
SAVEPOINT fail_assessment;
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (1, -5, 10); -- Fails chk_score_weight
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (2, 50, 0);  -- Fails chk_weight_positive
EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT fail_assessment;

COMMIT;

-- 3. Proof
SELECT * FROM Enrollment;
SELECT * FROM Assessment;


----B7
-- 1. Create audit table
CREATE TABLE Enrollment_AUDIT (
    bef_total NUMERIC,
    aft_total NUMERIC,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    key_col VARCHAR(64)
);

-- 2. Trigger to update denormalized total
CREATE OR REPLACE FUNCTION trg_update_enrollment_total() RETURNS TRIGGER AS $$
DECLARE
    before_total NUMERIC;
    after_total NUMERIC;
BEGIN
    -- Compute totals before change
    SELECT SUM(score * weight / 100) INTO before_total FROM Assessment;
    
    -- Update Enrollment totals
    UPDATE Enrollment e
    SET gpa = sub.total
    FROM (
        SELECT enrollment_id, SUM(score * weight / 100) AS total
        FROM Assessment
        GROUP BY enrollment_id
    ) sub
    WHERE e.enrollid = sub.enrollment_id;

    -- Compute totals after change
    SELECT SUM(score * weight / 100) INTO after_total FROM Assessment;

    -- Insert audit record
    INSERT INTO Enrollment_AUDIT(bef_total, aft_total, key_col)
    VALUES (before_total, after_total, 'ALL');

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enrollment_total
AFTER INSERT OR UPDATE OR DELETE ON Assessment
FOR EACH STATEMENT
EXECUTE FUNCTION trg_update_enrollment_total();


SELECT * FROM Enrollment;
SELECT * FROM Enrollment_AUDIT;


ALTER TABLE Enrollment
    ALTER COLUMN gpa TYPE NUMERIC(5,2);  -- now max total = 999.99

	----CREATING TRIGGER
	CREATE OR REPLACE FUNCTION trg_update_enrollment_total() RETURNS TRIGGER AS $$
DECLARE
    before_total NUMERIC;
    after_total NUMERIC;
BEGIN
    -- Compute total before DML
    SELECT SUM(score * weight / 100) INTO before_total FROM Assessment;

    -- Update Enrollment totals safely
    UPDATE Enrollment e
    SET gpa = LEAST(4, sub.total)  -- cap GPA to 4
    FROM (
        SELECT enrollment_id, SUM(score * weight / 100) AS total
        FROM Assessment
        GROUP BY enrollment_id
    ) sub
    WHERE e.enrollid = sub.enrollment_id;

    -- Compute total after DML
    SELECT SUM(score * weight / 100) INTO after_total FROM Assessment;

    -- Log into audit
    INSERT INTO Enrollment_AUDIT(bef_total, aft_total, key_col)
    VALUES (before_total, after_total, 'ALL');

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
DROP TRIGGER IF EXISTS trg_enrollment_total ON Assessment;
CREATE TRIGGER trg_enrollment_total
AFTER INSERT OR UPDATE OR DELETE ON Assessment
FOR EACH STATEMENT
EXECUTE FUNCTION trg_update_enrollment_total();



-----
-- Passing inserts
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (1, 70, 20);
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (2, 85, 30);

-- Update affecting 1 row
UPDATE Assessment SET score = 90 WHERE enrollment_id = 1;

-- Optional insert within limits
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (1, 60, 10);

-- Check results
SELECT * FROM Assessment;
SELECT * FROM Enrollment;
SELECT * FROM Enrollment_AUDIT;

----B8: Recursive Hierarchy Roll-Up
-- 1. Create hierarchy table
CREATE TABLE HIER(
    parent_id INT,
    child_id INT
);


---- 2. Insert 6–10 rows forming a 3-level hierarchy
INSERT INTO HIER(parent_id, child_id) VALUES
(1, 2), (1, 3),
(2, 4), (2, 5),
(3, 6);

-- 1️⃣ Recursive CTE to roll up from HIER (no permanent table needed)
WITH RECURSIVE hier_rollup AS (
    -- Base level: parent → child
    SELECT 
        parent_id,
        child_id,
        parent_id AS root_id,
        1 AS depth
    FROM hier

    UNION ALL

    -- Recursive step: climb the hierarchy
    SELECT 
        h.parent_id,
        h.child_id,
        r.root_id,
        r.depth + 1
    FROM hier h
    JOIN hier_rollup r ON h.parent_id = r.child_id
)

-- 2️⃣ Join recursive result to Assessment to compute totals
SELECT 
    h.root_id,
    ROUND(SUM(a.score * a.weight / 100), 2) AS total_score
FROM hier_rollup h
JOIN assessment a 
    ON a.enrollment_id = h.child_id
GROUP BY h.root_id
ORDER BY h.root_id;

----
CREATE OR REPLACE VIEW hier_rollup AS
WITH RECURSIVE rollup AS (
    SELECT parent_id, child_id, parent_id AS root_id, 1 AS depth
    FROM hier
    UNION ALL
    SELECT h.parent_id, h.child_id, r.root_id, r.depth + 1
    FROM hier h
    JOIN rollup r ON h.parent_id = r.child_id
)
SELECT * FROM rollup;
----
SELECT h.root_id, SUM(a.score * a.weight / 100) AS total
FROM hier_rollup h
JOIN assessment a ON a.enrollment_id = h.child_id
GROUP BY h.root_id
ORDER BY h.root_id;


----B9 Mini-Knowledge Base with Transitive Inference (≤10 facts) 

-- 1. Create triple table
CREATE TABLE TRIPLE(
    s VARCHAR(64),
    p VARCHAR(64),
    o VARCHAR(64)
);


-- 2. Insert 8–10 facts
INSERT INTO TRIPLE(s,p,o) VALUES
('Math101','isA','Course'),
('Course','isA','Subject'),
('Physics101','isA','Course'),
('Science','isA','Subject'),
('Course101','isA','Math101'),
('AdvancedMath','isA','Course'),
('CS101','isA','Course'),
('Programming','isA','Subject');

-- 3. Recursive transitive inference
WITH RECURSIVE infer(s,o) AS (
    SELECT s, o FROM triple WHERE p='isA'
    UNION
    SELECT i.s, t.o
    FROM infer i
    JOIN triple t ON i.o = t.s AND t.p='isA'
),
grouped AS (
    SELECT o, COUNT(*) AS cnt FROM infer GROUP BY o
)
SELECT * FROM grouped;

----

-- B10: Business Limit Alert (Function + Trigger)

-- 1. Create BUSINESS_LIMITS
CREATE TABLE BUSINESS_LIMITS(
    rule_key VARCHAR(64),
    threshold NUMERIC,
    active CHAR(1) CHECK (active IN ('Y','N'))
);





INSERT INTO BUSINESS_LIMITS(rule_key, threshold, active) VALUES
('MAX_SCORE', 95, 'Y');

-- 2. Function to check alert
CREATE OR REPLACE FUNCTION fn_should_alert(p_enroll INT, p_score NUMERIC) RETURNS INT AS $$
DECLARE
    lim NUMERIC;
BEGIN
    SELECT threshold INTO lim
    FROM BUSINESS_LIMITS
    WHERE active='Y' LIMIT 1;

    IF p_score > lim THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger on Assessment
CREATE OR REPLACE FUNCTION trg_business_limit() RETURNS TRIGGER AS $$
BEGIN
    IF fn_should_alert(NEW.enrollment_id, NEW.score) = 1 THEN
        RAISE EXCEPTION 'Score % exceeds business limit', NEW.score;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_limit
BEFORE INSERT OR UPDATE ON Assessment
FOR EACH ROW
EXECUTE FUNCTION trg_business_limit();

-- 4. Demonstrate passing/failing inserts
BEGIN;
-- Passing
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (1, 80, 20);
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (2, 90, 25);

-- Failing
SAVEPOINT fail_business;
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (1, 100, 10); -- Fails
INSERT INTO Assessment(enrollment_id, score, weight) VALUES (2, 99, 15);  -- Fails
EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT fail_business;

COMMIT;

-- Check final committed data
SELECT * FROM Assessment;