-- Physical Fitness Test Results for each site
WITH testtype AS (
    SELECT 
        t.TESTSCOREID,
        MIN(ts.NAME) as NAME
    FROM STUDENTTESTSCORE t
    JOIN TESTSCORE ts
        ON ts.ID = t.TESTSCOREID
    GROUP BY t.TESTSCOREID
),

testdate AS (
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
    SELECT *
    FROM (
        SELECT
            r.STUDENTID,
            r.SCHOOLID,
            d.GRADE_LEVEL,
            -- Use a window function to pick only one school per student/grade combination
            -- This is the robust fix for duplication. Ordering by START_DATE ensures
            -- you pick the *first* enrollment for that period, if needed.
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
)

SELECT 
    t.DCID,
    t.STUDENTID,
    s.STUDENT_NUMBER,
    d.GRADE_LEVEL,
    sch.SCHOOLID,
    tt.NAME AS TEST_TYPE,
    d.TESTDATE,
    t.STUDENTTESTID,
    t.NUMSCORE,
    t.PERCENTSCORE,
    t.ALPHASCORE,
    t.NOTES  
    
FROM STUDENTTESTSCORE t
LEFT JOIN STUDENTS s
    ON s.ID = t.STUDENTID
LEFT JOIN TESTTYPE tt
    ON tt.TESTSCOREID = t.TESTSCOREID
LEFT JOIN TESTDATE d
    ON d.STUDENTID = t.STUDENTID
LEFT JOIN SCHOOLID sch
    ON sch.STUDENTID = t.STUDENTID
    
WHERE t.TESTSCOREID IN (1,2,3,4,5,6,7,8,9,10,11)
    AND s.ENROLL_STATUS = 0
    AND s.GRADE_LEVEL IN (6,8,10)
    AND d.TESTDATE BETWEEN TO_DATE('10-AUG-2024', 'DD-MON-YYYY')
                   AND TO_DATE('06-JUN-2025', 'DD-MON-YYYY')
    
ORDER BY s.SCHOOLID, s.GRADE_LEVEL, tt.NAME
