# 🔔 D63 Start Page Alerts - EL & EO Customization

This folder contains custom modifications for the **D63 Start Page Alerts** plugin. These enhancements are designed to improve data validation for California state reporting requirements regarding Language Instruction Programs (LIP).

---

## 📊 Data Validation Alerts

### 1. [Language Instruction Program (EL)](./LanguageInstructionProgram)
**Target:** English Learners (EL) participating in a Dual Immersion Program.  
**Purpose:** Identifies EL students who are missing a required LIP record to ensure CALPADS compliance.

#### Modification Index
1. **[EL_No_LIP.sql](./LanguageInstructionProgram/EL_No_LIP.sql)** * **Location:** `web_root/wildcards/d63_spa/el_no_lip.txt`  
   * **Action:** Create this file from scratch to house the core database logic.
2. **[StartPage_Alerts.txt](./LanguageInstructionProgram/StartPage_Alerts.txt)** * **Location:** `web_root/wildcards/d63_start_page_alerts.txt`  
   * **Action:** Insert into the **HTML section** of the main Start Page alert box.
3. **[StartPage_Alerts.js](./LanguageInstructionProgram/StartPage_Alerts.js)** * **Location:** `web_root/wildcards/d63_start_page_alerts.txt`  
   * **Action:** Insert into the `<script>` section at the bottom of the file to manage student counts and UI toggles.
4. **[StartPage_Alerts_Pref.html](./LanguageInstructionProgram/StartPage_Alerts_Pref.html)** * **Location:** `web_root/admin/district/d63_spa_pref.html`  
   * **Action:** Add the **Javascript Initialization** and the **Settings Table** to the District Setup page.

---

### 2. [EO Students in Dual Immersion](./EO_Stu_DIM_LIP)
**Target:** English Only (EO) students participating in a Dual Immersion Program.  
**Purpose:** In California, *all* students in Dual Immersion—including English Only students—must have a valid LIP record. This alert flags missing records for EO students.

#### Modification Index
1. **[eo_stu_dim.sql](./EO_Stu_DIM_LIP/eo_stu_dim.sql)** * **Location:** `web_root/wildcards/d63_spa/eo_stu_dim.txt`  
   * **Action:** Create this file from scratch to house the core database logic.
2. **[StartPage_Alerts.txt](./EO_Stu_DIM_LIP/StartPage_Alerts.txt)** * **Location:** `web_root/wildcards/d63_start_page_alerts.txt`  
   * **Action:** Insert into the **HTML section** of the main alert box.
3. **[StartPage_Alerts.js](./EO_Stu_DIM_LIP/StartPage_Alerts.js)** * **Location:** `web_root/wildcards/d63_start_page_alerts.txt`  
   * **Action:** Insert into the `<script>` section to manage visibility and data counts.
4. **[StartPage_Alerts_Pref.html](./EO_Stu_DIM_LIP/StartPage_Alerts_Pref.html)** * **Location:** `web_root/admin/district/d63_spa_pref.html`  
   * **Action:** Add initialization and settings table to the District Setup page.

---

## ⚠️ Important Maintenance Note
If the **D63 Start Page Alerts** plugin is updated by the developer, the custom code blocks listed above will be overwritten. You must **manually re-insert** these snippets into the updated files to restore the custom EL and EO alert functionality.