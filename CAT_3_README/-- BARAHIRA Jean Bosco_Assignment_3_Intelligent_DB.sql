-- BARAHIRA Jean Bosco
-- Student Number: 215003240
-- Assignment_3
---Corrected Table DDL
-- Use schema
ALTER SESSION SET CURRENT_SCHEMA = HEALTHNET;

-- Minimal prerequisite table
CREATE TABLE PATIENT (
    ID NUMBER PRIMARY KEY,
    NAME VARCHAR2(100) NOT NULL
);

-- 2 Corrected PATIENT_MED table
CREATE TABLE PATIENT_MED (
    PATIENT_MED_ID NUMBER PRIMARY KEY,        -- unique id
    PATIENT_ID NUMBER NOT NULL REFERENCES PATIENT(ID), -- must reference an existing patient
    MED_NAME VARCHAR2(80) NOT NULL,           -- mandatory field
    DOSE_MG NUMBER(6,2) CHECK (DOSE_MG >= 0),-- non-negative dose
    START_DT DATE,
    END_DT DATE,
    CONSTRAINT CK_RX_DATES CHECK (
        START_DT IS NULL OR END_DT IS NULL OR START_DT <= END_DT
    ) -- start not after end
);

---3  Failing Inserts
-- 1. Negative dose
INSERT INTO PATIENT_MED (PATIENT_MED_ID, PATIENT_ID, MED_NAME, DOSE_MG)
VALUES (1, 101, 'Aspirin', -10);
-- ERROR: violates CHECK (DOSE_MG >= 0)

-- 2. Start date after end date
INSERT INTO PATIENT_MED (PATIENT_MED_ID, PATIENT_ID, MED_NAME, DOSE_MG, START_DT, END_DT)
VALUES (2, 101, 'Ibuprofen', 200, DATE '2025-12-31', DATE '2025-01-01');
-- ERROR: violates CK_RX_DATES
----PASSING INSERT
-- Add a patient first
INSERT INTO PATIENT (ID, NAME) VALUES (101, 'John Doe');

-- 1. Valid prescription
INSERT INTO PATIENT_MED (PATIENT_MED_ID, PATIENT_ID, MED_NAME, DOSE_MG, START_DT, END_DT)
VALUES (1, 101, 'Aspirin', 50, DATE '2025-10-01', DATE '2025-10-10');

-- 2. Another valid prescription with NULL dates
INSERT INTO PATIENT_MED (PATIENT_MED_ID, PATIENT_ID, MED_NAME, DOSE_MG)
VALUES (2, 101, 'Paracetamol', 500);

----QUESTION 2



CREATE OR REPLACE TRIGGER TRG_BILL_TOTAL_CMP
FOR INSERT OR UPDATE OR DELETE ON BILL_ITEM
COMPOUND TRIGGER

  -- Set to hold affected BILL_IDs
  TYPE t_bill_id_set IS TABLE OF BILL_ITEM.BILL_ID%TYPE;
  g_bill_ids t_bill_id_set := t_bill_id_set();

  -- Row-level BEFORE/AFTER triggers: collect affected BILL_IDs
  BEFORE EACH ROW IS
  BEGIN
    IF INSERTING OR UPDATING THEN
      IF g_bill_ids IS NULL OR NOT g_bill_ids.exists(:NEW.BILL_ID) THEN
        g_bill_ids.EXTEND;
        g_bill_ids(g_bill_ids.COUNT) := :NEW.BILL_ID;
      END IF;
    END IF;

    IF DELETING THEN
      IF g_bill_ids IS NULL OR NOT g_bill_ids.exists(:OLD.BILL_ID) THEN
        g_bill_ids.EXTEND;
        g_bill_ids(g_bill_ids.COUNT) := :OLD.BILL_ID;
      END IF;
    END IF;
  END BEFORE EACH ROW;

  -- Statement-level AFTER trigger: recompute totals and insert audit
  AFTER STATEMENT IS
  BEGIN
    FOR i IN 1 .. g_bill_ids.COUNT LOOP
      DECLARE
        v_old_total NUMBER(12,2);
        v_new_total NUMBER(12,2);
      BEGIN
        SELECT TOTAL INTO v_old_total FROM BILL WHERE ID = g_bill_ids(i);

        SELECT NVL(SUM(AMOUNT),0) INTO v_new_total
        FROM BILL_ITEM
        WHERE BILL_ID = g_bill_ids(i);

        UPDATE BILL
        SET TOTAL = v_new_total
        WHERE ID = g_bill_ids(i);

        -- Insert audit
        INSERT INTO BILL_AUDIT(BILL_ID, OLD_TOTAL, NEW_TOTAL, CHANGED_AT)
        VALUES (g_bill_ids(i), v_old_total, v_new_total, SYSDATE);
      END;
    END LOOP;
  END AFTER STATEMENT;

END TRG_BILL_TOTAL_CMP;
/

----Q3:The starter query is buggy because:

--The join direction is wrong: we need to follow the chain upwards, i.e., current supervisor → next supervisor.

--The hop counter in the anchor starts at 0 but should be 1 if counting steps to top.

--The final MAX(HOPS) scalar subquery has scope issues.

