-- Brigance Assessment Report for SMCOE
-- Pulls Pre-K and TK students with contact and demographic info

SELECT
  e.first_name,
  e.middle_name,
  e.last_name,
  e.student_number,
  e.state_studentnumber,
  e.grade_level,
  e.schoolid,
  sch.name AS school_name,
  e.home_room AS teacher,
  e.pl_language,
  e.dob,
  e.gender,
  r.racecd,
  e.ethnicity,
  e.fedethnicity,
  e.street,
  e.city,
  e.state,
  e.zip,
  e.home_phone

FROM 
  students e
  LEFT JOIN studentrace r ON r.studentid = e.id
  LEFT JOIN schools sch ON e.schoolid = sch.school_number

WHERE
  e.grade_level BETWEEN -1 AND 0 -- PreK and TK
  AND e.schoolid NOT IN ('777777', '888888') -- Exclude district-wide/test sites
  AND e.exitcode IS NULL

ORDER BY e.last_name ASC;
