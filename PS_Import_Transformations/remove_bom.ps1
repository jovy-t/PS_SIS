$InputFile = "C:\Users\trejoj\Downloads\41688900000000\quoted.csv"
$OutputFile = "C:\Users\trejoj\Downloads\41688900000000\final.csv"

Write-Host "Reading: $InputFile"

# Read all bytes
$bytes = [System.IO.File]::ReadAllBytes($InputFile)

# Strip UTF-8 BOM if present
if ($bytes.Length -ge 3 -and 
    $bytes[0] -eq 0xEF -and 
    $bytes[1] -eq 0xBB -and 
    $bytes[2] -eq 0xBF) {

    Write-Host "Removing UTF-8 BOM..."
    $bytes = $bytes[3..($bytes.Length-1)]
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$text = $utf8.GetString($bytes)

$lines = $text -split "`r?`n"

$headers = @(
    "RecordType",
    "SSID",
    "CALPADSGrade",
    "CALPADSSchoolCode",
    "FinalTestCompletedDate",
    "LexileorQuantileMeasure",
    "ScaleScore",
    "SmarterScaleScoresErrorBandsMin",
    "SmarterScaleScoresErrorBandsMax",
    "AchievementLevels",
    "AccommodationsIndicator",
    "DesignatedSupportIndicator"
)

# Parse header from file
$sourceHeaders = $lines[0].Trim('"').Split(",")

# Create output builder
$out = New-Object System.Text.StringBuilder

# Write header (quoted)
$out.AppendLine(($headers | ForEach-Object { '"' + $_ + '"' }) -join ",")

# Process rows
for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if (-not $line.Trim()) { continue }

    # Split row
    $values = $line.Trim('"').Split(",")

    # Map to dictionary
    $rowMap = @{}
    for ($c = 0; $c -lt $sourceHeaders.Count; $c++) {
        $rowMap[$sourceHeaders[$c]] = $values[$c]
    }

    # Build cleaned row
    $row = $headers | ForEach-Object {
        '"' + $rowMap[$_] + '"'
    }

    $out.AppendLine($row -join ",")
}

# Write output file (UTF8 no BOM)
[System.IO.File]::WriteAllText($OutputFile, $out.ToString(), $utf8)

Write-Host "Done!"
Write-Host "Created: $OutputFile"
