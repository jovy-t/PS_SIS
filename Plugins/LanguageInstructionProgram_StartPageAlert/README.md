# D63 Start Page Alerts - EL Customization
This folder contains the custom modifications added to the **D63 Start Page Alerts** plugin to identify students with EL Status but no active LIP record.

### Modification Index
1.  **[EL_No_LIP.sql](./EL_No_LIP.sql)**: The core database logic. 
* **Location:** `web_root/wildcards/d63_spa/el_no_lip.txt`
* **Action:** Create this file from scratch.
2.  **[StartPage_Alerts.txt](./StartPage_Alerts.txt)**: Instructions for the main Start Page alert box and student list.
* **Location:** `web_root/wildcards/d63_start_page_alerts.txt`
* **Action:** Paste into the HTML section
3.  **[StartPage_Alerts.js](./StartPage_Alerts.js)**: The JavaScript that counts the students and toggles visibility.
* **Location:** `web_root/wildcards/d63_start_page_alerts.txt`
* **Action:** Paste into the `<script>` section at the bottom
4.  **[StartPage_Alerts_Pref..html](./StartPage_Alerts_Pref.html)**: The HTML and JavaScript initialization for the District Setup page.
* **Location:** `web_root/admin/district/d63_spa_pref.html`
* **Action:** Add the Javascript Initialization and the Settings Table.

**Note:** If the D63 plugin is updated, these code blocks must be re-inserted into the updated files to restore the EL alert functionality.