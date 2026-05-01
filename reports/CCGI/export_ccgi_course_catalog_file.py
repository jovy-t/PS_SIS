from ccgi_common import (
    BASE_DIR,
    fetch_powerquery_records,
    get_access_token,
    get_env,
    write_csv,
)

CCGI_HEADERS = [
    "CDSCode",
    "GraduationRequirements",
    "Subject",
    "CourseTitle",
    "Description",
    "CourseNumber",
    "CourseDuration",
    "Academic",
    "Credits",
    "Honors",
    "Offered",
    "SchoolType",
    "Year",
    "StateCourseCode",
]

POWERQUERY_TO_CCGI_MAP = {
    "CDSCode": "cdscode",
    "GraduationRequirements": "graduationrequirements",
    "Subject": "subject",
    "CourseTitle": "coursetitle",
    "Description": "description",
    "CourseNumber": "coursenumber",
    "CourseDuration": "courseduration",
    "Academic": "academic",
    "Credits": "credits",
    "Honors": "honors",
    "Offered": "offered",
    "SchoolType": "schooltype",
    "Year": "year",
    "StateCourseCode": "statecoursecode",
}

QUERY_NAME = get_env("CCGI_COURSE_CATALOG_QUERY_NAME")
DISTRICT_NAME = "Cabrillo"
TEMPLATE_NAME = "Course Catalog_Template"


def build_course_catalog_rows(records: list[dict]) -> list[dict]:
    rows: list[dict] = []

    for record in records:
        row: dict[str, str] = {}
        for header in CCGI_HEADERS:
            source_key = POWERQUERY_TO_CCGI_MAP[header]
            value = record.get(source_key, "")
            if value is None:
                value = ""
            row[header] = str(value).strip() if value != "" else ""
        rows.append(row)

    return rows


def main() -> None:
    print("CCGI course catalog export starting...")

    access_token = get_access_token()
    print("Access token retrieved successfully.")

    records = fetch_powerquery_records(
        query_name=QUERY_NAME,
        access_token=access_token,
        payload={"school_year_start": 2025},
    )

    if not records:
        print("No records returned.")
        return

    ccgi_rows = build_course_catalog_rows(records)
    print(f"Built {len(ccgi_rows)} CCGI course catalog rows.")

    output_path = write_csv(
        rows=ccgi_rows,
        headers=CCGI_HEADERS,
        district_name=DISTRICT_NAME,
        template_name=TEMPLATE_NAME,
        output_dir=BASE_DIR / "output",
    )

    print(f"Wrote file: {output_path}")


if __name__ == "__main__":
    main()
