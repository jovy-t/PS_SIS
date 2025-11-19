-- Pulls Parent data

WITH ranked_contacts AS (
    SELECT
        s.dcid,
        s.student_number,
        p.firstname,
        p.middlename,
        p.lastname,
        COALESCE(cs.displayvalue, cs.description) AS relationship,
        CASE scd.liveswithflg
            WHEN 1 THEN 'Yes'
            WHEN 0 THEN 'No'
            ELSE 'Unknown'
        END AS lives_with,
        p.gendercodesetid AS contact_gender,
        rel.primary_contact,
        dem.parented,
        ROW_NUMBER() OVER (
            PARTITION BY s.dcid
            ORDER BY rel.primary_contact DESC, sca.contactpriorityorder NULLS LAST, p.lastname, p.firstname
        ) AS rn
    FROM students s
    JOIN studentcontactassoc sca
        ON sca.studentdcid = s.dcid
    LEFT JOIN studentcontactdetail scd
        ON scd.studentcontactassocid = sca.studentcontactassocid
    LEFT JOIN codeset cs
        ON cs.codesetid = scd.relationshiptypecodesetid
    JOIN person p
        ON p.id = sca.personid
    LEFT JOIN s_contact_relationship_c rel
        ON rel.students_dcid = s.dcid AND rel.s_contacts_sid = p.id
    LEFT JOIN S_CA_STU_X dem
        ON dem.studentsdcid = s.dcid
)

SELECT
    s.last_name,
    s.first_name,
    s.student_number,
    s.state_studentnumber,

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

FROM students s
LEFT JOIN S_CA_STU_X dem
    ON dem.studentsdcid = s.dcid
LEFT JOIN schools sch
    ON sch.school_number = s.schoolid

-- Parent 1
LEFT JOIN (
    SELECT * FROM ranked_contacts WHERE rn = 1
) rc1
    ON rc1.dcid = s.dcid

-- Parent 2
LEFT JOIN (
    SELECT * FROM ranked_contacts WHERE rn = 2
) rc2
    ON rc2.dcid = s.dcid

WHERE s.enroll_status = 0
    AND s.grade_level BETWEEN -1 AND 2
    AND s.schoolid NOT IN ('777777','888888')
    AND s.EXITCODE IS NULL
ORDER BY s.last_name;
