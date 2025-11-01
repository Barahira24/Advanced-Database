-- NAmes: BARAHIRA JeaN Bosco
-- Student_Number:215003240

--Task1. Split your database into two logical nodes (e.g.BranchDB_A, BranchDB_B) using horizontal fragmentation. 

-- Create logical nodes as schemas
CREATE SCHEMA IF NOT EXISTS BranchDB_A;
CREATE SCHEMA IF NOT EXISTS BranchDB_B;

-- --------- BranchDB_A tables ----------
SET search_path = BranchDB_A, public;

CREATE TABLE IF NOT EXISTS Department (
  DeptID    SERIAL PRIMARY KEY,
  DeptName  VARCHAR(100) NOT NULL,
  Faculty   VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Instructor (
  InstructorID SERIAL PRIMARY KEY,
  FullName     VARCHAR(150) NOT NULL,
  DeptID       INT NOT NULL REFERENCES Department(DeptID) ON DELETE CASCADE,
  Email        VARCHAR(150),
  Phone        VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Course (
  CourseID     SERIAL PRIMARY KEY,
  Title        VARCHAR(200) NOT NULL,
  CreditHours  INT,
  DeptID       INT NOT NULL REFERENCES Department(DeptID) ON DELETE CASCADE,
  InstructorID INT NOT NULL REFERENCES Instructor(InstructorID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Student (
  StudentID   SERIAL PRIMARY KEY,
  FullName    VARCHAR(150) NOT NULL,
  Gender      VARCHAR(10),
  Email       VARCHAR(150),
  YearOfStudy INT
);

CREATE TABLE IF NOT EXISTS Enrollment (
  EnrollID   SERIAL PRIMARY KEY,
  StudentID  INT NOT NULL REFERENCES Student(StudentID) ON DELETE CASCADE,
  CourseID   INT NOT NULL REFERENCES Course(CourseID) ON DELETE CASCADE,
  Semester   VARCHAR(20),
  Status     VARCHAR(20)
);

-- Assessment linked to Enrollment with CASCADE DELETE
CREATE TABLE IF NOT EXISTS Assessment (
  AssessID       SERIAL PRIMARY KEY,
  EnrollID       INT NOT NULL REFERENCES Enrollment(EnrollID) ON DELETE CASCADE,
  AssessmentType VARCHAR(50),
  Score          NUMERIC(5,2),
  Weight         NUMERIC(5,2)
);

-- --------- Horizontal fragmentation (sample inserts) ----------

-- Branch A: Science / Engineering departments and their rows
SET search_path = BranchDB_A, public;

INSERT INTO Department (DeptName, Faculty) VALUES
  ('Computer Science', 'Science'),
  ('Mathematics', 'Science');
INSERT INTO Department (DeptName, Faculty) VALUES
  ('Mathematics', 'Science'),
  ('Physics', 'Science'),
  ('Chemistry', 'Science'),
  ('Biology', 'Science'),
  ('Electrical Engineering', 'Engineering'),
  ('Civil Engineering', 'Engineering'),
  ('Mechanical Engineering', 'Engineering'),
  ('Economics', 'Business and Economics'),
  ('Accounting', 'Business and Economics'),
  ('Marketing', 'Business and Economics'),
  ('Law', 'Law'),
  ('Political Science', 'Arts and Humanities'),
  ('History', 'Arts and Humanities'),
  ('English Literature', 'Arts and Humanities'),
  ('Education', 'Education'),
  ('Nursing', 'Health Sciences'),
  ('Pharmacy', 'Health Sciences'),
  ('Architecture', 'Architecture and Design'),
  ('Environmental Science', 'Science');

Select * FROM Department; 

INSERT INTO Instructor (FullName, DeptID, Email, Phone) VALUES
  ('Dr. Alice Mugenzi', 1, 'alice@uni.edu', '0788000001'),
  ('Prof. John Kamanzi', 2, 'john@uni.edu', '0788000002');

 

SELECT *  FROM Instructor;

INSERT INTO Course (Title, CreditHours, DeptID, InstructorID) VALUES
  ('Database Systems', 3, 1, 1),
  ('Calculus II', 4, 2, 2);

INSERT INTO Student (FullName, Gender, Email, YearOfStudy) VALUES
  ('Jean Bosco', 'Male', 'bosco@student.edu', 2),
  ('Aline Mukamana', 'Female', 'aline@student.edu', 1);

INSERT INTO Enrollment (StudentID, CourseID, Semester, Status) VALUES
  (1, 1, '2025S1', 'Active'),
  (2, 2, '2025S1', 'Active');

INSERT INTO Assessment (EnrollID, AssessmentType, Score, Weight) VALUES
  (1, 'Midterm', 78.5, 40),
  (1, 'Final', 82.0, 60);


  -- Create logical nodes as schemas
CREATE SCHEMA IF NOT EXISTS BranchDB_A;
CREATE SCHEMA IF NOT EXISTS BranchDB_B;

-- --------- BranchDB_B tables (same DDL) ----------

SET search_path = BranchDB_B, public;

CREATE TABLE IF NOT EXISTS Department (
  DeptID    SERIAL PRIMARY KEY,
  DeptName  VARCHAR(100) NOT NULL,
  Faculty   VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Instructor (
  InstructorID SERIAL PRIMARY KEY,
  FullName     VARCHAR(150) NOT NULL,
  DeptID       INT NOT NULL REFERENCES Department(DeptID) ON DELETE CASCADE,
  Email        VARCHAR(150),
  Phone        VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Course (
  CourseID     SERIAL PRIMARY KEY,
  Title        VARCHAR(200) NOT NULL,
  CreditHours  INT,
  DeptID       INT NOT NULL REFERENCES Department(DeptID) ON DELETE CASCADE,
  InstructorID INT NOT NULL REFERENCES Instructor(InstructorID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Student (
  StudentID   SERIAL PRIMARY KEY,
  FullName    VARCHAR(150) NOT NULL,
  Gender      VARCHAR(10),
  Email       VARCHAR(150),
  YearOfStudy INT
);

CREATE TABLE IF NOT EXISTS Enrollment (
  EnrollID   SERIAL PRIMARY KEY,
  StudentID  INT NOT NULL REFERENCES Student(StudentID) ON DELETE CASCADE,
  CourseID   INT NOT NULL REFERENCES Course(CourseID) ON DELETE CASCADE,
  Semester   VARCHAR(20),
  Status     VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Assessment (
  AssessID       SERIAL PRIMARY KEY,
  EnrollID       INT NOT NULL REFERENCES Enrollment(EnrollID) ON DELETE CASCADE,
  AssessmentType VARCHAR(50),
  Score          NUMERIC(5,2),
  Weight         NUMERIC(5,2)
);

-- --------- Horizontal fragmentation (sample inserts) ----------

-- Branch B: Business / Arts departments (disjoint rows)

SET search_path = BranchDB_B, public;

INSERT INTO Department (DeptName, Faculty) VALUES
  ('Accounting', 'Business'),
  ('Marketing', 'Business');

INSERT INTO Instructor (FullName, DeptID, Email, Phone) VALUES
  ('Dr. Eric Nshimiyimana', 1, 'eric@uni.edu', '0788000003'),
  ('Prof. Grace Uwineza', 2, 'grace@uni.edu', '0788000004');

INSERT INTO Course (Title, CreditHours, DeptID, InstructorID) VALUES
  ('Financial Accounting', 3, 1, 1),
  ('Marketing Strategies', 3, 2, 2);
  
Select * FROM Course ;

INSERT INTO Student (FullName, Gender, Email, YearOfStudy) VALUES
  ('Patrick Mugisha', 'Male', 'patrick@student.edu', 3),
  ('Claudine Ingabire', 'Female', 'claudine@student.edu', 2);

INSERT INTO Enrollment (StudentID, CourseID, Semester, Status) VALUES
  (1, 1, '2025S2', 'Active'),
  (2, 2, '2025S2', 'Active');

INSERT INTO Assessment (EnrollID, AssessmentType, Score, Weight) VALUES
  (1, 'Assignment', 88.0, 20),
  (1, 'Final', 75.0, 80);


SHOW config_file;

SELECT gid, prepared, owner, database FROM pg_prepared_xacts;
SELECT * FROM BranchDB_B.student WHERE fullname LIKE 'Remote_Participant%';

-- If the previous attempt failed (transaction aborted), first rollback
ROLLBACK;

-- Start a new transaction in this session
BEGIN;

-- Attempt to update the same row
UPDATE student SET fullname = 'Locked Name B' WHERE studentid = 1;

-- This will block until Session A commits or rolls back



SHOW config_file;


-- Task2. Create a database link between your two schemas Demonstrate a successful remote SELECT and a 
---distributed join between local and remote tables. Include scripts and query results. 

 -- (1) postgres_fdw setup (recommended)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create server pointing to the same DB or a remote DB. Replace connection options.
DROP SERVER IF EXISTS branchb_srv CASCADE;
CREATE SERVER branchb_srv FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', dbname 'BranchDB_B', port '5432');

-- Create user mapping for current_user (replace username/password)
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER branchb_srv
  OPTIONS (user 'postgres', password 'postgres');

-- Import the BranchDB_B schema tables into public schema as foreign tables
-- (or INTO a dedicated schema like "foreign_branchb")
IMPORT FOREIGN SCHEMA BranchDB_B
  LIMIT TO (student, enrollment, course, instructor, department, assessment)
  FROM SERVER branchb_srv INTO public;
  

-- Now you have foreign tables public.student, public.enrollment, etc. backed by BranchDB_B.*
-- Example remote SELECT:
SELECT * FROM public.student LIMIT 5;

-- Example distributed join: join local BranchDB_A.Student with remote Enrollment (foreign table)
SET search_path = BranchDB_A, public;
EXPLAIN ANALYZE
SELECT a.studentid, a.fullname, e.enrollid, e.courseid
FROM student a
JOIN public.enrollment e ON a.studentid = e.studentid
WHERE a.yearofstudy >= 2;

-- (2) dblink (function-style) -- alternative
CREATE EXTENSION IF NOT EXISTS dblink;


-- Open a named dblink connection (replace conn string)
SELECT dblink_connect('conn_branchb', 'host=localhost dbname=BranchDB_B user=postgres password=postgres');

-- Simple remote select via dblink:
SELECT * FROM dblink('conn_branchb', 'SELECT studentid, fullname FROM BranchDB_B.student')
  AS t(studentid INT, fullname TEXT);

-- Distributed join via LATERAL dblink (less efficient than FDW):
SET search_path = BranchDB_A, public;
SELECT a.studentid, a.fullname, b.enrollid, b.courseid
FROM student a
LEFT JOIN LATERAL (
  SELECT * FROM dblink('conn_branchb',
    format('SELECT enrollid, studentid, courseid FROM BranchDB_B.enrollment WHERE studentid = %s', a.studentid)
  ) AS t(enrollid INT, studentid INT, courseid INT)
) b ON true;

---Task3. Enable parallel query execution on a large table (e.g., Transactions, Orders). Use max_parallel_workers_per_gather  instead of /*+ PARALLEL(table, 8) */  
--- Bhint and compare serial vs parallel performance. Show and EXPLAIN PLAN output and execution time.

-- create a large table to test parallelism
CREATE TABLE public.transactions (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMP WITHOUT TIME ZONE,
  amount NUMERIC(12,2),
  account_id INT,
  comment TEXT
);

-- Populate many rows quickly (example 10 million rows). Adjust to your machine.
INSERT INTO public.transactions (created_at, amount, account_id, comment)
SELECT
  NOW() - ((random()*365)::int || ' days')::interval,
  (random()*10000)::numeric(12,2),
  (1 + (random()*1000)::int),
  md5(random()::text)
FROM generate_series(1, 2000000); -- run multiple times or increase count to reach size

-- Check server parallel settings
SHOW max_parallel_workers_per_gather;
SHOW max_parallel_workers;

-- Serial run: force no parallel workers
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS)
SELECT sum(amount) FROM public.transactions WHERE created_at >= '2024-01-01';

-- Parallel run: allow parallel workers
SET max_parallel_workers_per_gather = 2;
SET max_parallel_workers = 8;
EXPLAIN (ANALYZE, BUFFERS)
SELECT sum(amount) FROM public.transactions WHERE created_at >= '2024-01-01';

--TASK4: Write a PL/SQL block performing inserts on both nodes and committing once. Verify atomicity using DBA_2PC_PENDING. Provide SQL code and explanation of results.
-- Connect to remote (BranchDB_B) with dblink named 'conn_branchb' (see Task 2).
-- Connect to remote (BranchDB_B) with dblink named 'conn_branchb' (see Task 2).
-- Step 1: create remote prepared transaction
SELECT dblink_exec('conn_branchb',
  BEGIN;
INSERT INTO BranchDB_B.student(fullname, gender, email, yearofstudy)
VALUES ('Remote_Participant', 'Male', 'remote.part@example.edu', 1);

SELECT dblink_exec('conn_branchb', $$
  BEGIN;
  INSERT INTO BranchDB_B.student(fullname, gender, email, yearofstudy)
  VALUES ('Niyonshuti Francine', 'Female', 'Niyonshuti@gmail.com', 2);
  PREPARE TRANSACTION 'gid_univ_tx_003';
$$);


-- Prepare the transaction with a global ID
PREPARE TRANSACTION 'gid_univ_tx_001';

-- (run on BranchDB_A)
-- ==========================================
-- CREATE EXTENSION IF NOT EXISTS dblink;
-- SELECT dblink_connect('conn_branchb', 'host=localhost port=5432 dbname=BranchDB_B user=postgres password=yourpassword');

-- ==========================================
-- STEP 1: BEGIN and PREPARE on Remote DB
-- ==========================================
SELECT dblink_exec('conn_branchb', $$
  BEGIN;
  INSERT INTO student(fullname, gender, email, yearofstudy)
    VALUES ('Remote_Participant', 'Male', 'remote.part@example.edu', 1);
  PREPARE TRANSACTION 'gid_univ_tx_002';
$$);

SELECT dblink_exec('conn_branchb', $$
  BEGIN;
  INSERT INTO BranchDB_B.student(fullname, gender, email, yearofstudy)
  VALUES ('Remote_Participant', 'Male', 'remote.part@example.edu', 1);
  PREPARE TRANSACTION 'gid_univ_tx_002';
$$);

COMMIT PREPARED 'gid_univ_tx_002'

-- ==========================================
-- STEP 2: BEGIN and PREPARE on Local DB
-- ==========================================
BEGIN;
INSERT INTO BranchDB_A.student(fullname, gender, email, yearofstudy)
VALUES ('Local_Participant', 'Female', 'local.part@example.edu', 1);
PREPARE TRANSACTION 'gid_univ_tx_001';

-- Check prepared transactions locally
SELECT * FROM pg_prepared_xacts;

-- ==========================================
-- STEP 3: COMMIT BOTH PREPARED TRANSACTIONS
-- ==========================================
-- Commit remote first via dblink
SELECT dblink_exec('conn_branchb', $$COMMIT PREPARED 'gid_univ_tx_001';$$);

-- Commit local
COMMIT PREPARED 'gid_univ_tx_001';


-- STEP 4: Verify

-- Check local
SELECT * FROM BranchDB_A.student WHERE email='local.part@example.edu';

-- Check remote via dblink
SELECT * FROM dblink('conn_branchb', 'SELECT * FROM BranchDB_B.student WHERE email=''remote.part@example.edu'';')
AS t(studentid int, fullname text, gender text, email text, yearofstudy int);

-- Cleanup: verify rows inserted on both branches
SELECT * FROM BranchDB_A.student WHERE fullname LIKE 'Local_Participant%';
SELECT * FROM BranchDB_B.student WHERE fullname LIKE 'Remote_Participant%';

--TASK5  Simulate a network failure during a distributed transaction. Check unresolved transactions and resolve them using ROLLBACK FORCE. Submit screenshots and brief explanation of recovery steps.
-- On remote or via dblink_exec:
SELECT dblink_exec('conn_branchb', $$ROLLBACK PREPARED 'gid_univ_tx_001';$$);

SELECT* FROM pg_prepared_xacts;

-- On local:
ROLLBACK PREPARED 'gid_univ_tx_001';


--TASK6: Demonstrate a lock conflict by running two sessions thatupdate the same record from different nodes. Query DBA_LOCKS and interpret results.
-- Session A
SET search_path = BranchDB_A, public;
BEGIN;
UPDATE student SET fullname = 'Locked Name A' WHERE studentid = 1;
-- keep transaction open, do not commit yet
-- On psql: leave this session waiting
ROLLBACK;

--TASK6:Demonstrate a lock conflict by running two sessions that update the same record from different nodes. Query DBA_LOCKS and interpret results.

-- Session A
SET search_path = BranchDB_A, public;
BEGIN;
UPDATE student SET fullname = 'Locked Name A' WHERE studentid = 1;
-- keep transaction open, do not commit yet
-- On psql: leave this session waiting
-- Session B
SET search_path = BranchDB_A, public;
BEGIN;
UPDATE student SET fullname = 'Locked Name B' WHERE studentid = 1;
-- This will block until Session A commits/rollbacks

-- Query pg_locks and pg_stat_activity to find blockers/waiters
SELECT pid, relation::regclass AS relation, mode, granted
FROM pg_locks pl
LEFT JOIN pg_class pc ON pl.relation = pc.oid
WHERE relation::text LIKE '%student%';

-- see blocking relationships
SELECT blocked_locks.pid     AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid    AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_query,
       blocking_activity.query AS blocking_query
FROM  pg_locks blocked_locks
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
 AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
 AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
 AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
 AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
 AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
 AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
 AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
 AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
 AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted AND blocking_locks.granted;

--TASK7: Perform parallel data aggregation or loading using PARALLEL DML. Compare runtime and document improvement in query cost and execution time.
-- create a target summary table

-- Serial run: force no parallel workers
SET max_parallel_workers_per_gather = 0;
SET max_parallel_workers = 0;
SET max_parallel_maintenance_workers = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT studentid,
       count(*) AS courses_taken,
       sum(score * weight / 100.0) AS weighted_sum
FROM (
  SELECT e.enrollid, e.studentid, a.score, a.weight
  FROM BranchDB_A.enrollment e
  JOIN BranchDB_A.assessment a ON e.enrollid = a.enrollid
  UNION ALL
  SELECT e.enrollid, e.studentid, a.score, a.weight
  FROM BranchDB_B.enrollment e
  JOIN BranchDB_B.assessment a ON e.enrollid = a.enrollid
) sub
GROUP BY studentid;

-- Parallel run: allow parallel workers

SET max_parallel_workers_per_gather = 7;
SET max_parallel_workers = 8;
SET max_parallel_maintenance_workers = 4;

EXPLAIN (ANALYZE, BUFFERS)
SELECT studentid,
       count(*) AS courses_taken,
       sum(score * weight / 100.0) AS weighted_sum
FROM (
  SELECT e.enrollid, e.studentid, a.score, a.weight
  FROM BranchDB_A.enrollment e
  JOIN BranchDB_A.assessment a ON e.enrollid = a.enrollid
  UNION ALL
  SELECT e.enrollid, e.studentid, a.score, a.weight
  FROM BranchDB_B.enrollment e
  JOIN BranchDB_B.assessment a ON e.enrollid = a.enrollid
) sub
GROUP BY studentid;

--TASK8: Draw and explain a three-tier architecture for your project (Presentation, Application, Database). Show data flow and interaction with database links.

--- it is drawn in PDF document


--TASK9:Use EXPLAIN PLAN and DBMS_XPLAN.DISPLAY to analyze a distributed join. Discuss optimizer strategy and how data movement is minimized.
-- Ensure foreign tables for BranchDB_B are imported into public via FDW
SET search_path = BranchDB_A, public;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT c.courseid, c.title, e.enrollid, e.studentid
FROM course c
JOIN public.enrollment e ON c.courseid = e.courseid
WHERE c.credithours >= 3;

--TASK10: Run one complex query three ways – centralized, parallel, distributed. Measure time and I/O using AUTOTRACE. Write a half-page analysis on scalability and efficiency.

-- First Create a combined central table

CREATE TABLE public.all_enrollments AS
SELECT *, 'A' AS branch FROM BranchDB_A.enrollment
UNION ALL
SELECT *, 'B' AS branch FROM BranchDB_B.enrollment;

--1 Centralized
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.studentid, s.fullname,
       COUNT(e.enrollid) AS courses_taken,
       SUM(a.score * a.weight / 100.0) AS total_weighted_score
FROM BranchDB_A.student s
LEFT JOIN public.all_enrollments e ON s.studentid = e.studentid
LEFT JOIN BranchDB_A.assessment a ON e.enrollid = a.enrollid
GROUP BY s.studentid, s.fullname
HAVING COUNT(e.enrollid) >= 1;

--2:Parallel Query
SET max_parallel_workers_per_gather = 4;
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.studentid, s.fullname,
       COUNT(e.enrollid) AS courses_taken,
       SUM(a.score * a.weight / 100.0) AS total_weighted_score
FROM BranchDB_A.student s
LEFT JOIN public.all_enrollments e ON s.studentid = e.studentid
LEFT JOIN BranchDB_A.assessment a ON e.enrollid = a.enrollid
GROUP BY s.studentid, s.fullname
HAVING COUNT(e.enrollid) >= 1;

--3:Distributed query:
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.studentid, s.fullname,
       COUNT(e.enrollid) AS courses_taken,
       SUM(a.score * a.weight / 100.0) AS total_weighted_score
FROM BranchDB_A.student s
LEFT JOIN public.enrollment e ON s.studentid = e.studentid
LEFT JOIN BranchDB_A.assessment a ON e.enrollid = a.enrollid
GROUP BY s.studentid, s.fullname
HAVING COUNT(e.enrollid) >= 1;