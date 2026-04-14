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
