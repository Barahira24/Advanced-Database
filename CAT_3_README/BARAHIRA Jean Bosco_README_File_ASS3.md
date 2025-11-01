  
**Names:** BARAHIRA Jean Bosco  
**Student Number:** 215003240  

---

##  Overview
This project demonstrates advanced **Oracle SQL and PL/SQL concepts**, including data validation with constraints, compound triggers, recursive queries, and spatial operations.  
All scripts are written for execution inside **VS Code SQL tools** or **SQL*Plus** connected to an Oracle database.

---

##  Question 1 — Table DDL and Validation Constraints

### Schema Setup
```sql
ALTER SESSION SET CURRENT_SCHEMA = HEALTHNET;
```

### Patient Tables
```sql
CREATE TABLE PATIENT (
    ID NUMBER PRIMARY KEY,
    NAME VARCHAR2(100) NOT NULL
);

CREATE TABLE PATIENT_MED (
    PATIENT_MED_ID NUMBER PRIMARY KEY,
    PATIENT_ID NUMBER NOT NULL REFERENCES PATIENT(ID),
    MED_NAME VARCHAR2(80) NOT NULL,
    DOSE_MG NUMBER(6,2) CHECK (DOSE_MG >= 0),
    START_DT DATE,
    END_DT DATE,
    CONSTRAINT CK_RX_DATES CHECK (
        START_DT IS NULL OR END_DT IS NULL OR START_DT <= END_DT
    )
);
```

### Failing and Passing Inserts
```sql
-- Invalid inserts (will fail)
INSERT INTO PATIENT_MED VALUES (1, 101, 'Aspirin', -10, NULL, NULL);
INSERT INTO PATIENT_MED VALUES (2, 101, 'Ibuprofen', 200, DATE '2025-12-31', DATE '2025-01-01');

-- Valid inserts
INSERT INTO PATIENT VALUES (101, 'John Doe');
INSERT INTO PATIENT_MED VALUES (1, 101, 'Aspirin', 50, DATE '2025-10-01', DATE '2025-10-10');
INSERT INTO PATIENT_MED VALUES (2, 101, 'Paracetamol', 500, NULL, NULL);
```

---

##  Question 2 — Compound Trigger on `BILL_ITEM`
This trigger recalculates totals and logs audit records whenever a bill item changes.

```sql
CREATE OR REPLACE TRIGGER TRG_BILL_TOTAL_CMP
FOR INSERT OR UPDATE OR DELETE ON BILL_ITEM
COMPOUND TRIGGER
  TYPE t_bill_id_set IS TABLE OF BILL_ITEM.BILL_ID%TYPE;
  g_bill_ids t_bill_id_set := t_bill_id_set();

  BEFORE EACH ROW IS
  BEGIN
    IF INSERTING OR UPDATING THEN
      g_bill_ids.EXTEND;
      g_bill_ids(g_bill_ids.COUNT) := :NEW.BILL_ID;
    ELSIF DELETING THEN
      g_bill_ids.EXTEND;
      g_bill_ids(g_bill_ids.COUNT) := :OLD.BILL_ID;
    END IF;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR i IN 1 .. g_bill_ids.COUNT LOOP
      DECLARE
        v_old_total NUMBER(12,2);
        v_new_total NUMBER(12,2);
      BEGIN
        SELECT TOTAL INTO v_old_total FROM BILL WHERE ID = g_bill_ids(i);
        SELECT NVL(SUM(AMOUNT),0) INTO v_new_total FROM BILL_ITEM WHERE BILL_ID = g_bill_ids(i);
        UPDATE BILL SET TOTAL = v_new_total WHERE ID = g_bill_ids(i);
        INSERT INTO BILL_AUDIT(BILL_ID, OLD_TOTAL, NEW_TOTAL, CHANGED_AT)
        VALUES (g_bill_ids(i), v_old_total, v_new_total, SYSDATE);
      END;
    END LOOP;
  END AFTER STATEMENT;
END TRG_BILL_TOTAL_CMP;
/
```

---

##  Question 3 — Recursive Query for Employee Supervision Chain
Finds the top supervisor for each employee using recursion.

