# PowerSchool Schema Overview

This document outlines the key PowerSchool database tables used in district-level SQL reporting and extracts.

## Core Tables

| Table              | Purpose                                              |
|-------------------|------------------------------------------------------|
| `students`        | Stores core student records (name, dob, contacts)   |
| `reenrollments`   | Stores historical/supplemental enrollment records   |
| `schools`         | Lookup for school names and numbers                 |
| `studentrace`     | Holds individual race codes per student             |
| `s_ca_stu_x`      | Stores CA-specific extension fields (SPED, 504, EL) |
| `s_ca_stu_ela_c`  | Stores detailed EL status history per student       |

## Key Field Notes

- `students.dcid`: Primary join key for most extension tables.
- `students.id`: Used for joins like `studentrace.studentid` and `reenrollments.studentid`.
- `entrydate` / `exitdate`: Must be filtered correctly to match school year windows.
- `exitcode`: Values starting with `N` or `100` often mean “No Show” or completed.

## Best Practices

- Use `LEFT JOIN` for optional data (e.g., demographics, race).
- Use `NVL(exitdate, TO_DATE(...))` to ensure current students are included.
- Use consistent aliasing (`s`, `re`, `dem`, `sch`, etc.).
