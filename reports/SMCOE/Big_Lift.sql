/*******************************************************************************
  PROJECT: Enterprise Student Information Systems (SIS) ETL Pipeline
  TARGET PLATFORM: Oracle SQL / PowerSchool SIS
  
  DESCRIPTION:
  This high-performance reporting query extracts, cleanses, and consolidates 
  complex student demographic, enrollment, and program data for county 
  compliance auditing (SMCOE). It targets active and recently disenrolled
  TK–3 student cohorts while defensively mitigating severe data fragmentation.

  ADVANCED DESIGN PATTERNS SHOWCASED:
  1. Analytical Windowing (Deterministic Deduplication via ROW_NUMBER)
  2. Polymorphic Multi-Path Fallback Joins (COALESCE routing over 3 schema variants)
  3. Relational Pivot via Conditional Aggregation (MAX/CASE)
*******************************************************************************/

WITH race_cte AS (
  /*---------------------------------------------------------------------------
    1. RELATIONAL PIVOT VIA CONDITIONAL AGGREGATION
    Problem: Student race data is normalized in a 1-to-Many table (STUDENTRACE).
             Joining directly would duplicate student rows.
    Solution: Row-rank entries deterministically by code value, then aggregate 
              and pivot the top 3 distinct race codes into a single 1-to-1 row.
  ---------------------------------------------------------------------------*/
  SELECT
    STUDENTID,
    MAX(CASE WHEN rn = 1 THEN racecd END) AS RACE1,
    MAX(CASE WHEN rn = 2 THEN racecd END) AS RACE2,
    MAX(CASE WHEN rn = 3 THEN racecd END) AS RACE3
  FROM (
    SELECT
      STUDENTID,
      RACECD,
      ROW_NUMBER() OVER (PARTITION BY STUDENTID ORDER BY TO_NUMBER(RACECD)) AS rn
    FROM STUDENTRACE
  )
  GROUP BY STUDENTID
),

lunch_program_cte AS (
    /*---------------------------------------------------------------------------
      2. CATEGORICAL CONSOLIDATION
      Identifies National School Lunch Program (NSLP) participation by capturing 
      the code variant (Free vs. Reduced) to flag eligibility.
    ---------------------------------------------------------------------------*/
    SELECT
        STUDENTSDCID,
        MIN(PROGRAMCODE) AS LUNCH_PROGRAM_CODE
    FROM S_CA_STU_CALPADSPROGRAMS_C
    WHERE PROGRAMCODE IN ('181', '182')
    GROUP BY STUDENTSDCID
),

program_504_cte AS (
    /*---------------------------------------------------------------------------
      3. CHRONOLOGICAL LATEST-RECORD ISOLATION (504 PLANS)
      Problem: Students can have multiple historical 504 program logs (Code 101).
      Solution: Partition by student and order descending by STARTDATE to ensure 
                only the most recent operational record is retrieved.
    ---------------------------------------------------------------------------*/
    SELECT 
        STUDENTSDCID,
        STARTDATE AS EFFECTIVE_DATE_504
    FROM (
        SELECT 
            STUDENTSDCID,
            STARTDATE,
            ROW_NUMBER() OVER (PARTITION BY STUDENTSDCID ORDER BY STARTDATE DESC, ID DESC) AS rn
        FROM S_CA_STU_CALPADSPROGRAMS_C
        WHERE PROGRAMCODE = '101'
    )
    WHERE rn = 1
),

program_foster_cte AS (
    /*---------------------------------------------------------------------------
      4. CHRONOLOGICAL LATEST-RECORD ISOLATION (FOSTER YOUTH)
      Isolates the most recent Foster Youth status entry (Code 190) utilizing 
      the same analytical ranking pattern to eliminate historical row bleeding.
    ---------------------------------------------------------------------------*/
    SELECT 
        STUDENTSDCID,
        STARTDATE AS FOSTER_YOUTH_DATE
    FROM (
        SELECT 
            STUDENTSDCID,
            STARTDATE,
            ROW_NUMBER() OVER (PARTITION BY STUDENTSDCID ORDER BY STARTDATE DESC, ID DESC) AS rn
        FROM S_CA_STU_CALPADSPROGRAMS_C
        WHERE PROGRAMCODE = '190'
    )
    WHERE rn = 1
),

