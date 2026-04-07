import os
from dotenv import load_dotenv
import csv
from datetime import date
from pathlib import Path
import requests

CCGI_HEADERS = [
    "PrimaryCDSCode",
    "LocalStudentID",
    "StateID",
    "FirstName",
    "PreferredFirstName",
    "MiddleName",
    "PreferredMiddleName",
    "LastName",
    "PreferredLastName",
    "Suffix",
    "DateOfBirth",
    "Gender",
    "GradeLevel",
    "GPA",
    "GPAType",
    "CalGrantGPA",
    "NSLP",
    "LOTECert",
    "LOTECertSource",
    "LanguageCode",
    "FosterYouth",
    "ParentConsent",
    "HispanicEthnicity",
    "RaceCode1",
    "RaceCode2",
    "RaceCode3",
    "RaceCode4",
    "RaceCode5",
    "EnrollmentStartDate",
    "EnrollmentEndDate",
    "DistrictAssignedStudentEmailAddress",
    "SWDIndicator",
    "504ProgramIndicator",
    "EL",
    "AB469OptOut",
    "Homeless",
    "Migrant",
    "ParentGuardianEdLevel",
]

POWERQUERY_TO_CCGI_MAP = {
    "PrimaryCDSCode": "primarycdscode",
    "LocalStudentID": "localstudentid",
    "StateID": "stateid",
    "FirstName": "firstname",
    "PreferredFirstName": "preferredfirstname",
    "MiddleName": "middlename",
    "PreferredMiddleName": "preferredmiddlename",
    "LastName": "lastname",
    "PreferredLastName": "preferredlastname",
    "Suffix": "suffix",
    "DateOfBirth": "dateofbirth",
    "Gender": "gender",
    "GradeLevel": "gradelevel",
    "GPA": "gpa",
    "GPAType": "gpatype",
    "CalGrantGPA": "calgrantgpa",
    "NSLP": "nslp",
    "LOTECert": "lotecert",
    "LOTECertSource": "lotecertsource",
    "LanguageCode": "languagecode",
    "FosterYouth": "fosteryouth",
    "ParentConsent": "parentconsent",
    "HispanicEthnicity": "hispanicethnicity",
    "RaceCode1": "racecode1",
    "RaceCode2": "racecode2",
    "RaceCode3": "racecode3",
    "RaceCode4": "racecode4",
    "RaceCode5": "racecode5",
    "EnrollmentStartDate": "enrollmentstartdate",
    "EnrollmentEndDate": "enrollmentenddate",
    "DistrictAssignedStudentEmailAddress": "districtassignedstudentemailaddress",
    "SWDIndicator": "swdindicator",
    "504ProgramIndicator": "504programindicator",
    "EL": "el",
    "AB469OptOut": "ab469optout",
    "Homeless": "homeless",
    "Migrant": "migrant",
    "ParentGuardianEdLevel": "parentguardianedlevel",
}

BASE_DIR = Path(__file__).parent
load_dotenv(BASE_DIR / ".env")

# Fill these in locally
POWERSCHOOL_BASE_URL = os.getenv("POWERSCHOOL_BASE_URL")
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")
QUERY_NAME = os.getenv("QUERY_NAME")

DISTRICT_CDS = os.getenv("DISTRICT_CDS")
GPA_TYPE = "Weighted"


def build_ccgi_row(powerquery_record: dict) -> dict:
    row = {}

    for header in CCGI_HEADERS:
        source_key = POWERQUERY_TO_CCGI_MAP[header]
        value = powerquery_record.get(source_key, "")
        if value is None:
            value = ""
        row[header] = value

    return row


def write_ccgi_csv(rows: list[dict], district_name: str, output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)

    file_date = date.today().strftime("%Y%m%d")
    filename = f"{district_name}_StudentTemplate_{file_date}.csv"
    output_path = output_dir / filename

    with output_path.open("w", encoding="utf-8", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=CCGI_HEADERS)
        writer.writeheader()
        writer.writerows(rows)

    return output_path


def get_access_token() -> str:
    token_url = f"{POWERSCHOOL_BASE_URL}/oauth/access_token/"

    response = requests.post(
        token_url,
        auth=(CLIENT_ID, CLIENT_SECRET),
        headers={
            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        },
        data={
            "grant_type": "client_credentials",
        },
        timeout=60,
    )

    print("Token status:", response.status_code)
    response.raise_for_status()

    token_data = response.json()
    return token_data["access_token"]


def fetch_powerquery_records(access_token: str) -> list[dict]:
    query_url = f"{POWERSCHOOL_BASE_URL}/ws/schema/query/{QUERY_NAME}"

    response = requests.post(
        query_url,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
        json={
            "district_cds": DISTRICT_CDS,
            "gpa_type": GPA_TYPE,
        },
        timeout=120,
    )

    print("PowerQuery status:", response.status_code)
    response.raise_for_status()

    data = response.json()
    print("Top-level keys:", list(data.keys()))

    records = data.get("record", [])
    print(f"Fetched {len(records)} records")

    return records


def main() -> None:
    print("CCGI export script starting...")

    access_token = get_access_token()
    print("Access token retrieved successfully.")

    records = fetch_powerquery_records(access_token)

    if not records:
        print("No records returned.")
        return

    ccgi_rows = [build_ccgi_row(record) for record in records]

    print(f"Built {len(ccgi_rows)} CCGI rows.")

    output_path = write_ccgi_csv(
        rows=ccgi_rows,
        district_name="Cabrillo",
        output_dir=BASE_DIR / "output",
    )

    print(f"Wrote file: {output_path}")


if __name__ == "__main__":
    main()