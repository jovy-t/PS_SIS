-- Total students in each program by site

WITH ProgramNames AS (
    SELECT '101' AS PROGRAMCODE, '504 Accommodations' AS ProgramName FROM DUAL UNION ALL
    SELECT '135', 'Migrant' FROM DUAL UNION ALL
    SELECT '144', 'SPED' FROM DUAL UNION ALL
    SELECT '181', 'Free Lunch' FROM DUAL UNION ALL
    SELECT '182', 'Reduced Lunch' FROM DUAL UNION ALL
    SELECT '190', 'Foster Youth' FROM DUAL UNION ALL
    SELECT '191', 'Homeless' FROM DUAL UNION ALL
    SELECT '301', 'Dual Immersion' FROM DUAL UNION ALL
    SELECT '305', 'Structured English Immersion' FROM DUAL
)
SELECT
    sch.NAME AS School_Name,
    s.GRADE_LEVEL,
    pn.ProgramName,
    COUNT(s.ID) AS Total_Students
FROM
    STUDENTS s
INNER JOIN
    SCHOOLS sch ON s.SCHOOLID = sch.SCHOOL_NUMBER
INNER JOIN
    S_CA_STU_CALPADSPROGRAMS_C cal ON s.DCID = cal.STUDENTSDCID
INNER JOIN
    ProgramNames pn ON cal.PROGRAMCODE = pn.PROGRAMCODE
WHERE
    s.ENROLL_STATUS = 0
GROUP BY
    sch.NAME,
    s.GRADE_LEVEL,    pn.ProgramName
ORDER BY
    sch.NAME,
    s.GRADE_LEVEL,
    pn.ProgramName;