ela_cte AS (
    /*---------------------------------------------------------------------------
      5. DEFENSIVE DATA-INTEGRITY FILTERING (ELA STATUS)
      Extracts primary language and English Language Acquisition data. Orders 
      by start date descending to secure the current linguistic profile.
    ---------------------------------------------------------------------------*/
    SELECT
        STUDENTSDCID,
        PRIMARYLANGUAGE,
        ELASTATUS,
        ELASTATUSSTARTDATE
    FROM (
        SELECT
            STUDENTSDCID,
            PRIMARYLANGUAGE,
            ELASTATUS,
            ELASTATUSSTARTDATE,
            ROW_NUMBER() OVER (PARTITION BY STUDENTSDCID ORDER BY ELASTATUSSTARTDATE DESC, PRIMARYLANGUAGE) AS rn
        FROM S_CA_STU_ELA_C
    )
    WHERE rn = 1
),

/*===========================================================================
  POLYMORPHIC TEACHER-ASSIGNMENT PIPELINES (PATHS 1-3)
  Problem: Legacy data models and modular scheduling systems split teacher 
           assignments across core tables (CC), platform-managed enrollment tables 
           (PSM), and static schedule overrides.
  Solution: Extract assignments independently via 3 asynchronous subqueries,
            ranking rows by operational recency (DATELEFT DESC) to guarantee 
            structural resilience against term-boundary expirations.
===========================================================================*/

/* Path 1: Core Schedule (CC Table Roster Mapping) */
teacher_cc AS (
  SELECT STUDENTID, TEACHER_NAME
  FROM (
    SELECT
        cc.STUDENTID,
        COALESCE(t.LASTFIRST, t.FIRST_NAME || ' ' || t.LAST_NAME) AS TEACHER_NAME,
        ROW_NUMBER() OVER (PARTITION BY cc.STUDENTID ORDER BY cc.DATELEFT DESC, cc.DATEENROLLED DESC) as rn
    FROM CC cc
    JOIN SECTIONS s ON s.ID = cc.SECTIONID
    LEFT JOIN TEACHERS t ON t.ID = s.TEACHER
    WHERE cc.SECTIONID IS NOT NULL
  ) WHERE rn = 1
),

/* Path 2: PowerSchool Master (PSM) System Section Mapping */
teacher_psm AS (
  SELECT STUDENTID, TEACHER_NAME
  FROM (
    SELECT
        se.STUDENTID,
        (pt.FIRSTNAME || ' ' || pt.LASTNAME) AS TEACHER_NAME,
        ROW_NUMBER() OVER (PARTITION BY se.STUDENTID ORDER BY se.DATELEFT DESC) as rn
    FROM PSM_SECTIONENROLLMENT se
    JOIN PSM_SECTIONTEACHER st ON st.SECTIONID = se.SECTIONID AND (st.PRIORITYORDER = 1 OR st.PRIORITYORDER IS NULL)
    JOIN PSM_TEACHER pt ON pt.ID = st.TEACHERID
    WHERE se.SECTIONENROLLMENTSTATUS = 0
  ) WHERE rn = 1
),

/* Path 3: Master Course Schedule Cross-Reference Rule Overrides */
teacher_by_cn AS (
  SELECT STUDENTID, TEACHER_NAME
  FROM (
    SELECT
        se.STUDENTID,
        COALESCE(t2.LASTFIRST, t2.FIRST_NAME || ' ' || t2.LAST_NAME, pt2.FIRSTNAME || ' ' || pt2.LASTNAME) AS TEACHER_NAME,
        ROW_NUMBER() OVER (PARTITION BY se.STUDENTID ORDER BY se.DATELEFT DESC) as rn
    FROM PSM_SECTIONENROLLMENT se
    JOIN SECTIONS s ON s.ID = se.SECTIONID
    LEFT JOIN SCHEDULETEACHERASSIGNMENTS sta ON sta.COURSENUMBER = s.COURSE_NUMBER AND sta.SCHOOLID = s.SCHOOLID
    LEFT JOIN TEACHERS t2 ON (t2.DCID = sta.TEACHERKEY OR t2.ID = sta.TEACHERKEY)
    LEFT JOIN PSM_TEACHER pt2 ON pt2.ID = sta.TEACHERKEY
    WHERE se.SECTIONENROLLMENTSTATUS = 0
  ) WHERE rn = 1
)

