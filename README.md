# PowerSchool SQL Query Repository

## 📊 PowerSchool SQL Queries

This repository contains a curated collection of SQL queries designed to extract, analyze, and report on student data from the PowerSchool SIS. These queries are tailored to support CALPADS reporting, student program tracking, district reporting, and other custom needs.

> ⚠️ **Note:** These queries are specific to our district's schema and requirements and may require modification to run in other environments.

---

## 🗂 Folder Structure

```text
/powerschool-sql-queries/
│
├── reports/                # All report-based SQL queries
│   ├── smcoe/              # Reports required by San Mateo County Office of Education (SMCOE)
│   │   ├── big_lift.sql
│   │   └── brigance.sql
│   └── calpads/            # CALPADS compliance or validation reports (planned)
│
├── utilities/             # Common joins, views, or helper queries (planned)
│
├── docs/                  # Documentation for schema, data definitions, and business rules
│   └── powerschool-schema-overview.md
│
├── .gitignore             # Ignore config files or secure data
├── README.md              # Project overview
└── .env (optional)        # DB credentials (DO NOT COMMIT)
