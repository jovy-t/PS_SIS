# Race & Ethnicity Logic

Describes how race and ethnicity are extracted from PowerSchool for reporting and compliance (e.g., CALPADS).

## Ethnicity

| Field         | Table     | Description                  |
|---------------|-----------|------------------------------|
| `fedethnicity`| `students`| Hispanic/Latino indicator    |

## Race (multiple possible values)

| Table         | Field     | Notes                            |
|---------------|-----------|----------------------------------|
| `studentrace` | `racecd`  | One record per race per student |

To flatten multiple races:
```sql
SELECT studentid,
       MAX(CASE WHEN rn = 1 THEN racecd END) AS race1,
       MAX(CASE WHEN rn = 2 THEN racecd END) AS race2,
       MAX(CASE WHEN rn = 3 THEN racecd END) AS race3
FROM (
  SELECT studentid, racecd,
         ROW_NUMBER() OVER (PARTITION BY studentid ORDER BY TO_NUMBER(racecd)) AS rn
  FROM studentrace
)
GROUP BY studentid;
