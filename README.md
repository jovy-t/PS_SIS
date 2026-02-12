# PowerSchool SQL & Analytics Repository

## 📊 Project Overview
This repository contains a curated collection of SQL queries and analytical scripts designed to extract, analyze, and report on student data from the PowerSchool SIS. These tools support CALPADS compliance, SMCOE requirements, and district-level data visualization.

> ⚠️ **IMPORTANT:** Never commit files containing Google Drive links, database credentials, or PII (Personally Identifiable Information). Ensure all sensitive files are listed in the `.gitignore`.

---

## 🗂 Folder Structure

```text
/PS_SIS/
│
├── reports/                   # Reporting and Data Extraction
│   ├── smcoe/                 # San Mateo County Office of Education (SMCOE) reports
│   │   ├── big_lift.sql
│   │   └── brigance.sql
│   ├── calpads/               # CALPADS compliance/validation (planned)
│   └── Student_Analytics/     # JS-based data processing & visualization
│       └── LTEL.js            # Long Term English Learner analysis
│
├── utilities/                 # Common joins and helper queries
│
├── docs/                      # Schema documentation & business rules
│   └── powerschool-schema-overview.md
│
├── .gitignore                 # Prevents sensitive files from being uploaded
└── README.md                  # Project overview