# 🔔 Custom Popup Alerts (MBA Alert Creator)

This folder contains custom modifications and SQL logic for the **MBA Alert Creator** plugin within the PowerSchool SIS. These alerts are designed to surface critical student information directly to teachers and admin staff via the student header.

---

## 🚀 Alert Catalog

| Alert Name | Components | Description | Status |
| :--- | :--- | :--- | :--- |
| **CA EC 49079 - Student Incident** | [Display](./ec49079_alert.html) / [Query](./ec49079.html) | Notifies staff if a student has been suspended or expelled (EC 48900) within the last 3 years. | ✅ Production |
| **LIP: Dual-Language Immersion** | [Query](./DualImmersion.html) | Alerts staff if a student has an active or historical LIP code of *301*. Ensures continuity of course content. | ✅ Production |
| **Special Education (IEP)** | [Display](./sped_alert.html) | Links IEP documents directly in the alert popup using a custom PowerQuery. | ✅ Production |
| **Primary Disability Mapping** | [Query](./disability_alert_main.html) | Cross-references `S_CA_STU_CALPADSPROGRAMS_C` and `S_CA_STU_X` for disability codes. | 🚧 WIP |

---

## 🛠 Technical Architecture & Constraints

### 1. The Use of `~[tlist_sql]`
In modern PowerSchool development, `~[tlist_sql]` is **strongly deprecated**. It executes SQL directly on the page, which presents security risks (SQL injection) and performance bottlenecks.
* **Why it is used here:** The **MBA Alert Creator** plugin requires a `.html` trigger file containing this specific tag to determine which students should display an alert. 
* **The Alternative:** For any development outside of this specific plugin, `~[datatable]` or `PowerQueries` (JSON-based) should be used instead.

### 2. Avoiding `WITH` (CTE) and `EXISTS`
While standard Oracle SQL supports Common Table Expressions (CTEs) and `EXISTS` clauses, the PowerSchool `tlist_sql` parser is a legacy tool. 
* **Parser Limitations:** Complex nested logic or `WITH` blocks often fail to render because the parser struggles to hand off the query to the database correctly.
* **The Fix:** We use **Self-Joins** or **Flattened Subqueries** (`IN` / `NOT IN`) to ensure compatibility with the legacy tag.

### 3. Logic: Inclusion vs. Exclusion
To handle inconsistent data entry across various school sites:
1. **Action Requirement:** The incident MUST have an action code of Suspension (100) or Expulsion (200). This filters out "Minor" incidents that resulted only in detention.
2. **Exclusion List:** Rather than listing every possible serious behavior, the query excludes "non-qualifying" behaviors (e.g., Tobacco, Defiance) to ensure the alert remains legally accurate.