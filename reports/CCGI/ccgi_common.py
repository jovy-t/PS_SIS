import os
import csv
from datetime import date
from pathlib import Path
from typing import Optional

import requests
from dotenv import load_dotenv

BASE_DIR = Path(__file__).parent
load_dotenv(BASE_DIR / ".env")


def get_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"Missing required environment variable: {name}")
    return value


def get_access_token() -> str:
    base_url = get_env("POWERSCHOOL_BASE_URL")
    client_id = get_env("CLIENT_ID")
    client_secret = get_env("CLIENT_SECRET")

    token_url = f"{base_url}/oauth/access_token/"

    response = requests.post(
        token_url,
        auth=(client_id, client_secret),
        headers={
            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        },
        data={"grant_type": "client_credentials"},
        timeout=60,
    )
    response.raise_for_status()
    return response.json()["access_token"]


def fetch_powerquery_records(
    query_name: str,
    access_token: str,
    payload: Optional[dict] = None,
    timeout: int = 120,
    pagesize: int = 1000,
) -> list[dict]:
    base_url = get_env("POWERSCHOOL_BASE_URL")
    all_records: list[dict] = []
    page = 1

    while True:
        query_url = (
            f"{base_url}/ws/schema/query/{query_name}"
            f"?pagesize={pagesize}&page={page}"
        )

        print(f"Calling PowerQuery URL: {query_url}")
        print("Payload:", payload or {})

        response = requests.post(
            query_url,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
            json=payload or {},
            timeout=timeout,
        )

        print("PowerQuery status:", response.status_code)
        print("PowerQuery response text:", response.text[:1000])

        response.raise_for_status()

        data = response.json()
        records = data.get("record", [])

        print(f"Page {page}: fetched {len(records)} records")

        if not records:
            break

        all_records.extend(records)

        if len(records) < pagesize:
            break

        page += 1

    print(f"Total fetched records: {len(all_records)}")
    return all_records


def build_rows(records: list[dict], headers: list[str], mapping: dict[str, str]) -> list[dict]:
    rows: list[dict] = []

    for record in records:
        row: dict[str, str] = {}
        for header in headers:
            value = record.get(mapping[header], "")
            if value is None:
                value = ""
            row[header] = str(value).strip() if value != "" else ""
        rows.append(row)

    return rows


def write_csv(rows: list[dict], headers: list[str], district_name: str, template_name: str, output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)

    file_date = date.today().strftime("%Y%m%d")
    filename = f"{district_name}_{template_name}_{file_date}.csv"
    output_path = output_dir / filename

    with output_path.open("w", encoding="utf-8", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)

    return output_path