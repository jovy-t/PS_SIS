# 📊 PowerSchool SQL & Analytics Repository

## 🚀 Project Overview
This repository contains a curated collection of SQL queries, analytical scripts, and PowerSchool customizations designed to extract, analyze, and report on student data. These tools support CALPADS compliance, SMCOE requirements, and district-level data visualization.

---

## 🗂 Folder Structure

| Section | Description |
| :--- | :--- |
| 🔌 **[Plugins](./Plugins)** | Customizations for MBA Alert Creator and D63 Start Page Alerts. |
| 📝 **[Reports](./reports)** | SQL and JS scripts for SMCOE, CALPADS, and Student Analytics. |
| 🛠 **[Utilities](./utilities)** | Common SQL joins, views, and helper scripts. |
| 📖 **[Docs](./docs)** | PowerSchool schema documentation and business rules. |

```text
/PS_SIS/
│
├── Plugins/                   # PowerSchool Plugin Customizations
│   ├── Custom_Alert/          # MBA Alert Creator modifications
│   └── StartPageAlert/        # D63 Start Page Alert enhancements
│
├── reports/                   # Reporting and Data Extraction
│   ├── smcoe/                 # San Mateo County (SMCOE) reports
│   ├── calpads/               # CALPADS compliance/validation
│   └── Student_Analytics/     # JS-based data processing (LTEL.js)
│
├── utilities/                 # Common joins and helper queries
├── docs/                      # Schema documentation & business rules
├── .gitignore                 # Prevents sensitive files from being uploaded
└── README.md                  # Project overview