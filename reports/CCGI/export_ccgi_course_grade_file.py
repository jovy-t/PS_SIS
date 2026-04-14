from ccgi_common import (
    BASE_DIR,
    build_rows,
    fetch_powerquery_records,
    get_access_token,
    get_env,
    write_csv,
)

CCGI_HEADERS = [
    "StateID",
    "CDSCode",
    "ATPCode",
    "CourseInstitutionName",
    "IsWorkInProgress",
    "GradeLevel",
    "SchoolYear",
    "TermDescription",
    "Term",
    "CourseCurriculumTerm",
    "LocalCourseID",
    "TranscriptAbbreviation",
    "SubjectArea",
    "AcademicIndicator",
    "DualEnrollmentIndicator",
    "CreditsAttempted",
    "CreditsEarned",
    "CourseGrade",
]

POWERQUERY_TO_CCGI_MAP = {
    "StateID": "stateid",
    "CDSCode": "cdscode",
    "ATPCode": "atpcode",
    "CourseInstitutionName": "courseinstitutionname",
    "IsWorkInProgress": "isworkinprogress",
    "GradeLevel": "gradelevel",
    "SchoolYear": "schoolyear",
    "TermDescription": "termdescription",
    "Term": "term",
    "CourseCurriculumTerm": "coursecurriculumterm",
    "LocalCourseID": "localcourseid",
    "TranscriptAbbreviation": "transcriptabbreviation",
    "SubjectArea": "subjectarea",
    "AcademicIndicator": "academicindicator",
    "DualEnrollmentIndicator": "dualenrollmentindicator",
    "CreditsAttempted": "creditsattempted",
    "CreditsEarned": "creditsearned",
    "CourseGrade": "coursegrade",
}

QUERY_NAME = get_env("CCGI_COURSE_GRADE_QUERY_NAME")
DISTRICT_NAME = "Cabrillo"


def main() -> None:
    print("CCGI course grade export starting...")

    access_token = get_access_token()
    print("Access token retrieved successfully.")

    records = fetch_powerquery_records(
        query_name=QUERY_NAME,
        access_token=access_token,
        payload={},
    )

    if not records:
        print("No records returned.")
        return

    ccgi_rows = build_rows(
        records=records,
        headers=CCGI_HEADERS,
        mapping=POWERQUERY_TO_CCGI_MAP,
    )

    print(f"Built {len(ccgi_rows)} CCGI course grade rows.")

    output_path = write_csv(
        rows=ccgi_rows,
        headers=CCGI_HEADERS,
        district_name=DISTRICT_NAME,
        template_name="CourseGradeTemplate",
        output_dir=BASE_DIR / "output",
    )

    print(f"Wrote file: {output_path}")


if __name__ == "__main__":
    main()