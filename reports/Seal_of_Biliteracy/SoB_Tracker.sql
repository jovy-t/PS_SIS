/* 
California Seal of Biliteracy Tracker for active grade 12 students.
This query combines coursework, AP exam data, and California state assessment data
to show student progress toward the Seal of Biliteracy and identify students who
may need additional review for world language proficiency.
*/

WITH student_scope AS (
    SELECT
        s.id,
        s.dcid,
        s.student_number,
        s.last_name,
        s.first_name,
        s.grade_level,
        s.enroll_status,
        s.schoolid,
        sx.elastatus
    FROM students s
    LEFT JOIN s_ca_stu_x sx
        ON sx.studentsdcid = s.dcid
    WHERE s.enroll_status = 0
      AND s.grade_level = 12
),

english_gradreq AS (
    /*
    English graduation requirement source:
    - CUSD Grad requirement set
    - English course group
    - approved course list stored in COURSELISTCHECK
    - required credits stored in REQCRHRS
    */
    SELECT
        gr.id,
        gr.gradreqsetid,
        gr.name,
        gr.coursegroup,
        gr.courselistcheck,
        gr.reqcrhrs,
        gr.schoolid
    FROM gradreq gr
    WHERE gr.gradreqsetid = 2
      AND gr.coursegroup = 'English'
      AND gr.name = 'English'
),

english_coursework AS (
    /*
    Only count courses that appear in the approved English graduation course list.
    INSTR with comma wrappers prevents partial course number matches.
    */
    SELECT
        sg.studentid,
        SUM(NVL(sg.earnedcrhrs, 0)) AS eng_total_credits,
        ROUND(
            SUM((NVL(sg.gpa_points, 0) + NVL(sg.gpa_addedvalue, 0)) * NVL(sg.earnedcrhrs, 0))
            / NULLIF(SUM(NVL(sg.earnedcrhrs, 0)), 0),
            3
        ) AS eng_gpa
    FROM storedgrades sg
    CROSS JOIN english_gradreq gr
    WHERE TO_NUMBER(sg.grade_level) >= 9
      AND UPPER(sg.credit_type) LIKE '%ELA%'
      AND INSTR(',' || gr.courselistcheck || ',', ',' || sg.course_number || ',') > 0
    GROUP BY sg.studentid
),

world_language_coursework AS (
    /*
    Fields produced:
    - wl_years_completed: count of distinct grade levels with earned credit
    - wl_total_credits
    - wl_gpa

    Important:
    This identifies coursework progress, but California's coursework
    path also requires oral proficiency or another qualifying language
    assessment. That extra requirement is NOT fully mapped yet, so
    coursework alone does not automatically mark the student as fully
    qualified in the final result.
    --------------------------------------------------------------
    */
    SELECT
        sg.studentid,
        COUNT(DISTINCT CASE
            WHEN NVL(sg.earnedcrhrs, 0) > 0 THEN TO_NUMBER(sg.grade_level)
        END) AS wl_years_completed,
        SUM(NVL(sg.earnedcrhrs, 0)) AS wl_total_credits,
        ROUND(
            SUM((NVL(sg.gpa_points, 0) + NVL(sg.gpa_addedvalue, 0)) * NVL(sg.earnedcrhrs, 0))
            / NULLIF(SUM(NVL(sg.earnedcrhrs, 0)), 0),
            3
        ) AS wl_gpa
    FROM storedgrades sg
    JOIN courses c
        ON c.course_number = sg.course_number
    WHERE TO_NUMBER(sg.grade_level) >= 9
      AND c.sched_department = 'FL'
    GROUP BY sg.studentid
),

legacy_ap_scores AS (
    /*
    Pulls AP scores from the legacy testing tables. Taking the MAX score in case multiple score rows exist.
    */
    SELECT
        sts.studentid,
        MAX(CASE WHEN ts.name = 'AP English' THEN sts.numscore END) AS ap_english_score,
        MAX(CASE WHEN ts.name = 'AP French'  THEN sts.numscore END) AS ap_french_score,
        MAX(CASE WHEN ts.name = 'AP Spanish' THEN sts.numscore END) AS ap_spanish_score
    FROM studenttestscore sts
    JOIN testscore ts
        ON ts.id = sts.testscoreid
    WHERE ts.name IN ('AP English', 'AP French', 'AP Spanish')
    GROUP BY sts.studentid
),

