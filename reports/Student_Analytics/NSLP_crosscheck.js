// Cross referencing data from district's Point of Sale (POS) with CALPADS Direct Certification

function compareValues() {
  const start = new Date();
  console.log("=== START compareValues() ===");

  //
  // MAIN SPREADSHEET
  //
  const ss = SpreadsheetApp.getActive();
  const mainSheet = ss.getSheetByName("Sheet2");
  const mainValues = mainSheet.getRange("E2:E").getValues()
    .flat()
    .filter(x => x !== "" && x !== null)
    .map(String);

  const mainSet = new Set(mainValues);
  console.log(`Loaded ${mainSet.size} main IDs`);
  console.log(`Sample main IDs: ${JSON.stringify([...mainSet].slice(0, 10))}`);


  //
  // LOAD OR CREATE OUTPUT SHEETS
  //
  const matchedSheet = getOrCreateSheet(ss, "Matched");
  const unmatchedSheet = getOrCreateSheet(ss, "Unmatched");

  // Clear output
  matchedSheet.clearContents();
  unmatchedSheet.clearContents();

  // Write headers
  matchedSheet.getRange(1,1,1,3).setValues([["ID","SourceSheet","Row"]]);
  unmatchedSheet.getRange(1,1,1,5).setValues([["ID","SourceSheet","Row","ColH","ColL"]]);

  //
  // EXTERNAL SPREADSHEET
  //
  const externalID = "ID";
  const extSS = SpreadsheetApp.openById(externalID);

  const sheetNames = ["Sheet1","Sheet2","Sheet3","Sheet4","Sheet5","Sheet6","Sheet7"];

  let matched = [];
  let unmatched = [];

  sheetNames.forEach(name => {
    console.log(`\n--- Processing external sheet: ${name} ---`);

    const sh = extSS.getSheetByName(name);
    if (!sh) {
      console.log(`Sheet ${name} not found.`);
      return;
    }

    const maxRow = sh.getLastRow();
    const maxCol = sh.getLastColumn();

    if (maxRow < 6) {
      console.log(`Sheet ${name} empty or no data.`);
      return;
    }

    // Read entire sheet in one call
    const data = sh.getRange(1, 1, maxRow, maxCol).getValues();

    // Detect ID column
    const idCol = detectIDColumn(data, mainSet, name);
    if (!idCol) {
      console.log(`❌ No usable ID column found in ${name}`);
      return;
    }

    console.log(`Using ID column ${idCol} for ${name}`);

    //
    // Process rows starting at row 6
    //
    let rowCount = 0;

    for (let r = 6; r <= maxRow; r++) {
      const id = mergedAwareValue(data, r - 1, idCol - 1);

      if (!id || id === "") {
        console.log(`${name}: blank ID at row ${r}, stopping.`);
        break;
      }

      rowCount++;

      const idStr = String(id).trim();
      const colH = mergedAwareValue(data, r - 1, 7);  // H -> index 7
      const colL = mergedAwareValue(data, r - 1, 11); // L -> index 11

      if (mainSet.has(idStr)) {
        matched.push([idStr, name, r]);
      } else {
        unmatched.push([idStr, name, r, colH, colL]);
      }
    }

    console.log(`${name}: processed ${rowCount} rows.`);
  });

  //
  // OUTPUT RESULTS
  //
  console.log(`\nMatched count: ${matched.length}`);
  console.log(`Unmatched count: ${unmatched.length}`);

  if (matched.length > 0) {
    matchedSheet.getRange(2,1,matched.length,3).setValues(matched);
  } else {
    console.log("No matched records to write.");
  }

  if (unmatched.length > 0) {
    unmatchedSheet.getRange(2,1,unmatched.length,5).setValues(unmatched);
  } else {
    console.log("No unmatched records to write.");
  }

  console.log("=== END compareValues() ===");
}



// --------------------------------------------
// Helper: Create sheet if missing
// --------------------------------------------
function getOrCreateSheet(ss, name) {
  let sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
  }
  return sh;
}



// --------------------------------------------
// Helper: Detect best ID column by matching
// --------------------------------------------
function detectIDColumn(data, mainSet, sheetName) {
  let scores = [];

  const headerRow = data[5]; // row6 in sheet

  for (let col = 0; col < headerRow.length; col++) {
    let matches = 0;
    let nonEmpty = 0;

    for (let r = 6; r < data.length; r++) {
      const val = mergedAwareValue(data, r, col);
      if (val !== "" && val !== null) nonEmpty++;

      if (mainSet.has(String(val).trim())) matches++;
    }

    scores.push({colIndex: col+1, matches, nonEmpty});
  }

  scores.sort((a,b) => b.matches - a.matches);

  console.log(`Column detection stats (${sheetName}):`, JSON.stringify(scores.slice(0,5)));

  return scores[0].matches > 0 ? scores[0].colIndex : null;
}



// --------------------------------------------
// Helper: Return correct value even from merged cells
// --------------------------------------------
function mergedAwareValue(data, row, col) {
  let val = data[row][col];

  // If cell is empty but previous row has same merged region, use previous
  while ((val === "" || val === null) && row > 0) {
    row--;
    val = data[row][col];
  }

  return val;
}
