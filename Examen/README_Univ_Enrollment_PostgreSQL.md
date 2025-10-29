# BARAHIRA Jean Bosco
# Student Number:215003240
#  University Enrollment & Assessment Tracking System  
### (Distributed PostgreSQL Implementation with FDW, Transactions, Triggers & Recursive SQL)

##  Overview  
This project uses **PostgreSQL** to simulate a **university enrollment and assessment tracking system**.  
It exhibits sophisticated **database concepts** such as:


Data fragmentation and recombination; Foreign Data Wrapper (FDW) for distributed joins; parallel versus serial aggregation; two-phase commit transactions; recursive queries (CTE) for hierarchy roll-up and inference; business rule enforcement using triggers and functions; audit and consistency management
---

##  Project Structure

**A1**  Fragment & Recombine  Horizontal fragmentation of `assessment` data across two nodes 
**A2**  FDW & Cross-Node Join  Create foreign tables and join distributed data 
**A3**  Aggregation  Compare serial vs. parallel aggregation performance   
**A4**  Two-Phase Commit  Show distributed transaction commit/rollback  
**A5**  Lock Conflict  Show distributed lock behavior  
**B6**  Constraints & Validation  
**B7**  Triggers & Auditing 
**B8**  Recursive roll-up using CTE 
**B9**  Mini-Knowledge Base with Transitive Inference (≤10 facts)
**B10** Business Limit Alert (Function + Trigger) (row-budget safe)

---

##  Prerequisites

- **PostgreSQL 14+**
- Access to **two PostgreSQL databases** or logical schemas (Node_A and Node_B)
- Superuser privileges (for FDW setup)
- User credentials (e.g., `postgres/postgres`)

---

##  Setup Instructions

### 1️⃣ Create Schemas
Two logical nodes represent distributed databases:
```sql
CREATE SCHEMA IF NOT EXISTS node_a;
CREATE SCHEMA IF NOT EXISTS node_b;
```

### 2️⃣ Create & Populate Node A (`assessment_a`)
```sql
SET search_path = node_a, public;

CREATE TABLE assessment_a (
  assessment_id INTEGER PRIMARY KEY,
  student_id INTEGER NOT NULL,
  course_id INTEGER NOT NULL,
  assessment_type VARCHAR(50),
  score NUMERIC(5,2) CHECK (score BETWEEN 0 AND 100),
  taken_on DATE
);
```

Insert even-numbered records (2,4,6,8,10).

### 3️ Create & Populate Node B (`student`, `course`, `assessment_b`)
```sql
SET search_path = node_b, public;
CREATE TABLE student (...);
CREATE TABLE course (...);
CREATE TABLE assessment_b (...);
```
Insert odd-numbered records (1,3,5,7,9) for `assessment_b`.

### 4️ Setup Foreign Data Wrapper (FDW)
FDW allows **cross-node queries**.

```sql
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER proj_link FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'Node_B', port '5432');

CREATE USER MAPPING FOR CURRENT_USER SERVER proj_link
OPTIONS (user 'postgres', password 'postgres');
```

Import foreign tables:
```sql
IMPORT FOREIGN SCHEMA public LIMIT TO (student, course, assessment_b)
FROM SERVER proj_link INTO public;
```

### 5️ Unified View (Recombination)
```sql
CREATE VIEW assessment_all AS
SELECT * FROM node_a.assessment_a
UNION ALL
SELECT * FROM public.assessment_b_fwd;
```

Validate:
```sql
SELECT COUNT(*) AS total_rows, SUM(assessment_id % 97) AS checksum
FROM assessment_all;
```

### 6️ Distributed Join (A2)
```sql
SELECT a.assessment_id, a.student_id, a.score, cf.course_name
FROM assessment_a a
JOIN course_foreign cf ON a.course_id = cf.course_id
WHERE a.score >= 70;
```

### 7️ Aggregation (A3)
Compare serial and parallel execution:
```sql
EXPLAIN ANALYZE
SELECT course_id, COUNT(*) AS cnt, ROUND(AVG(score)::numeric,2) AS avg_score
FROM assessment_all
GROUP BY course_id;
```

Enable parallel workers:
```sql
SET LOCAL max_parallel_workers_per_gather = 4;
```

### 8️ Two-Phase Commit (A4)
Simulate distributed transaction commit and rollback.

### 9️ Lock Conflict Simulation (A5)
Hold locks to demonstrate blocking and conflict resolution.

---

##  Section B — Logical Design & Constraints

### **B6: Enrollment & Assessment**
Create base tables with integrity constraints and test inserts.

### **B7: Audit Trigger**
Maintains GPA and logs changes to `Enrollment_AUDIT` after every DML operation on `Assessment`.

### **B8: Recursive Hierarchy Roll-Up**
Recursive query computes aggregated totals per root using a 3-level hierarchy.

### **B9: Transitive Inference**
Implements recursive inference rules using a `TRIPLE` fact table.

### **B10: Business Rule Enforcement**
Implements trigger and function to restrict scores beyond `BUSINESS_LIMITS` threshold.



##  Testing Summary

| Test Type | Description | Expected Result |
|-----------|-------------|-----------------|
| FDW Join | Query across nodes | Returns ≤10 joined rows |
| Parallel Aggregation | Speed improvement visible in `EXPLAIN` | Parallel workers shown |
| Two-Phase Commit | Prepared → Commit | Visible in `pg_prepared_xacts` |
| Constraint Violations | Invalid inserts | Rejected |
| Trigger (B7) | Audit logging | Rows added in `Enrollment_AUDIT` |
| Recursive Query | Hierarchy roll-up | Aggregated totals per root |
| Business Rule (B10) | Score > threshold | Raises exception |

---

##  Author & Credits
**Prepared by:** BARAHIRA Jean Bosco  
**Course:** Advanced Database Technology  
**Instructor:** RUKUNDO Prince  
**Database System:** PostgreSQL 14+  
