// --- UNZIP FUNCTION (Returns folder IDs and confirms access) ---
function unzipAllZipFiles() {
  const processedFolderIds = []; 
  const ZIP_MIME_TYPE = "application/zip";

  try {
    // Note: The constant MAIN_FOLDER_ID is defined in Main_Workflow.gs but is visible here.
    const parentFolder = DriveApp.getFolderById(MAIN_FOLDER_ID);
    
    Logger.log('CONFIRMATION: Accessing main folder: ' + parentFolder.getName() + ' (ID: ' + MAIN_FOLDER_ID + ')');
    
    const zipFiles = parentFolder.getFiles(); 
    let processedCount = 0;

    while (zipFiles.hasNext()) {
      const zipFile = zipFiles.next();
      const fileName = zipFile.getName();

      if (fileName.toLowerCase().endsWith(".zip")) {
        try {
          Logger.log('Processing file: ' + fileName);

          const unzippedBlobs = Utilities.unzip(zipFile.getBlob());
          const newFolderName = fileName.replace(/\.zip$/i, "") + "_Unzipped";
          const newFolder = parentFolder.createFolder(newFolderName);
          
          processedFolderIds.push(newFolder.getId());
          Logger.log('UNZIP SUCCESS: Created new folder with ID: ' + newFolder.getId());

          unzippedBlobs.forEach((fileBlob) => {
            newFolder.createFile(fileBlob);
          });

          zipFile.setTrashed(true);
          processedCount++;

        } catch (e) {
          Logger.log('ERROR processing ZIP file ' + fileName + ': ' + e.toString());
        }
      }
    }
    
    Logger.log('Unzipping finished. ' + processedCount + ' ZIP files processed.');
    return processedFolderIds; 

  } catch (e) {
    Logger.log('CRITICAL ERROR during unzipping (Check MAIN_FOLDER_ID or permissions): ' + e.toString());
    return [];
  }
}

// --- CONVERSION FUNCTION (Converts text files to sheets using the caret delimiter) ---
function convertTextToSheets(folderIds) {
  // Note: The constants DELIMITER and TEXT_MIME_TYPE are defined in Main_Workflow.gs but are visible here.
  let convertedCount = 0;

  Logger.log('Starting text-to-sheets conversion on ' + folderIds.length + ' folders.');

  folderIds.forEach(folderId => {
    Logger.log('CONVERSION STARTING for FOLDER ID received: ' + folderId); 

    try {
      const currentFolder = DriveApp.getFolderById(folderId);
      const textFiles = currentFolder.getFilesByType(TEXT_MIME_TYPE);

      while (textFiles.hasNext()) {
        const txtFile = textFiles.next();
        const fileName = txtFile.getName();

        Logger.log('Attempting to read file: ' + fileName);

        let fileContent;
        
        // ISOLATED READ ATTEMPT
        try {
          fileContent = txtFile.getBlob().getDataAsString('UTF-8');
        } catch (readError) {
          Logger.log(`CRITICAL READ ERROR on file ${fileName}: Failed to read Blob to String.`);
          Logger.log(`Error Details: ${readError.toString()}`);
          continue; 
        }

        // --- Start Content Validation and Parsing ---
        
        if (!fileContent) {
            Logger.log(`CRITICAL FAILURE: fileContent variable is UNDEFINED after read attempt for ${fileName}. Skipping.`);
            continue;
        }

        // Universal Line Ending Fix
        fileContent = fileContent.replace(/\r\n|\r/g, '\n'); 

        // Check if content is empty
        if (fileContent.trim().length === 0) {
          Logger.log(`Skipping empty file: ${fileName}.`);
          txtFile.setTrashed(true);
          continue; 
        }

        // Parse the data
        const dataArray = fileContent.split('\n')
          .filter(row => row.trim().lenagth > 0) 
          .map(row => row.split(DELIMITER)); 

        // Final check to ensure the array has valid data
        if (dataArray.length === 0 || dataArray[0].length === 0) {
          Logger.log(`Skipping malformed/unparseable file: ${fileName}`);
          txtFile.setTrashed(true);
          continue; 
        }
        
        // Create and populate the Google Sheet
        const sheetName = fileName.replace(/\.txt$/i, "");
        const newSpreadsheet = SpreadsheetApp.create(sheetName);
        
        // Move the new Sheet to the current folder
        DriveApp.getFileById(newSpreadsheet.getId()).getParents().next().removeFile(DriveApp.getFileById(newSpreadsheet.getId()));
        currentFolder.addFile(DriveApp.getFileById(newSpreadsheet.getId()));

        const sheet = newSpreadsheet.getSheets()[0];
        
        const numRows = dataArray.length;
        const numCols = dataArray[0].length;
        
        sheet.getRange(1, 1, numRows, numCols).setValues(dataArray);

        Logger.log(`Successfully created and populated sheet: ${newSpreadsheet.getUrl()}`);
        
        txtFile.setTrashed(true);
        convertedCount++;
      }
    } catch (e) {
      Logger.log('FATAL ERROR during conversion in folder ID ' + folderId + ': ' + e.toString());
    }
  });

  Logger.log(`Conversion finished. ${convertedCount} files were converted.`);
}

// --- GLOBAL CONSTANTS ---
// The main folder where the ZIPs are uploaded
const MAIN_FOLDER_ID = "1lgMXqK8esVZAbWDKHXxhq0wOl1ars5Zc"; 

// The delimiter for your text files (Carat ^)
const DELIMITER = "^"; 
const TEXT_MIME_TYPE = MimeType.PLAIN_TEXT;


// --- MASTER WORKFLOW FUNCTION (Run this function) ---
function fullWorkflow() {
  Logger.log('--- Starting Full Workflow: Unzip and Convert ---');
  
  // Step 1: Run Unzip. It returns the IDs of the new subfolders.
  // NOTE: This calls the function defined in Unzip_Functions.gs
  const newFolderIds = unzipAllZipFiles();

  // Step 2: Pass the returned IDs to the Conversion function.
  // NOTE: This calls the function defined in Convert_Functions.gs
  if (newFolderIds.length > 0) {
    convertTextToSheets(newFolderIds);
  } else {
    Logger.log('No ZIP files were found or processed to convert.');
  }

  Logger.log('--- Full Workflow Complete ---');
}
