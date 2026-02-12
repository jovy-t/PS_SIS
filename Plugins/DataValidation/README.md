# PowerSchool Exit Code Validation

This repository contains a jQuery customization for PowerSchool that ensures data integrity when students are transferred out. Specifically, it enforces the selection of a **School Completion Status** when a specific **Exit Code** is chosen.

---

## 📂 Deployment Details

* **File Path:** `/admin/students/`
* **Target Page:** This script is designed to run on the student transfer/edit pages (e.g., `edittransfer1.html`).
* **Injection Point:** For PowerSchool customizations, this code is typically placed within a **Page Customization** or a **Fragment Extension** (e.g., inside a `.footer.txt` or `.content.footer.txt` file).

---

## 🛠 Functionality

The script applies the following logic to the user interface:

1.  **Conditional Enabling:** The `School Completion Status` field is disabled by default and only becomes editable if the Exit Code is set to **E230**.
2.  **Visual Cues:** * If **E230** is selected and the status is empty, the field turns **light red**.
    * If the Exit Code is changed to something else, the field clears itself and turns **grey**.
3.  **Submission Guard:** If a user attempts to click "Submit" while the Exit Code is **E230** but the status is blank, the script triggers a browser alert and prevents the record from saving.

---

## ⚠️ Important Installation Note

To ensure the code displays with proper syntax highlighting on GitHub, the main script is saved as a `.js` file. However, **PowerSchool requires `<script>` tags** to execute JavaScript within its HTML templates.

> **Before pasting into PowerSchool:** Ensure you uncomment the `<script>` and `</script>` tags at the top and bottom of the file. If these tags are not active, the browser will treat the code as plain text and the validation will not run.

---

### How to use this in PowerSchool:
1.  Navigate to **Customization** > **Custom Page Management**.
2.  Locate or create the file: `admin/students/edittransfer1.custom_validation.content.footer.txt`.
3.  Copy the code from `transfer_validation.js` in this repository.
4.  Paste it into the PowerSchool editor.
5.  **Uncomment** the `<script>` tags.
6.  **Publish** the changes.