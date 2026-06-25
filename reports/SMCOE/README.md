# SMCOE Reports

This folder contains reports required by the San Mateo County Office of Education (SMCOE) for compliance auditing and program tracking.

## Dynamic Execution Note

Two queries in this directory have been refactored for **Oracle APEX**. They utilize dynamic bind variables (`:P1_YEAR`) to eliminate hardcoded values, allowing them to be run seamlessly every summer without modifying the underlying SQL script.

---

## Reports

### `big_lift.sql`
Generates a high-performance, deduplicated roster of TK–3 students for Big Lift program tracking. 

* **Cohort Scope:** Targets active and disenrolled students within a dynamically specified school year.
    * Example: For the 2025-2026 academic year, `:P1_YEAR = 2026`
* **Data Included:** Comprehensive demographics, multi-path teacher assignment fallback logic, English Learner (EL) milestones, and latest-record chronological isolation for critical programs (SPED, 504, Foster Youth, and National School Lunch Program eligibility).

### `big_lift_contacts.sql`
Serves as the parent/guardian contact companion query for the primary Big Lift student roster.

* **Cohort Scope:** Dynamically extracts family and contact profiles for the exact same TK–3 student base based on the student's exit calendar year.
* **Data Included:** Pivots normalized relational data to isolate the top two primary contacts per student. Captures parent legal names, explicit relationship types, parent educational attainment tiers, corresponding languages, verified phone numbers, and structured residential addresses.

### `brigance.sql`
* Pulls Pre-K and TK student contact and demographic info needed for Brigance Assessment coordination.
