# California Seal of Biliteracy Tracker

## Overview

This query is designed to help high schools track active 12th grade students' progress toward the **California State Seal of Biliteracy**.

It combines:

- student enrollment and ELA status
- English coursework and GPA
- world language coursework and GPA
- AP exam results from legacy testing tables
- SBAC ELA and ELPAC results from California state assessment extension tables

The output is intended to help school staff identify:

- students who already qualify through the currently mapped pathways
- students who are missing one or more requirements
- students whose world language coursework appears complete but still need proficiency review

---

## What the Query Does

The query evaluates three major areas:

### 1. English Requirement

A student is treated as meeting the English requirement if they satisfy **one** of the following mapped paths:

- English coursework GPA meets the local threshold used in the query
- SBAC / CAASPP ELA Achievement Level is 3 or higher
- AP English score is 3 or higher

**English coursework is based on the approved English graduation course list from the CUSD Grad requirement setup.**  
This ensures that only courses officially recognized by the district for English graduation credit are included in the GPA and credit calculations.

---

### 2. Additional Requirement for English Learners

If a student is currently marked as `EL`, the query also checks whether the student has:

- ELPAC Oral Language Proficiency Level (PL) of 4 or higher

If the student is not `EL`, this step is marked as not required.

---

### 3. World Language Requirement

The query currently recognizes these mapped paths:

- AP French score of 3 or higher
- AP Spanish score of 3 or higher

The query also identifies students who appear to meet the **world language coursework** pathway based on years completed and GPA.

**Important:**

World language coursework identifies coursework progress, but California's coursework path also requires oral proficiency or another qualifying language assessment. That extra requirement is **not fully mapped yet**, so coursework alone does not automatically mark the student as fully qualified in the final result.

Because of this, students who meet coursework criteria without a mapped proficiency assessment are flagged for review.

---

## Data Sources Used

### Student and status data
- `STUDENTS`
- `S_CA_STU_X`

### Coursework and GPA
- `STOREDGRADES`
- `COURSES`
- `GRADREQ`
- `GRADREQSETS`

### Legacy AP exam data
- `STUDENTTESTSCORE`
- `TESTSCORE`

### California state assessment data
- `S_CA_STU_TEST_S`
- `S_CA_STU_TESTSCORE_C`
- `S_CA_TEST_S`
- `S_CA_TESTSCORE_C`

---

## GPA Calculation Used

For both **English GPA** and **World Language GPA**, the query uses a **credit-weighted GPA** based on values already stored in PowerSchool.

```text
GPA = SUM((GPA_POINTS + GPA_ADDEDVALUE) × EARNEDCRHRS)
      ÷
      SUM(EARNEDCRHRS)