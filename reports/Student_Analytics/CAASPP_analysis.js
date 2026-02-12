/**
 * Analysis on CDE Data Quest Assessment files
 * 
 * Includes functions to compile data from multiple Google Sheets,
 * and generate two types of charts (Line Chart for Trends and Stacked Bar Chart for Subgroup Gaps).
 */

// --- CONFIGURATION FOR COLUMN MAPPING ---
// URL for the 2022-2023 file, which has a different column structure.
const OLD_DATA_URL_FRAGMENT = "ID"; // Unique part of the 22-23 URL

// Define column indices (0-based) for the different file structures.

// Configuration for 2023-24 and 2024-25 files (LATEST STRUCTURE)
const LATEST_INDICES = {
    TEST_YEAR: 7,
    STUDENT_GROUP_ID: 10,
    GRADE: 11,
    PCT_MET_ABOVE: 20,
    COUNT_MET_ABOVE: 21, // Count Standard Met and Above
    PCT_L4: 16, // Percentage Standard Exceeded
    PCT_L3: 18, // Percentage Standard Met
    PCT_L2: 22, // Percentage Standard Nearly Met
    PCT_L1: 24  // Percentage Standard Not Met
};

// Configuration for 2022-2023 file (OLD STRUCTURE)
const OLD_INDICES = {
    TEST_YEAR: 4,
    STUDENT_GROUP_ID: 5,
    GRADE: 9,
    PCT_MET_ABOVE: 16, // Percentage Standard Met and Above
    COUNT_MET_ABOVE: 8,  // Total Tested with Scores at Reporting Level
    PCT_L4: 14, // Percentage Standard Exceeded
    PCT_L3: 15, // Percentage Standard Met
    PCT_L2: 17, // Percentage Standard Nearly Met
    PCT_L1: 18  // Percentage Standard Not Met
};

// Key Student Group IDs for focused analysis
const KEY_GROUPS = {
    '1': 'All Students',
    '3': 'Male',
    '4': 'Female',
    '31': 'Socioeconomically disadvantaged',
    '111': 'Not socioeconomically disadvantaged',
    '78': 'Hispanic or Latino',
    '80': 'White'
};
// ----------------------------------------

// --- 1. DATA COMPILATION FUNCTION ---
function compileAllData() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const outputSheetName = "Compiled Data";
  
  // NOTE: The IDs below are extracted from the URLs provided by the user.
  const sourceSheetUrls = [
    "https://docs.google.com/spreadsheets/d/ID/edit#gid=0", // 24-25
    "https://docs.google.com/spreadsheets/d/ID/edit#gid=0", // 23-24
    "https://docs.google.com/spreadsheets/d/ID/edit#gid=0"  // 22-23 (Old structure)
  ];

  let compiledData = [];

  // Define the new header for the compiled sheet
  const header = [
    "Test Year", "Grade", "Student Group ID", "Student Group Name",
    "Pct Met and Above", "Count Met and Above",
    "Pct Exceeded (L4)", "Pct Met (L3)", "Pct Nearly Met (L2)", "Pct Not Met (L1)"
  ];
  compiledData.push(header);

  // 1. Loop through each source sheet URL
  sourceSheetUrls.forEach(url => {
    try {
      // Determine which column mapping to use based on the URL
      const indices = url.includes(OLD_DATA_URL_FRAGMENT) ? OLD_INDICES : LATEST_INDICES;
      
      const sourceSS = SpreadsheetApp.openByUrl(url);
      const sourceSheet = sourceSS.getSheets()[0]; // Assuming data is on the first sheet
      const range = sourceSheet.getDataRange();
      const values = range.getValues();
      
      // 2. Process data rows (skip header, which is Row 1 / index 0)
      for (let i = 1; i < values.length; i++) {
        const row = values[i];
        const studentGroupId = String(row[indices.STUDENT_GROUP_ID]);
        
        // Check if the group is one of our key groups and the score is not suppressed ('*')
        if (KEY_GROUPS[studentGroupId] && row[indices.PCT_MET_ABOVE] !== '*') {
          
          // Data extraction and compilation using the determined index map
          const dataRow = [
            row[indices.TEST_YEAR],
            row[indices.GRADE],
            studentGroupId,
            KEY_GROUPS[studentGroupId],
            
            // Core Achievement Metrics (ensure numeric)
            Number(row[indices.PCT_MET_ABOVE]),
            Number(row[indices.COUNT_MET_ABOVE]),
            
            // Achievement Level Breakdown (ensure numeric)
            Number(row[indices.PCT_L4]),
            Number(row[indices.PCT_L3]),
            Number(row[indices.PCT_L2]),
            Number(row[indices.PCT_L1])
          ];
          compiledData.push(dataRow);
        }
      }
    } catch (e) {
      Logger.log(`Could not open or process URL ${url}: ${e}`);
      Browser.msgBox(`Error processing sheet for URL ${url}. Ensure the file is a Google Sheet and public: ` + e.toString());
    }
  });

  // 3. Write data to the new sheet
  let outputSheet = ss.getSheetByName(outputSheetName);
  if (!outputSheet) {
    outputSheet = ss.insertSheet(outputSheetName);
  }
  
  // Clear existing content and write the new data
  outputSheet.clearContents();
  outputSheet.getRange(1, 1, compiledData.length, compiledData[0].length).setValues(compiledData);
  outputSheet.setColumnWidth(4, 250);
  
  Logger.log(`Data compilation complete! ${compiledData.length - 1} data points compiled into the sheet: "${outputSheetName}".`);
}
