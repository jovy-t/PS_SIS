WITH all_enrollment AS (
    -- Current students table
    SELECT
        dcid AS studentid,
        student_number,
        state_studentnumber,
        entrydate,
        exitdate,
        exitcode,
        grade_level,
        schoolid
    FROM students
    WHERE
        grade_level BETWEEN -1 AND 3
        AND entrydate BETWEEN TO_DATE('08/14/2024', 'MM/DD/YYYY') AND TO_DATE('06/06/2025', 'MM/DD/YYYY')
        AND NVL(exitdate, TO_DATE('12/31/9999','MM/DD/YYYY')) >= TO_DATE('08/15/2024','MM/DD/YYYY')
        AND (
            exitcode IS NULL
            OR (exitcode NOT LIKE 'N%' AND exitcode != '100')
        )

    UNION ALL

    -- reenrollments table
    SELECT
        s.dcid AS studentid,
        s.student_number,
        s.state_studentnumber,
        r.entrydate,
        r.exitdate,
        r.exitcode,
        r.grade_level,
        r.schoolid
    FROM students s
    JOIN reenrollments r
        ON r.studentid = s.id
    WHERE
        r.grade_level BETWEEN -1 AND 3
        AND r.entrydate BETWEEN TO_DATE('08/14/2024', 'MM/DD/YYYY') AND TO_DATE('06/06/2025', 'MM/DD/YYYY')
        AND NVL(r.exitdate, TO_DATE('12/31/9999','MM/DD/YYYY')) >= TO_DATE('08/15/2024','MM/DD/YYYY')
        AND (
            r.exitcode IS NULL
            OR (r.exitcode NOT LIKE 'N%' AND r.exitcode != '100')
        )
),

ranked_contacts AS (
    SELECT
        ae.studentid,
        ae.student_number,
        p.firstname,
        p.middlename,
        p.lastname,
        rel.lives_with,
        rel.relationship,
        p.gendercodesetid AS contact_gender, -- fixed alias
        rel.primary_contact,
        rel.contact_order,
        dem.parented,
        ROW_NUMBER() OVER (
            PARTITION BY ae.studentid
            ORDER BY rel.primary_contact DESC, sca.contactpriorityorder NULLS LAST, p.lastname, p.firstname
        ) AS rn
    FROM all_enrollment ae
    JOIN studentcontactassoc sca
        ON sca.studentdcid = ae.studentid
    JOIN person p
        ON p.id = sca.personid
    LEFT JOIN s_contact_relationship_c rel
        ON rel.students_dcid = ae.studentid
       AND rel.s_contacts_sid = p.id
    LEFT JOIN S_CA_STU_X dem
        ON dem.studentsdcid = ae.studentid
)

SELECT
    s.last_name,
    s.middle_name,
    s.first_name,
    ae.student_number,
    s.state_studentnumber,
    s.dob,
    s.gender,
    sch.name,
    ae.grade_level,
    s.home_room AS "Teacher",

    -- First Parent
    rc1.firstname AS "Parent 1 First Name",
    rc1.lastname AS "Parent 1 Last Name",
    rc1.lives_with AS "Lives with Child",
    rc1.relationship AS "Parent 1 Relationship to Child",
    rc1.contact_gender AS "Parent 1 Gender",
    dem.parented AS "Parent 1 Education Level",

    -- Second Parent
    rc2.firstname AS "Parent 2 First Name",
    rc2.lastname AS "Parent 2 Last Name",
    rc2.lives_with AS "Lives with Child",
    rc2.relationship AS "Parent 2 Relationship to Child",
    rc2.contact_gender AS "Parent 2 Gender",
    dem.parented2 AS "Parent 2 Education Level"

FROM all_enrollment ae
JOIN students s
    ON s.dcid = ae.studentid
LEFT JOIN S_CA_STU_X dem
    ON dem.studentsdcid = s.dcid
LEFT JOIN schools sch
    ON sch.school_number = ae.schoolid

-- Parent 1
LEFT JOIN (
    SELECT * FROM ranked_contacts WHERE rn = 1
) rc1
    ON rc1.studentid = ae.studentid

-- Parent 2
LEFT JOIN (
    SELECT * FROM ranked_contacts WHERE rn = 2
) rc2
    ON rc2.studentid = ae.studentid

ORDER BY s.last_name;
