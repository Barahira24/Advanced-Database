
Detailed README File: Distributed PostgreSQL Project
**Name:** BARAHIRA Jean Bosco
**Student Number:** 215003240
**Module:** Advanced Database Systems
**Project Title:** University Enrollment & Assessment Tracking System using Distributed PostgreSQL Databases

1. Project Description
This project demonstrates the implementation of a distributed database environment in PostgreSQL. It simulates a university enrollment and assessment system, distributed across two logical nodes representing different departments (Science/Engineering and Business/Arts). The objective is to apply advanced database concepts including horizontal fragmentation, foreign data wrappers (FDW), distributed transactions, parallel query execution, locking mechanisms, and performance optimization.
2. Database Architecture
The system uses two logical schemas to simulate distributed database nodes:
**BranchDB_A** : stores Science and Engineering departments.
**BranchDB_B** : stores Business and Arts departments.

Each schema maintains identical table structures for Department, Instructor, Course, Student, Enrollment, and Assessment. Horizontal fragmentation is achieved by storing disjoint subsets of data in each schema.
3. Implementation Steps

**Task 1:** Horizontal Fragmentation
Both BranchDB_A and BranchDB_B schemas were created to represent distributed nodes. Tables for Department, Instructor, Course, Student, Enrollment, and Assessment were created identically in both schemas. Data was horizontally fragmented by department type: Science and Engineering data stored in BranchDB_A, and Business and Arts data stored in BranchDB_B.

**Task 2:** Database Link and Distributed Join
A database link between BranchDB_A and BranchDB_B was established using two approaches:
1. **postgres_fdw**  created a foreign data wrapper and imported BranchDB_B tables into public schema.
2. **dblink** established connection using dblink_connect and executed remote SQL queries.   

A distributed join query combined local (BranchDB_A) and remote (BranchDB_B) student and enrollment data to verify seamless data integration.
**Task 3:** Parallel Query Execution

A large table (public.transactions) was created to test parallel query processing. The parameter `max_parallel_workers_per_gather` was adjusted to compare performance between serial and parallel executions. The EXPLAIN (ANALYZE, BUFFERS) command was used to measure query plans and execution time differences.

**Task 4:** Distributed Transaction and Atomicity
A PL/pgSQL block simulated a distributed transaction across both BranchDB_A and BranchDB_B using the two-phase commit protocol. Each branch prepared and committed transactions with unique Global IDs (GIDs). Atomicity was verified using `pg_prepared_xacts` and committed using `COMMIT PREPARED`. This ensured data consistency across distributed nodes.

**Task 5:** Network Failure and Recovery
A network failure was simulated by interrupting a distributed transaction mid-execution. Unresolved transactions were detected using `pg_prepared_xacts`. Recovery was achieved via `ROLLBACK PREPARED` and verified by re-querying affected tables.

**Task 6:** Lock Conflict Simulation
Two concurrent sessions were used to update the same student record, simulating a lock conflict. `pg_locks` and `pg_stat_activity` views were queried to identify blocking and waiting processes. The test demonstrated PostgreSQL’s concurrency control and deadlock detection mechanisms.

**Task 7:** Parallel Data Aggregation
Parallel DML was demonstrated by aggregating scores from both branches using UNION ALL queries. Performance was tested with varying parallel worker settings (`max_parallel_workers_per_gather`). Parallelism improved execution efficiency for large aggregations.

**Task 8:** Three-Tier Architecture
The project follows a standard 3-tier architecture:
1. Presentation Layer : user interface or query tool (e.g., pgAdmin, psql).
2. Application Layer : query logic and transaction coordination.
3. Database Layer : distributed data nodes (BranchDB_A and BranchDB_B) connected via FDW and dblink.

Data flows from presentation through the application to the respective database nodes, using FDW for remote data access.

**Task 9:** Query Plan Analysis
EXPLAIN PLAN and DBMS_XPLAN were used to analyze distributed joins between BranchDB_A and BranchDB_B. The optimizer minimized data movement by applying local filters before sending results across nodes. This reduced network I/O and improved query efficiency.

**Task 10:** Scalability and Efficiency Analysis
A complex query was executed in three modes—centralized, parallel, and distributed—to assess scalability. Parallel and distributed modes exhibited faster performance and lower I/O costs. Findings confirmed that distributed parallel execution is more scalable for large datasets.
4. Execution Instructions
1. Execute all SQL scripts in PostgreSQL (v15 or above).
2. Create both schemas: BranchDB_A and BranchDB_B.
3. Load data into each schema.
4. Configure postgres_fdw or dblink for inter-schema connections.
5. Run distributed and parallel queries sequentially.
6. Use EXPLAIN ANALYZE to measure execution times.
7. Simulate transaction failures and verify rollback or commit.
8. Observe lock conflicts using pg_locks during concurrent updates.
5. Performance Observations
• Horizontal fragmentation improved manageability and reduced query scope per node.
• postgres_fdw performed better than dblink due to integrated query planning.
• Parallel queries achieved up to 2x faster performance for aggregations.
• Two-phase commit maintained atomicity across branches during distributed inserts.
• Lock conflict simulation verified PostgreSQL’s concurrency and isolation guarantees.
6. Conclusion
The project successfully showcases distributed database principles implemented in PostgreSQL. It demonstrates horizontal fragmentation, inter-database communication, distributed transactions, parallelism, and recovery mechanisms. These concepts are foundational for designing scalable, reliable, and fault-tolerant distributed database systems.


**Prepared by:** BARAHIRA Jean Bosco  
**Course:** Advanced Database Technology  
**Instructor:** RUKUNDO Prince  
**Database System:** PostgreSQL 14+ 
