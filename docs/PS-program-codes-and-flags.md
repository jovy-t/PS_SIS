# Program Codes & Flags

This document outlines program-related fields for tracking student participation in programs like EL, SPED, 504, and Foster Youth.

## English Learners (EL)

| Field                     | Table             | Description                      |
|--------------------------|-------------------|----------------------------------|
| `elastatus`              | `s_ca_stu_x`      | Current EL status                |
| `elastatusstartdate`     | `s_ca_stu_ela_c`  | Date of current EL status        |
| `primarylanguagedesc`    | `s_ca_stu_ela_c`  | Language used at home            |

## SPED

| Field                | Table        | Description                      |
|---------------------|--------------|----------------------------------|
| `primarydisability` | `s_ca_stu_x` | Primary disability code          |
| `spentrydate`       | `s_ca_stu_x` | Date of SPED program start       |

## Section 504

| Field     | Table        | Description            |
|----------|--------------|------------------------|
| `sped504`| `s_ca_stu_x` | Boolean or code flag   |

## Foster Youth

| Field           | Table        | Description                   |
|----------------|--------------|-------------------------------|
| `fosterprogram`| `s_ca_stu_x` | Participation in foster care  |

## Free/Reduced Meals

| Field        | Table     | Description            |
|--------------|-----------|------------------------|
| `lunchstatus`| `students`| FRPM eligibility code  |