```sql
CREATE TABLE STAFF_SUPERVISOR (EMPLOYEE VARCHAR2(50), SUPERVISOR VARCHAR2(50));

INSERT INTO STAFF_SUPERVISOR VALUES ('Alice', 'Bob');
INSERT INTO STAFF_SUPERVISOR VALUES ('Bob', 'Carol');
INSERT INTO STAFF_SUPERVISOR VALUES ('Carol', 'Dana');
INSERT INTO STAFF_SUPERVISOR VALUES ('Eve', 'Bob');
INSERT INTO STAFF_SUPERVISOR VALUES ('Frank', 'Eve');

WITH RECURSIVE SUPERS(EMP, SUP, HOPS, PATH) AS (
  SELECT EMPLOYEE, SUPERVISOR, 1, EMPLOYEE || '>' || SUPERVISOR FROM STAFF_SUPERVISOR
  UNION ALL
  SELECT s.EMPLOYEE, t.SUP, t.HOPS + 1, t.PATH || '>' || t.SUP
  FROM SUPERS t
  JOIN STAFF_SUPERVISOR s ON t.SUP = s.EMPLOYEE
  WHERE INSTR(t.PATH, s.SUPERVISOR) = 0
)
SELECT EMP, SUP AS TOP_SUPERVISOR, HOPS
FROM SUPERS s1
WHERE HOPS = (SELECT MAX(HOPS) FROM SUPERS s2 WHERE s2.EMP = s1.EMP)
ORDER BY EMP;
```

---

##  Question 4 — Recursive Disease Hierarchy
Traces all child diseases from the ancestor `InfectiousDisease`.

```sql
CREATE TABLE DISEASE_ISA (CHILD VARCHAR2(100), ANCESTOR VARCHAR2(100));

INSERT INTO DISEASE_ISA VALUES ('Flu', 'ViralInfection');
INSERT INTO DISEASE_ISA VALUES ('Cold', 'ViralInfection');
INSERT INTO DISEASE_ISA VALUES ('ViralInfection', 'InfectiousDisease');
INSERT INTO DISEASE_ISA VALUES ('BacterialInfection', 'InfectiousDisease');
INSERT INTO DISEASE_ISA VALUES ('Tuberculosis', 'BacterialInfection');

WITH RECURSIVE DISEASE_HIER(CHILD, ANCESTOR, LEVEL, PATH) AS (
  SELECT CHILD, ANCESTOR, 1, ANCESTOR || '>' || CHILD
  FROM DISEASE_ISA
  WHERE ANCESTOR = 'InfectiousDisease'
  UNION ALL
  SELECT d.CHILD, d.ANCESTOR, h.LEVEL + 1, h.PATH || '>' || d.CHILD
  FROM DISEASE_HIER h
  JOIN DISEASE_ISA d ON h.CHILD = d.ANCESTOR
)
SELECT CHILD, LEVEL
FROM DISEASE_HIER
WHERE ANCESTOR = 'InfectiousDisease'
ORDER BY LEVEL, CHILD;
```

---

##  Question 5 — Spatial Query (SDO_GEOMETRY)
Finds the nearest hospital within 10 km of an ambulance location.

```sql
VAR AMB_POINT SDO_GEOMETRY;
EXEC :AMB_POINT := SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(-73.935242, 40.730610, NULL), NULL, NULL);

SELECT HOSPITAL_ID, NAME, ADDRESS, SDO_NN_DISTANCE(1) AS DISTANCE_KM
FROM HOSPITAL
WHERE SDO_NN(LOCATION, :AMB_POINT, 'sdo_num_res=1') = 'TRUE'
  AND SDO_WITHIN_DISTANCE(LOCATION, :AMB_POINT, 'distance=10 unit=KM') = 'TRUE'
ORDER BY DISTANCE_KM
FETCH FIRST 1 ROW ONLY;
```

---

##  Summary
This project covered:
- Table constraints and data validation
- Compound triggers for automated auditing
- Recursive queries for hierarchical relationships
- Spatial operations with `SDO_GEOMETRY`