ca_state_events AS (
    /*
    Finds California state testing and ranks to keep only the latest 
    administration for each student and test.

    Tests currently included:
    - SBAC_SUM_ELA
    - SUMMATIVE_ELPAC
    - SUMMATIVE_ALT_ELPAC

   Utilizing DENSE_RANK
    Some students may have multiple administrations. Only want the most recent test date for each test type.
    --------------------------------------------------------------
    */
    SELECT DISTINCT
        sct.id AS stu_test_id,
        sct.studentid,
        ct.name AS test_name,
        sct.test_date,
        DENSE_RANK() OVER (
            PARTITION BY sct.studentid, ct.name
            ORDER BY sct.test_date DESC NULLS LAST, sct.id DESC
        ) AS rn
    FROM s_ca_stu_test_s sct
    JOIN s_ca_stu_testscore_c scts
        ON scts.s_ca_stu_test_sid = sct.id
    JOIN s_ca_testscore_c cts
        ON cts.id = scts.testscoreid
    JOIN s_ca_test_s ct
        ON ct.id = cts.s_ca_test_sid
    WHERE (ct.name = 'SBAC_SUM_ELA' AND cts.name IN ('SBAC_01_TS2', 'SBAC_01_TS5'))
       OR (ct.name = 'SUMMATIVE_ELPAC' AND cts.name IN ('ELPAC_21_TS2', 'ELPAC_21_TS5'))
       OR (ct.name = 'SUMMATIVE_ALT_ELPAC' AND cts.name IN ('ELPAC_23_TS2', 'ELPAC_23_TS5'))
),

ca_state_latest_scores AS (
    /*
    Pulls the actual score values from the most recent
    California state testing event identified above.

    Current mapped fields:
    SBAC ELA
    - SBAC_01_TS2 = Scale Score
    - SBAC_01_TS5 = Achievement Level

    ELPAC
    - ELPAC_21_TS2 = Oral Language Scale Score
    - ELPAC_21_TS5 = Oral Language PL
    - ELPAC_23_TS2 = Oral Language Scale Score
    - ELPAC_23_TS5 = Oral Language PL

    Notes:
    - VALUE is stored as text, use REGEXP_LIKE before TO_NUMBER
    - scale scores are displayed for transparency
    - achievement / PL fields are used for qualification logic
    --------------------------------------------------------------
    */
    SELECT
        e.studentid,

        MAX(
            CASE
                WHEN ct.name = 'SBAC_SUM_ELA'
                 AND cts.name = 'SBAC_01_TS2'
                 AND REGEXP_LIKE(TRIM(scts.value), '^[0-9]+$')
                THEN TO_NUMBER(TRIM(scts.value))
            END
        ) AS sbac_ela_scale_score,

        MAX(
            CASE
                WHEN ct.name = 'SBAC_SUM_ELA'
                 AND cts.name = 'SBAC_01_TS5'
                 AND REGEXP_LIKE(TRIM(scts.value), '^[0-9]+$')
                THEN TO_NUMBER(TRIM(scts.value))
            END
        ) AS sbac_ela_achievement_level,

        MAX(
            CASE
                WHEN ct.name = 'SUMMATIVE_ELPAC'
                 AND cts.name = 'ELPAC_21_TS2'
                 AND REGEXP_LIKE(TRIM(scts.value), '^[0-9]+$')
                THEN TO_NUMBER(TRIM(scts.value))
                WHEN ct.name = 'SUMMATIVE_ALT_ELPAC'
                 AND cts.name = 'ELPAC_23_TS2'
                 AND REGEXP_LIKE(TRIM(scts.value), '^[0-9]+$')
                THEN TO_NUMBER(TRIM(scts.value))
            END
        ) AS elpac_oral_language_scale_score,

        MAX(
            CASE
                WHEN ct.name = 'SUMMATIVE_ELPAC'
                 AND cts.name = 'ELPAC_21_TS5'
                 AND REGEXP_LIKE(TRIM(scts.value), '^[0-9]+$')
                THEN TO_NUMBER(TRIM(scts.value))
                WHEN ct.name = 'SUMMATIVE_ALT_ELPAC'
                 AND cts.name = 'ELPAC_23_TS5'
                 AND REGEXP_LIKE(TRIM(scts.value), '^[0-9]+$')
                THEN TO_NUMBER(TRIM(scts.value))
            END
        ) AS elpac_oral_language_pl,

        MAX(CASE WHEN ct.name = 'SBAC_SUM_ELA' THEN e.test_date END) AS sbac_ela_test_date,
        MAX(CASE WHEN ct.name IN ('SUMMATIVE_ELPAC', 'SUMMATIVE_ALT_ELPAC') THEN e.test_date END) AS elpac_test_date

    FROM ca_state_events e
    JOIN s_ca_stu_testscore_c scts
        ON scts.s_ca_stu_test_sid = e.stu_test_id
    JOIN s_ca_testscore_c cts
        ON cts.id = scts.testscoreid
    JOIN s_ca_test_s ct
        ON ct.id = cts.s_ca_test_sid
    WHERE e.rn = 1
    GROUP BY e.studentid
),

