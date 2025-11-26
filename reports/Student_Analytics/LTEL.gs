/**
 * Reads data from the source sheet, groups records by School of Attendance (E)
 * and Grade Level Code (X), and counts the total records that fall into 
 * specific date ranges in Provisional LTEL Start Date (AS).
 *
 * It creates a new sheet named "Count_Report" with the results.
 */
function transformAndCountData() {
  // --- CONFIGURATION START ---

  // The ID of the spreadsheet (taken from your URL: https://docs.google.com/spreadsheets/d/1V302uPCFzCO52jFqT5P_2WGG8Bt-4H-rPwfcuxsxMDw/edit)
  const SPREADSHEET_ID = '1V302uPCFzCO52jFqT5P_2WGG8Bt-4H-rPwfcuxsxMDw';

  // The name of the source sheet (assuming the sheet with gid=281890882 is the source)
  // You might need to change this if the name is different (e.g., 'Sheet1', 'Data').
  const SOURCE_SHEET_NAME = '25-26_CENR_2025102315_18660324142'; 

  // Column Indices (A=0, B=1, ...):
  const COL_SCHOOL_E = 4;   // Column E (School of Attendance)
  const COL_GRADE_X  = 23;  // Column X (Grade Level Code)
  const COL_DATE_AS  = 44;  // Column AS (Provisional LTEL Start Date)

  // Define the date ranges in YYYYMMDD format (as strings for easy comparison)
  const DATE_RANGES = [
    { name: '2022/08/10 - 2023/06/10', start: '20220810', end: '20230610' },
    { name: '2023/08/10 - 2024/06/10', start: '20230810', end: '20240610' },
    { name: '2024/08/10 - 2025/06/10', start: '20240810', end: '20250610' },
    { name: '2025/08/10 - 2026/06/10', start: '20250810', end: '20260610' }
  ];

  // --- CONFIGURATION END ---
  
  const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  const sourceSheet = ss.getSheetByName(SOURCE_SHEET_NAME);
  
  if (!sourceSheet) {
    throw new Error(`Could not find a sheet named: ${SOURCE_SHEET_NAME}. Please update the SOURCE_SHEET_NAME variable.`);
  }

  // Get all data from the source sheet (excluding the header row)
  const range = sourceSheet.getDataRange();
  const values = range.getValues();
  
  // The structure to store the counts: 
  // Map<SchoolKey, Map<GradeKey, [Count1, Count2, Count3, Count4]>>
  const counts = new Map();

  // The date values are in YYYYMMDD format (number or text). 
  // We convert them to a string for robust lexicographical (chronological) comparison.
  
  // Start from the second row (index 1) to skip headers
  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    
    // Convert values to strings for consistent key and comparison logic
    const schoolId = String(row[COL_SCHOOL_E]).trim();
    const gradeCode = String(row[COL_GRADE_X]).trim();
    let dateValue = String(row[COL_DATE_AS]).trim();

    // Remove non-numeric characters and ensure exactly 8 digits for date comparison
    dateValue = dateValue.replace(/\D/g, ''); 

    // Ignore records where Grade Level or Date is blank or invalid
    if (gradeCode === '' || dateValue.length !== 8) {
      continue;
    }
    
    // --- Aggregation Logic ---
    
    // Create a key for the school (E)
    if (!counts.has(schoolId)) {
      counts.set(schoolId, new Map());
    }
    
    const schoolMap = counts.get(schoolId);
    
    // Create a key for the grade (X) within the school
    if (!schoolMap.has(gradeCode)) {
      // Initialize the count array for this specific School/Grade combination
      // [0, 0, 0, 0] for the four date ranges
      schoolMap.set(gradeCode, new Array(DATE_RANGES.length).fill(0));
    }
    
    const countArray = schoolMap.get(gradeCode);
    
    // Check against each date range and increment the count
    for (let j = 0; j < DATE_RANGES.length; j++) {
      const range = DATE_RANGES[j];
      
      // Since the format is YYYYMMDD, a simple string comparison works for chronological order.
      if (dateValue >= range.start && dateValue <= range.end) {
        countArray[j]++;
      }
    }
  }

  // --- Output Formatting ---
  
  // Prepare the header row
  const header = ['School of Attendance (E)', 'Grade Level (X)'];
  DATE_RANGES.forEach(range => header.push(range.name));
  
  const reportData = [header];

  // Convert the map structure into a 2D array for writing to the sheet
  for (const [schoolId, schoolMap] of counts) {
    for (const [gradeCode, countArray] of schoolMap) {
      const row = [schoolId, gradeCode, ...countArray];
      reportData.push(row);
    }
  }

  // --- Write to Target Sheet ---
  
  let targetSheet = ss.getSheetByName('Count_Report');
  if (targetSheet) {
    targetSheet.clear(); // Clear old data if sheet exists
  } else {
    targetSheet = ss.insertSheet('Count_Report'); // Create new sheet
  }
  
  if (reportData.length > 1) {
    targetSheet.getRange(1, 1, reportData.length, reportData[0].length).setValues(reportData);
    
    // Set column widths and make the header bold
    targetSheet.autoResizeColumns(1, reportData[0].length);
    targetSheet.getRange(1, 1, 1, reportData[0].length).setFontWeight('bold');
  }
  
  SpreadsheetApp.getUi().alert('Data transformation complete! Results are in the "Count_Report" sheet.');
}
