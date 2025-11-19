WITH testtype AS (
    -- Finds the descriptive name for each test score ID
    SELECT 
        t.TESTSCOREID,
        MIN(ts.NAME) AS NAME
    FROM STUDENTTESTSCORE t
    JOIN TESTSCORE ts
        ON ts.ID = t.TESTSCOREID
    GROUP BY t.TESTSCOREID
),

testdate AS (
    -- Finds the earliest test date and associated grade/school for each student
    SELECT
        t.STUDENTID,
        st.GRADE_LEVEL,
        st.SCHOOLID,
        MIN(st.TEST_DATE) AS TESTDATE
    FROM STUDENTTESTSCORE t
    JOIN STUDENTTEST st
        ON st.ID = t.STUDENTTESTID
    GROUP BY t.STUDENTID, st.GRADE_LEVEL, st.SCHOOLID
),

schoolid AS (
    -- Filters to only the single, primary enrollment record (rn = 1) for de-duplication
    SELECT
        *
    FROM (
        SELECT
            r.STUDENTID,
            r.SCHOOLID,
            d.GRADE_LEVEL,
            ROW_NUMBER() OVER (
                PARTITION BY r.STUDENTID, d.GRADE_LEVEL
                ORDER BY r.ENTRYDATE ASC 
            ) AS rn 
        FROM STUDENTTESTSCORE t
        JOIN REENROLLMENTS r
            ON r.STUDENTID = t.STUDENTID 
        JOIN TESTDATE d
            ON d.GRADE_LEVEL = r.GRADE_LEVEL 
        WHERE 
            r.ENTRYDATE BETWEEN TO_DATE('10-AUG-2024', 'DD-MON-YYYY')
                           AND TO_DATE('06-JUN-2025', 'DD-MON-YYYY')
    )
    WHERE rn = 1
),

Enrollment_Base AS (
    -- Calculates the total unduplicated enrollment count
    SELECT
        r.SCHOOLID,
        r.GRADE_LEVEL,
        COUNT(DISTINCT r.STUDENTID) AS Total_Enrolled_Students
    FROM 
        REENROLLMENTS r
    WHERE
        -- Filter REENROLLMENTS to the target academic year
        r.ENTRYDATE BETWEEN TO_DATE('10-AUG-2024', 'DD-MON-YYYY')
                       AND TO_DATE('06-JUN-2025', 'DD-MON-YYYY')
    GROUP BY
        r.SCHOOLID,
        r.GRADE_LEVEL
)

SELECT 
    sch.SCHOOLID,
    d.GRADE_LEVEL,
    tt.NAME AS Test_Type,
    ROUND(AVG(t.NUMSCORE), 2) AS Average_Numeric_Score, 
    COUNT(t.STUDENTTESTID) AS Participating_Students,
    eb.Total_Enrolled_Students,
    -- Calculate Percentage: (Participating Students / Total Enrolled) * 100
    ROUND(
        (CAST(COUNT(t.STUDENTTESTID) AS DECIMAL(10, 2)) / eb.Total_Enrolled_Students) * 100
    , 2) AS Percentage_Participation
FROM 
    STUDENTTESTSCORE t
LEFT JOIN 
    STUDENTS s
    ON s.ID = t.STUDENTID
LEFT JOIN 
    TESTDATE d
    ON d.STUDENTID = t.STUDENTID
LEFT JOIN
    TESTTYPE tt
    ON tt.TESTSCOREID = t.TESTSCOREID
LEFT JOIN 
    SCHOOLID sch 
    ON sch.STUDENTID = t.STUDENTID 
    AND sch.GRADE_LEVEL = d.GRADE_LEVEL 
LEFT JOIN
    Enrollment_Base eb
    ON eb.SCHOOLID = sch.SCHOOLID 
    AND eb.GRADE_LEVEL = d.GRADE_LEVEL
    
WHERE 
    t.TESTSCOREID IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
    AND s.ENROLL_STATUS = 0
    AND d.TESTDATE BETWEEN TO_DATE('10-AUG-2024', 'DD-MON-YYYY')
                   AND TO_DATE('06-JUN-2025', 'DD-MON-YYYY')
                   
GROUP BY 
    sch.SCHOOLID,
    d.GRADE_LEVEL,
    tt.NAME,
    eb.Total_Enrolled_Students
ORDER BY 
    sch.SCHOOLID,
    d.GRADE_LEVEL,
    tt.NAME;
