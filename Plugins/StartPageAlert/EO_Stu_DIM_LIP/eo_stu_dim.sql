/* LOCATION: web_root/wildcards/d63_spa/eo_dim.txt

   PURPOSE:
   This wildcard SQL query identifies students who:
   • Have EL Status = 'EO' (English Only / Reclassified Fluent English Proficient)
   • Are currently enrolled in a course whose number begins with "DIM"
   • Are actively enrolled in the current term

   IMPORTANT NOTE ON SYNTAX:
   This file does not follow standard SQL syntax because it uses PowerSchool "Wildcards"
   (tags inside ~ symbols).

   PowerSchool processes these tags FIRST, then sends the resulting SQL to the database.

   RELATED FILES:
   - wildcards/d63_start_page_alerts.txt
   - scripts/StartPage_Alerts.js
   - admin/d63_spa/selection.json
*/

(
SELECT DISTINCT
    s.id,
    s.dcid,
    s.lastfirst,
    s.student_number,
    sch.abbreviation AS schoolabbreviation,
    s.grade_level,
    cc.course_number

FROM students s

/* Join to EL status table */
JOIN S_CA_STU_ELA_C ela
    ON ela.studentsdcid = s.dcid

/* Join to current course enrollment */
JOIN cc
    ON cc.studentid = s.id

/* School lookup for display */
LEFT JOIN schools sch
    ON sch.school_number = s.schoolid

WHERE ~(curschoolid) IN (s.schoolid, s.summerschoolid, 0)

    /* Only actively enrolled students */
    AND s.enroll_status = 0

    /* Student must have EO status */
    AND ela.elastatus = 'EO'

    /* Only courses beginning with DIM */
    AND cc.course_number LIKE 'DIM%'

    /* Ensure student is still enrolled in the section */
    AND cc.dateleft >= CURRENT_DATE

    /* Ensure the course belongs to the current term */
    AND cc.termid IN (
        SELECT id
        FROM terms
        WHERE schoolid = s.schoolid
        AND firstday <= CURRENT_DATE
        AND lastday >= CURRENT_DATE
    )
)