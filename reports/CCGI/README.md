# CCGI Integration

## Overview
An end-to-end ETL pipeline that extracts data from PowerSchool SIS through custom PowerQueries, performs minimal transformation aligned with CCGI requirements, and outputs structured CSV files for submission.

---

## Architecture

| Layer | Purpose |
|------|--------|
| PowerQuery | Data extraction from PowerSchool Oracle |
| Python scripts | Mapping + light transformation + validation |
| Output folder | Final CSV files |
| (Future) SFTP | Delivery to CCGI |

---

## Process

### 1. Extract (PowerQuery)

PowerQueries are installed in PowerSchool and expose structured data via the Schema API.

The `ccgi_common.py` module handles:
- Loading environment variables (`.env`)
- OAuth authentication (`client_credentials`)
- Calling PowerQuery endpoints (`/ws/schema/query/...`)
- Passing required query parameters (e.g., `school_year_start`)
- Handling pagination (`pagesize`, `page`)
- Returning JSON records

**Important Notes:**
- API execution is stricter than Oracle APEX
- Query parameters must match expected types (e.g., `school_year_start` must be numeric, not string)
- Missing fields are omitted from API response (not returned as null)

### 2. Transform (Python)

Scripts:
- `export_ccgi_student_file.py`
- `export_ccgi_course_grade_file.py`
- `export_ccgi_course_catalog_file.py`

Responsibilities:
- Map PowerQuery fields → CCGI schema
- Preserve API data as-is (no assumptions or derived defaults unless explicitly required)
- Handle missing fields by inserting blank values in CSV
- Ensure all required CCGI headers are present and ordered correctly
- Keep transformation logic minimal (business logic primarily handled in PowerQuery)

**Design Approach:**
- PowerQuery handles most data shaping and fallback logic
- Python layer focuses on:
  - field mapping
  - schema alignment
  - output formatting

### 3. Load

- Outputs CSV files to `/output`