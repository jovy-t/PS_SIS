# PowerQueries: CCGI Student File + Course Grade File

## Overview

This PowerSchool plugin contains the PowerQueries used to support the **CaliforniaColleges.edu (CCGI)** integration.

It includes:

- Student File PowerQuery
- Course Grade File PowerQuery

## PowerQueries Included

### 1. Student File

**Purpose**
- Extracts student demographic, enrollment, GPA, race/ethnicity, and program participation data
- Used for CCGI Student Template

### 2. Course Grade File

**Purpose**
- Extracts transcript/course history data
- Used for CCGI Course Grade Template

---

## What is a PowerQuery?

> A reusable SQL-based data source that can be accessed via API or internal tools.

It allows you to:
- complex SQL logic (CTEs, joins, transformations)
- structured JSON output
- integration with external systems

## Why is a Plugin Required?

PowerQueries must be packaged inside a PowerSchool plugin.

The `plugin.xml` file:
- registers queries
- defines table/field access
- enables API exposure

## OAuth Configuration

```xml
<oauth></oauth>
This enables OAuth API access for the plugin.
- Client ID / Client Secret generation
- secure API access via OAuth 2.0

## PowerQuery Design Notes (IMPORTANT)

PowerQuery has several **strict limitations** that impact how SQL must be written. These are not SQL errors — they are specific to how PowerQuery parses and validates queries.

### 1. Column Lineage Requirement
PowerQuery must be able to trace every output column back to a **base table and field**. CTEs are allowed, but they must not obscure the origin of output columns.

❌ This will break:
```sql
WITH x AS (
    SELECT course_number FROM sections
)
SELECT course_number FROM x;
```

### Why this happens
PowerQuery is not a full SQL engine. It validates queries by tracking where each column originates.

When a column is passed through a CTE or subquery without directly referencing the base table in the final SELECT, PowerQuery loses that connection.

### What works
Always reference columns directly from a base table alias in the final SELECT:
```sql
SELECT sec.course_number
FROM sections sec;
```
### Best Practices
Use CTEs only for:
- filtering
- ranking (ROW_NUMBER)
- deduplication
- lookup tables
Avoid renaming core fields inside CTEs unless they are not used in the final SELECT
