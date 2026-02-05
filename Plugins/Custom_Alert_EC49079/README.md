# California EC 49079 - Student Incident Alert

## Project Overview
This project implements a custom PowerSchool alert based on **California Education Code 49079**. It notifies teachers when a student has engaged in (or is suspected of) conduct that is grounds for suspension or expulsion (EC 48900) within the last three years.

## Technical Architecture & Constraints

### 1. The Use of `~[tlist_sql]`
In modern PowerSchool development, `~[tlist_sql]` is **strongly deprecated**. It executes SQL directly on the page, which presents security risks (SQL injection) and performance bottlenecks.
* **Why it is used here:** The **MBA Alert Creator** plugin (a common third-party tool) requires a `.html` trigger file containing this specific tag to determine which students should display an alert. 
* **The Alternative:** For any development outside of this specific plugin, `~[datatable]` or `PowerQueries` (JSON-based) should be used instead.

### 2. Avoiding `WITH` (CTE) and `EXISTS`
While standard Oracle SQL supports Common Table Expressions (CTEs) and `EXISTS` clauses, the PowerSchool `tlist_sql` parser is a legacy tool. 
* **Parser Limitations:** Complex nested logic or `WITH` blocks often fail to render because the parser struggles to hand off the query to the database correctly.
* **The Fix:** We use **Self-Joins** or **Flattened Subqueries** (`IN` / `NOT IN`) to ensure compatibility with the legacy tag.

### 3. Logic: Inclusion vs. Exclusion
To handle inconsistent data entry across various school sites:
1. **Action Requirement:** The incident MUST have an action code of Suspension (100) or Expulsion (200). This filters out "Minor" incidents that resulted only in detention.
2. **Exclusion List:** Rather than listing every possible serious behavior, the query excludes "non-qualifying" behaviors (e.g., Tobacco, Defiance) to ensure the alert remains legally accurate.