/*===========================================================================
  MAIN EXECUTION SELECTION & TRANSFORMATION ENGINE
===========================================================================*/
SELECT
    /*--- Global Identifiers ---*/
    '4168890' AS school_district,
    sch.NAME AS school,
    
    /*--- Dynamic Multi-Path Priority Fallback Consolidation ---*/
    COALESCE(tcc.TEACHER_NAME, tpsm.TEACHER_NAME, tcn.TEACHER_NAME) AS teacher,
    
    /*--- Core Identity Metadata ---*/
    e.STUDENT_NUMBER AS student_local_id,
    e.STATE_STUDENTNUMBER AS ssid,
    e.FIRST_NAME AS student_legal_first_name,
    e.MIDDLE_NAME AS student_legal_middle_name,
    e.LAST_NAME AS student_legal_last_name,
    dem.namesuffix AS student_legal_name_suffix,
    e.DOB AS date_of_birth,
    e.GENDER AS gender,
    dem.BIRTHCOUNTRY AS birth_country,
    
    /*--- Language Profile Metrics ---*/
    ela.PRIMARYLANGUAGE AS primary_home_language,
    ela.ELASTATUS AS english_language_acquisition_status_code,
    ela.ELASTATUSSTARTDATE AS english_language_acquisition_status_start_date,
    
    /*--- Continuous Scope Filters & Dynamic Enums ---*/
    e.ENTRYDATE AS school_enrollment_start_date,
    e.EXITDATE AS school_enrollment_exit_date,
    e.GRADE_LEVEL AS grade,
    CASE WHEN e.FEDETHNICITY = 1 THEN 'Y' ELSE 'N' END AS hispanic_ethnicity_yn,
    
    /*--- Restructured Flattend Demographics ---*/
    r.RACE1 AS race_1,
    r.RACE2 AS race_2,
    r.RACE3 AS race_3,
    e.STREET AS residence_address,
    e.CITY AS residence_city,
    e.ZIP AS residence_zip,

    /*--- Program Status Evaluators ---*/
    CASE WHEN dem.primarydisability IS NOT NULL THEN 'Y' ELSE 'N' END AS special_education_code,
    dem.primarydisability AS special_ed_disability_code_1,
    NULL AS special_ed_disability_code_2, 
    dem.spentrydate AS disability_start_date,
    NULL AS disability_end_date, 
    lpc.LUNCH_PROGRAM_CODE AS free_or_reduced_meal_code,
    
    CASE 
      WHEN dem.sped504 = 1 OR p504.EFFECTIVE_DATE_504 IS NOT NULL THEN 'Yes' 
      ELSE 'No' 
    END AS accommodation_code_504,
    
    p504.EFFECTIVE_DATE_504 AS effective_date_504,
    dem.fosterprogram AS foster_youth_code,
    pfost.FOSTER_YOUTH_DATE AS foster_youth_date

FROM STUDENTS e

/*--- Relational Mapping Matrix (All Left-Outer Joins to protect core roster scope) ---*/
LEFT JOIN race_cte r            ON r.STUDENTID = e.ID
LEFT JOIN SCHOOLS sch           ON e.SCHOOLID = sch.SCHOOL_NUMBER
LEFT JOIN S_CA_STU_X dem        ON e.DCID = dem.STUDENTSDCID
LEFT JOIN ela_cte ela           ON ela.STUDENTSDCID = e.DCID
LEFT JOIN lunch_program_cte lpc ON lpc.STUDENTSDCID = e.DCID
LEFT JOIN program_504_cte p504  ON p504.STUDENTSDCID = e.DCID
LEFT JOIN program_foster_cte pfost ON pfost.STUDENTSDCID = e.DCID
LEFT JOIN teacher_cc tcc        ON tcc.STUDENTID = e.ID
LEFT JOIN teacher_psm tpsm      ON tpsm.STUDENTID = e.ID
LEFT JOIN teacher_by_cn tcn      ON tcn.STUDENTID = e.ID

WHERE e.GRADE_LEVEL BETWEEN -1 AND 3                             -- TK (Transitional Kindergarten) through 3rd Grade cohort
  AND e.SCHOOLID NOT IN ('777777', '888888', '1', '2', '4168890') 
  AND TO_CHAR(e.EXITDATE, 'YYYY') = :P1_YEAR

ORDER BY sch.NAME, e.STUDENT_NUMBER ASC;