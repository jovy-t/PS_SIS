-- Total student enrollment for each course section at every site

SELECT
    sch.NAME AS School_Name,
    sch.SCHOOL_NUMBER AS School_ID,
    -- some sites have sections that teach different grade levels
    MIN(s.GRADE_LEVEL) AS Min_Grade_Enrolled,
    MAX(s.GRADE_LEVEL) AS Max_Grade_Enrolled,
    sec.COURSE_NUMBER,
    sec.SECTION_NUMBER,
    COUNT(cc.STUDENTID) AS Actual_Students_Enrolled,
    sec.NO_OF_STUDENTS AS Stored_Student_Count
FROM
    SCHOOLS sch
INNER JOIN -- Only include schools that have sections
    SECTIONS sec ON sch.SCHOOL_NUMBER = sec.SCHOOLID
    AND sec.TERMID = 3500
INNER JOIN -- Only include sections that have student enrollment
    CC cc ON sec.ID = cc.SECTIONID
INNER JOIN -- Only include students who are actively enrolled (status 0)
    STUDENTS s ON cc.STUDENTID = s.ID
    AND s.ENROLL_STATUS = 0
WHERE
    sch.SCHOOL_NUMBER NOT IN (1, 2, 777777, 888888, 999999)
GROUP BY
    sch.NAME,
    sch.SCHOOL_NUMBER,
    sec.COURSE_NUMBER,
    sec.SECTION_NUMBER,
    sec.NO_OF_STUDENTS
ORDER BY
    sch.NAME,
    sch.SCHOOL_NUMBER,
    sec.SECTION_NUMBER;
