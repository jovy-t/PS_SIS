from pathlib import Path

from ccgi_common import (
    BASE_DIR,
    build_rows,
    fetch_powerquery_records,
    get_access_token,
    get_env,
    write_csv,
)

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

QUERY_NAME = get_env("CCGI_STUDENT_QUERY_NAME")
GPA_TYPE = "Weighted"
DISTRICT_NAME = "Cabrillo"

def main() -> None:
    print("CCGI student export starting...")

    access_token = get_access_token()
    print("Access token retrieved successfully.")

    payload = {
        "gpa_type": GPA_TYPE,
    }

    records = fetch_powerquery_records(
        query_name=QUERY_NAME,
        access_token=access_token,
        payload=payload,
    )

    if not records:
        print("No records returned.")
        return

    ccgi_rows = build_rows(
        records=records,
        headers=CCGI_HEADERS,
        mapping=POWERQUERY_TO_CCGI_MAP,
    )

    print(f"Built {len(ccgi_rows)} CCGI student rows.")

    output_path = write_csv(
        rows=ccgi_rows,
        headers=CCGI_HEADERS,
        district_name=DISTRICT_NAME,
        template_name="StudentTemplate",
        output_dir=BASE_DIR / "output",
    )

    print(f"Wrote file: {output_path}")


if __name__ == "__main__":
    main()