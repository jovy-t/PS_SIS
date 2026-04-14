# CCGI Integration

## Overview
An end-to-end ETL pipeline that extracts data from PowerSchool SIS through a custom PowerQuery API, transforms the dataset to align with CCGI specifications, and outputs a properly structured CSV.

## Proccess
### Extract
- Call PowerQuery API
- Retrieve Student Data
#### The shared helper module `ccgi_common.py`
Contains functions for:
- loading environment variables
- requesting OAuth access tokens
- calling PowerQueries
- handling pagination
- converting JSON records into row dictionaries
- writing CSV files


### Transform
- Map JSON keys to CCGI field names
- Add missing fields with blank values
- Apply formatting rules
### Load
- Write csv file to include all CCGI requirements

---

### `export_ccgi_student_file.py`
- authenticates to PowerSchool API
- calls the PowerQuery
- transforms data
- exports CSV

---

| Layer | Purpose |
|------|--------|
| PowerQuery | Data extraction |
| Python script | Transformation + export |
| Output folder | Final files |