--Sample Data (5–6 rows)
CREATE TABLE STAFF_SUPERVISOR (
    EMPLOYEE VARCHAR2(50),
    SUPERVISOR VARCHAR2(50)
);

INSERT INTO STAFF_SUPERVISOR VALUES ('Alice', 'Bob');
INSERT INTO STAFF_SUPERVISOR VALUES ('Bob', 'Carol');
INSERT INTO STAFF_SUPERVISOR VALUES ('Carol', 'Dana');
INSERT INTO STAFF_SUPERVISOR VALUES ('Eve', 'Bob');
INSERT INTO STAFF_SUPERVISOR VALUES ('Frank', 'Eve');
-- Optional cycle for testing
-- INSERT INTO STAFF_SUPERVISOR VALUES ('Dana', 'Alice'); -- would create a loop
----Correct Recursive Query

WITH RECURSIVE SUPERS(EMP, SUP, HOPS, PATH) AS (   
  -- Anchor member: start at each employee
  SELECT EMPLOYEE, SUPERVISOR, 1 AS HOPS, EMPLOYEE || '>' || SUPERVISOR AS PATH
  FROM STAFF_SUPERVISOR ----

  UNION ALL----

  -- Recursive member: climb the supervision chain
  SELECT s.EMPLOYEE, t.SUP, t.HOPS + 1, t.PATH || '>' || t.SUP
  FROM SUPERS t
  JOIN STAFF_SUPERVISOR s ON t.SUP = s.EMPLOYEE
  WHERE INSTR(t.PATH, s.SUPERVISOR) = 0  -- prevent cycles
)
SELECT EMP, SUP AS TOP_SUPERVISOR, HOPS
FROM SUPERS s1
WHERE HOPS = (
    SELECT MAX(HOPS)
    FROM SUPERS s2
    WHERE s2.EMP = s1.EMP
)
ORDER BY EMP;


-----QUESTION 4 :
--The starter is buggy because:
--The direction of recursion is wrong:
--CHILD/ANCESTOR are reversed in recursion.
--
--The base case starts from CHILD but should start from ANCESTOR.
--The final filter compares the wrong column (ISA.CHILD = 'InfectiousDisease'), it should be ISA.ANCESTOR = 'InfectiousDisease'.
--
--  

--Sample Data
CREATE TABLE DISEASE_ISA (
    CHILD VARCHAR2(100),
    ANCESTOR VARCHAR2(100)
);
INSERT INTO DISEASE_ISA VALUES ('Flu', 'ViralInfection');
INSERT INTO DISEASE_ISA VALUES ('Cold', 'ViralInfection');
INSERT INTO DISEASE_ISA VALUES ('ViralInfection', 'InfectiousDisease');
INSERT INTO DISEASE_ISA VALUES ('BacterialInfection', 'InfectiousDisease');
INSERT INTO DISEASE_ISA VALUES ('Tuberculosis', 'BacterialInfection');  
--Correct Recursive Query
WITH RECURSIVE DISEASE_HIER(CHILD, ANCESTOR,   
    LEVEL, PATH) AS (
  -- Anchor member: start from the top-level ancestor
  SELECT CHILD, ANCESTOR, 1 AS LEVEL, ANCESTOR || '>' || CHILD AS PATH
  FROM DISEASE_ISA
  WHERE ANCESTOR = 'InfectiousDisease'
    

  UNION ALL

  -- Recursive member: find children of current diseases
  SELECT d.CHILD, d.ANCESTOR, h.LEVEL + 1, h.PATH || '>' || d.CHILD
  FROM DISEASE_HIER h
  JOIN DISEASE_ISA d ON h.CHILD = d.ANCESTOR
)
SELECT CHILD, LEVEL
FROM DISEASE_HIER
WHERE ANCESTOR = 'InfectiousDisease'
ORDER BY LEVEL, CHILD;  

-----QUESTION 5 :Spatial Database task for Oracle using SDO_GEOMETRY.

--The issues in the starter are:

--Wrong SRID – should be 4326 (WGS84) instead of 3857.Lat/Lon order swapped – Oracle expects (X=longitude, Y=latitude).

--distance units missing – need 'unit=KM'.

-- placeholder :AMB_POINT – must define the ambulance location as a
-- SDO_GEOMETRY point.
--Corrected Query
-- Define ambulance location (example coordinates)
VAR AMB_POINT SDO_GEOMETRY;
EXEC :AMB_POINT := SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(-73.935242, 40.730610, NULL), NULL, NULL); -- Example: New York City
-- Find nearest hospital within 10 km
SELECT HOSPITAL_ID, NAME, ADDRESS,
    SDO_NN_DISTANCE(1) AS DISTANCE_KM
FROM HOSPITAL
WHERE SDO_NN(LOCATION, :AMB_POINT, 'sdo_num_res=1') = 'TRUE'
AND SDO_WITHIN_DISTANCE(LOCATION, :AMB_POINT, 'distance=10 unit=KM') = 'TRUE';
ORDER BY DISTANCE_KM;
-- Limit to 1 nearest hospital
FETCH FIRST 1 ROW ONLY;