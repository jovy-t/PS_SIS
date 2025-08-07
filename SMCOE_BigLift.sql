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
)

, ela_cte AS (
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
          CASE 
            WHEN elastatusstartdate IS NULL THEN 1 
            ELSE 0 
          END, 
          elastatusstartdate DESC
      ) AS rn
    FROM s_ca_stu_ela_c
  )
  WHERE rn = 1
)

, all_enrollment AS (
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
    LEFT OUTER JOIN reenrollments
    ON reenrollments.studentid=students.id
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
    s.student_number, s.state_studentnumber, s.first_name, s.middle_name, s.last_name, dem.namesuffix, s.gender,
    s.dob, s.street, s.city, s.zip, s.state, s.fedethnicity, r.race1, r.race2, r.race3, dem.birthcountry,
    s.mother, s.father, dem.guardian2_firstname, dem.guardian2_lastname, dem.g1relationship, dem.g2relationship, 
    dem.guardianaddrstreet, dem.guardianaddrcity, dem.guardianaddrstate, dem.guardianaddrzip,
    s.home_phone, s.guardianemail, dem.parented, dem.parented2, dem.parentcorresplang,
    re.schoolid, sch.name AS school_name, re.grade_level, re.entrydate, re.exitdate, re.districtofresidence, s.home_room AS teacher,
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

ORDER BY s.student_number ASC