final_flags AS (
    /*
    Combines all previously calculated pieces and creates
    easy-to-use flags for the final report output.

    Think of these flags as "yes/no building blocks" that let the
    final SELECT show human-readable statuses.
    --------------------------------------------------------------
    */
    SELECT
        ss.id AS studentid,
        ss.student_number,
        ss.last_name,
        ss.first_name,
        ss.grade_level,
        ss.schoolid,
        NVL(ss.elastatus, 'EO') AS ela_status,

        ec.eng_total_credits,
        ec.eng_gpa,

        wl.wl_years_completed,
        wl.wl_total_credits,
        wl.wl_gpa,

        ap.ap_english_score,
        ap.ap_french_score,
        ap.ap_spanish_score,

        ca.sbac_ela_test_date,
        ca.sbac_ela_scale_score,
        ca.sbac_ela_achievement_level,
        ca.elpac_test_date,
        ca.elpac_oral_language_scale_score,
        ca.elpac_oral_language_pl,

        CASE
            WHEN NVL(ec.eng_total_credits, 0) >= 40
             AND NVL(ec.eng_gpa, 0) >= 3.0
            THEN 1 ELSE 0
        END AS english_coursework_met,

        /* State assessment path for English:
           SBAC/CAASPP ELA Achievement Level >= 3 */
        CASE
            WHEN NVL(ca.sbac_ela_achievement_level, 0) >= 3
            THEN 1 ELSE 0
        END AS sbac_ela_met,

        /* AP English path */
        CASE
            WHEN NVL(ap.ap_english_score, 0) >= 3
            THEN 1 ELSE 0
        END AS ap_english_met,

        /* Coursework progress for world language */
        CASE
            WHEN NVL(wl.wl_years_completed, 0) >= 4
             AND NVL(wl.wl_gpa, 0) >= 3.0
            THEN 1 ELSE 0
        END AS wl_coursework_progress_met,

        /* AP world language path currently mapped */
        CASE
            WHEN NVL(ap.ap_french_score, 0) >= 3
              OR NVL(ap.ap_spanish_score, 0) >= 3
            THEN 1 ELSE 0
        END AS ap_world_language_met

    FROM student_scope ss
    LEFT JOIN english_coursework ec
        ON ec.studentid = ss.id
    LEFT JOIN world_language_coursework wl
        ON wl.studentid = ss.id
    LEFT JOIN legacy_ap_scores ap
        ON ap.studentid = ss.id
    LEFT JOIN ca_state_latest_scores ca
        ON ca.studentid = ss.id
)

