
# Advanced Database Technology (DSC6235)
## Continuous Assessment One

**Student Name:** BARAHIRA Jean Bosco  
**Student Number:** 215003240  
**Lecturers:** Dr. Eric Hitimana & Prince Rukundo  

---

##  Project Overview
This project implements a **university enrollment and assessment tracking system** in **PostgreSQL**.  
It demonstrates advanced relational database design concepts, including:
- **Primary & Foreign Key Constraints**
- **Cascading Deletes**
- **Triggers and Stored Functions**
- **Views and Derived Tables**
- **Data Validation with CHECK Constraints**
- **Automated GPA Recalculation via Triggers**

---

##  1. Database Schema
The system models several entities commonly found in a university setting:

| Table | Description |
|--------|--------------|
| **Department** | Stores department and faculty information. |
| **Instructor** | Contains instructors linked to departments. |
| **Course** | Courses offered by departments, each assigned to an instructor. |
| **Student** | Student profiles with gender, email, and year of study. |
| **Enrollment** | Tracks which students are registered for which courses and semesters. |
| **Assessment** | Stores marks and weights for assignments, quizzes, and finals. |
| **SemesterGPA** | Records computed GPA per student per semester (trigger maintained). |

Each table includes **data integrity constraints** such as `NOT NULL`, `UNIQUE`, and `CHECK`.

---

##  2. Key Functionalities

###  a) Data Insertion
- Sample data includes:
  - 3 departments
  - 3 instructors
  - 5 courses
  - 10 students with enrollments and assessments across two semesters.

###  b) Function: `fn_final_grade_for_enroll`
Computes a student’s **final numeric grade** for a given enrollment using weighted scores.

```sql
SELECT fn_final_grade_for_enroll(1);
```

###  c) Grade & GPA Calculation
Grades are converted into letter grades (`A`, `B`, `C`, `D`, `F`) and grade points (0–4 scale).  
The GPA per semester is computed automatically by the trigger `trg_recalc_gpa_after_assess_update`.

###  d) Trigger Function: `fn_recalc_semester_gpa`
Automatically recalculates GPA whenever an assessment is **inserted, updated, or deleted**.

###  e) View: `view_avg_grade_per_department`
Summarizes the **average final grades per department** for performance analysis.

```sql
SELECT * FROM view_avg_grade_per_department;
```

---

##  3. Example Queries

### a) Retrieve students’ grades with letter classification:
```sql
SELECT s."FullName", c."Title", e."Semester",
       ROUND(fn_final_grade_for_enroll(e."EnrollID"),2) AS FinalPercent,
       CASE
         WHEN fn_final_grade_for_enroll(e."EnrollID") >= 85 THEN 'A'
         WHEN fn_final_grade_for_enroll(e."EnrollID") >= 70 THEN 'B'
         WHEN fn_final_grade_for_enroll(e."EnrollID") >= 60 THEN 'C'
         WHEN fn_final_grade_for_enroll(e."EnrollID") >= 50 THEN 'D'
         ELSE 'F'
       END AS LetterGrade
FROM "Enrollment" e
JOIN "Student" s ON s."StudentID" = e."StudentID"
JOIN "Course" c ON c."CourseID" = e."CourseID";
```

### b) Detect students failing more than two courses:
```sql
SELECT s."FullName", COUNT(*) AS FailedCourses
FROM "Enrollment" e
JOIN "Student" s ON s."StudentID" = e."StudentID"
JOIN (
  SELECT "EnrollID", fn_final_grade_for_enroll("EnrollID") AS final_percent
  FROM "Enrollment"
) fg ON fg."EnrollID" = e."EnrollID"
WHERE fg.final_percent < 50
GROUP BY s."FullName"
HAVING COUNT(*) > 2;
```

---

##  4. How to Run in PostgreSQL

1. Open **pgAdmin** or **psql**.
2. Create a new database, e.g.:
   ```sql
   CREATE DATABASE advanced_db_tech;
   ```
3. Copy all SQL code into **VS Code** → save as `university_system.sql`.
4. Run the file in PostgreSQL:
   ```bash
   \i 'path_to_your_file/university_system.sql';
   ```
5. Verify data using sample queries:
   ```sql
   SELECT * FROM "Student";
   SELECT * FROM "SemesterGPA";
   ```

---

##  5. Expected Results
- Automatic GPA calculation after any grade update.
- View summarizing departmental average performance.
- Data integrity maintained by strong constraints and FK relations.
- Logical structure demonstrating **advanced database design principles**.

---

##  6. Files
| File Name | Description |
|-----------|-------------|
| `university_system.sql` | Main PostgreSQL script for schema and data. |
| `README.md` | This explanatory document. |

---

##  Author
**BARAHIRA Jean Bosco**  
**Advanced Database Technology (DSC6235)**  

