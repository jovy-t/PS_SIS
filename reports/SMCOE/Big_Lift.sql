-- Big Lift Program Report for SMCOE
-- Pulls students in grades TK–3 with demographic, program, and enrollment data

WITH race_cte AS (
  SELECT
    studentid,
    MAX(CASE WHEN rn = 1 THEN racecd END) AS race1,
    MAX(CASE WHEN rn = 2 THEN racecd END) AS race2,
    MAX(CASE WHEN rn = 3 THEN racecd END) AS race3
  FROM (
    SELECT
      studentid,
      racecd,
      ROW_NUMBER() OVER (PARTITION BY studentid ORDER BY TO_NUMBER(racecd)) AS rn
    FROM studentrace
  )
  GROUP BY studentid
),

ela_cte AS (
  SELECT *
  FROM (
    SELECT
      studentsdcid,
      elastatus,
      elastatusstartdate,
      primarylanguage,
      primarylanguagedesc,
      ROW_NUMBER() OVER (
        PARTITION BY studentsdcid 
        ORDER BY 
          CASE WHEN elastatusstartdate IS NULL THEN 1 ELSE 0 END, 
          elastatusstartdate DESC
      ) AS rn
    FROM s_ca_stu_ela_c
  )
  WHERE rn = 1
),

/* Path 1: CC → SECTIONS → TEACHERS */
teacher_cc AS (
  SELECT
      cc.STUDENTID,
      MIN(COALESCE(t.LASTFIRST, t.FIRST_NAME || ' ' || t.LAST_NAME)) AS TEACHER_NAME
  FROM CC cc
  JOIN SECTIONS s
    ON s.ID = cc.SECTIONID
  LEFT JOIN TEACHERS t
    ON t.ID = s.TEACHER
  WHERE cc.DATEENROLLED <= TRUNC(SYSDATE)
    AND (cc.DATELEFT IS NULL OR cc.DATELEFT >= TRUNC(SYSDATE))
    AND cc.SECTIONID IS NOT NULL
  GROUP BY cc.STUDENTID
),

/* Path 2: PSM_* tables */
teacher_psm AS (
  SELECT
      se.STUDENTID,
      MIN(pt.FIRSTNAME || ' ' || pt.LASTNAME) AS TEACHER_NAME
  FROM PSM_SECTIONENROLLMENT se
  JOIN PSM_SECTIONTEACHER st
    ON st.SECTIONID = se.SECTIONID
   AND (st.PRIORITYORDER = 1 OR st.PRIORITYORDER IS NULL)
  JOIN PSM_TEACHER pt
    ON pt.ID = st.TEACHERID
  WHERE se.SECTIONENROLLMENTSTATUS = 0
    AND (se.DATELEFT IS NULL OR se.DATELEFT >= TRUNC(SYSDATE))
  GROUP BY se.STUDENTID
),

/* Path 3: by COURSENUMBER via SCHEDULETEACHERASSIGNMENTS */
teacher_by_cn AS (
  SELECT
      se.STUDENTID,
      MIN(
        COALESCE(t2.LASTFIRST, t2.FIRST_NAME || ' ' || t2.LAST_NAME,
                 pt2.FIRSTNAME || ' ' || pt2.LASTNAME)
      ) AS TEACHER_NAME
  FROM PSM_SECTIONENROLLMENT se
  JOIN SECTIONS s
    ON s.ID = se.SECTIONID
  LEFT JOIN SCHEDULETEACHERASSIGNMENTS sta
    ON sta.COURSENUMBER = s.COURSE_NUMBER
   AND sta.SCHOOLID = s.SCHOOLID
  /* TEACHERKEY inconsistencies: try TEACHERS.DCID, fallback TEACHERS.ID; also try PSM_TEACHER.ID */
  LEFT JOIN TEACHERS t2
    ON (t2.DCID = sta.TEACHERKEY OR t2.ID = sta.TEACHERKEY)
  LEFT JOIN PSM_TEACHER pt2
    ON pt2.ID = sta.TEACHERKEY
  WHERE se.SECTIONENROLLMENTSTATUS = 0
    AND (se.DATELEFT IS NULL OR se.DATELEFT >= TRUNC(SYSDATE))
  GROUP BY se.STUDENTID
),

all_enrollment AS (
  -- Gets current and past enrollments in TK–3 range for 2024–2025 SY
  SELECT
    dcid AS studentid,
    entrydate,
    exitdate,
    exitcode,
    grade_level,
    schoolid,
    lunchstatus,
    districtofresidence
  FROM students
  WHERE
    grade_level BETWEEN -1 AND 3
    AND entrydate BETWEEN TO_DATE('08/14/2024', 'MM/DD/YYYY') AND TO_DATE('06/06/2025', 'MM/DD/YYYY')
    AND NVL(exitdate, TO_DATE('12/31/9999','MM/DD/YYYY')) >= TO_DATE('08/15/2024','MM/DD/YYYY')
    AND (
      exitcode IS NULL
      OR (exitcode NOT LIKE 'N%' AND exitcode != '100')
    )

  UNION

  SELECT
    students.dcid AS studentid,
    reenrollments.entrydate,
    reenrollments.exitdate,
    reenrollments.exitcode,
    reenrollments.grade_level,
    reenrollments.schoolid,
    students.lunchstatus,
    reenrollments.districtofresidence
  FROM students
    LEFT OUTER JOIN reenrollments ON reenrollments.studentid = students.id
  WHERE
    reenrollments.grade_level BETWEEN -1 AND 3
    AND reenrollments.entrydate BETWEEN TO_DATE('08/14/2024', 'MM/DD/YYYY') AND TO_DATE('06/06/2025', 'MM/DD/YYYY')
    AND NVL(reenrollments.exitdate, TO_DATE('12/31/9999','MM/DD/YYYY')) >= TO_DATE('08/15/2024','MM/DD/YYYY')
    AND (
      reenrollments.exitcode IS NULL
      OR (reenrollments.exitcode NOT LIKE 'N%' AND reenrollments.exitcode != '100')
    )
)

SELECT 
  s.student_number, s.state_studentnumber,
  s.first_name, s.middle_name, s.last_name, dem.namesuffix,
  s.gender, s.dob, s.street, s.city, s.zip, s.state,
  s.fedethnicity, r.race1, r.race2, r.race3,
  dem.birthcountry,
  re.schoolid, sch.name AS school_name,
  re.grade_level, re.entrydate, re.exitdate, re.districtofresidence,
   /* First non-null across three sources */
  COALESCE(tcc.TEACHER_NAME, tpsm.TEACHER_NAME, tcn.TEACHER_NAME) AS TEACHER,
  dem.elastatus, dem.elastatusdate, ela.primarylanguagedesc,
  dem.spentrydate, dem.primarydisability, dem.sped504,
  dem.fosterprogram, re.lunchstatus

FROM 
  all_enrollment re
  INNER JOIN students s ON re.studentid = s.dcid
  LEFT JOIN S_CA_STU_X dem ON s.dcid = dem.studentsdcid
  LEFT JOIN race_cte r ON r.studentid = s.id
  LEFT JOIN schools sch ON re.schoolid = sch.school_number
  LEFT JOIN ela_cte ela ON s.dcid = ela.studentsdcid
  LEFT JOIN teacher_cc   tcc ON tcc.studentid  = s.id
  LEFT JOIN teacher_psm  tpsm ON tpsm.studentid = s.id
  LEFT JOIN teacher_by_cn tcn ON tcn.studentid  = s.id

ORDER BY s.student_number ASC;