SELECT
    ff.student_number                        AS "Student Number",
    ff.last_name                             AS "Last Name",
    ff.first_name                            AS "First Name",
    ff.schoolid                              AS "School ID",
    ff.grade_level                           AS "Grade Level",
    ff.ela_status                            AS "ELA Status",

    ff.eng_total_credits                     AS "English Credits",
    ff.eng_gpa                               AS "English GPA",
    ff.sbac_ela_test_date                    AS "SBAC ELA Test Date",
    ff.sbac_ela_scale_score                  AS "SBAC ELA Scale Score",
    ff.sbac_ela_achievement_level            AS "SBAC ELA Achievement Level",
    ff.ap_english_score                      AS "AP English Score",

    ff.wl_years_completed                    AS "WL Years Completed",
    ff.wl_total_credits                      AS "WL Credits",
    ff.wl_gpa                                AS "WL GPA",
    ff.ap_french_score                       AS "AP French Score",
    ff.ap_spanish_score                      AS "AP Spanish Score",

    ff.elpac_test_date                       AS "ELPAC Test Date",
    ff.elpac_oral_language_scale_score       AS "ELPAC Oral Language Scale Score",
    ff.elpac_oral_language_pl                AS "ELPAC Oral Language PL",

    CASE
        WHEN ff.english_coursework_met = 1 THEN 'Met via Coursework'
        WHEN ff.sbac_ela_met = 1 THEN 'Met via SBAC ELA'
        WHEN ff.ap_english_met = 1 THEN 'Met via AP English'
        ELSE 'Not Met'
    END AS "English Requirement Status",

    CASE
        WHEN ff.ela_status = 'EL' AND NVL(ff.elpac_oral_language_pl, 0) >= 4 THEN 'Met'
        WHEN ff.ela_status = 'EL' THEN 'Not Met'
        ELSE 'Not Required'
    END AS "ELPAC Oral Requirement Status",

    CASE
        WHEN ff.ap_world_language_met = 1 THEN 'Met via AP'
        WHEN ff.wl_coursework_progress_met = 1 THEN 'Coursework Met - Oral Proficiency Review Needed'
        ELSE 'Not Met'
    END AS "World Language Requirement Status",

    CASE
        WHEN (ff.english_coursework_met = 1 OR ff.sbac_ela_met = 1 OR ff.ap_english_met = 1)
         AND (ff.ela_status <> 'EL' OR NVL(ff.elpac_oral_language_pl, 0) >= 4)
         AND ff.ap_world_language_met = 1
        THEN 'Yes'
        ELSE 'No'
    END AS "Qualifies for Seal",

    CASE
        WHEN (ff.english_coursework_met = 1 OR ff.sbac_ela_met = 1 OR ff.ap_english_met = 1)
         AND (ff.ela_status <> 'EL' OR NVL(ff.elpac_oral_language_pl, 0) >= 4)
         AND ff.ap_world_language_met = 1
        THEN 'Fully Met by Mapped Paths'
        WHEN (ff.english_coursework_met = 1 OR ff.sbac_ela_met = 1 OR ff.ap_english_met = 1)
         AND (ff.ela_status <> 'EL' OR NVL(ff.elpac_oral_language_pl, 0) >= 4)
         AND ff.wl_coursework_progress_met = 1
         AND ff.ap_world_language_met = 0
        THEN 'Needs World Language Oral Proficiency / District Assessment Review'
        WHEN NOT (ff.english_coursework_met = 1 OR ff.sbac_ela_met = 1 OR ff.ap_english_met = 1)
         AND ff.ap_world_language_met = 0
         AND ff.wl_coursework_progress_met = 0
        THEN 'Missing English and World Language'
        WHEN NOT (ff.english_coursework_met = 1 OR ff.sbac_ela_met = 1 OR ff.ap_english_met = 1)
        THEN 'Missing English Requirement'
        WHEN ff.ela_status = 'EL' AND NVL(ff.elpac_oral_language_pl, 0) < 4
        THEN 'Missing ELPAC Oral Language PL 4'
        WHEN ff.ap_world_language_met = 0 AND ff.wl_coursework_progress_met = 0
        THEN 'Missing World Language Requirement'
        ELSE 'Review'
    END AS "Seal Progress Status"

FROM final_flags ff
ORDER BY ff.last_name, ff.first_name;