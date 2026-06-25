WITH person_address_cte AS (
    SELECT 
        personid,
        street,
        linetwo,
        city,
        postalcode
    FROM (
        SELECT 
            paa.personid,
            pa.street,
            pa.linetwo,
            pa.city,
            pa.postalcode,
            ROW_NUMBER() OVER (PARTITION BY paa.personid ORDER BY paa.personaddressid DESC) AS rn
        FROM personaddressassoc paa
        JOIN personaddress pa ON pa.personaddressid = paa.personaddressid
    )
    WHERE rn = 1
),

person_phone_cte AS (
    SELECT 
        personid,
        phonenumberasentered
    FROM (
        SELECT 
            personid,
            phonenumberasentered,
            ROW_NUMBER() OVER (PARTITION BY personid ORDER BY personphonenumberassocid DESC) AS rn
        FROM personphonenumberassoc
    )
    WHERE rn = 1
),

person_email_cte AS (
    SELECT 
        personid,
        emailaddress
    FROM (
        SELECT 
            peaa.personid,
            ea.emailaddress,
            ROW_NUMBER() OVER (PARTITION BY peaa.personid ORDER BY peaa.emailaddressid DESC) AS rn
        FROM personemailaddressassoc peaa
        JOIN emailaddress ea ON ea.emailaddressid = peaa.emailaddressid
    )
    WHERE rn = 1
),

ranked_contacts AS (
    SELECT
        s.dcid,
        s.student_number,
        p.firstname,
        p.middlename,
        p.lastname,
        COALESCE(cs.displayvalue, cs.description) AS relationship,
        rel.primary_contact,
        dem.parented,
        addr.street,
        addr.linetwo,
        addr.city,
        addr.postalcode,
        ph.phonenumberasentered,
        em.emailaddress,
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
    LEFT JOIN person_address_cte addr
        ON addr.personid = p.id
    LEFT JOIN person_phone_cte ph
        ON ph.personid = p.id
    LEFT JOIN person_email_cte em
        ON em.personid = p.id
)

SELECT
    s.student_number AS student_local_id,
    s.state_studentnumber AS ssid,
    s.first_name AS student_first_name,
    s.last_name AS student_last_name,

    rc1.lastname AS parent_1_last_name,
    rc1.firstname AS parent_1_first_name,
    rc1.relationship AS parent_1_relationship,
    dem.parented AS parent_1_education_level,
    dem.parentcorresplang AS parent_1_language,
    rc1.emailaddress AS parent_1_email,
    rc1.phonenumberasentered AS parent_1_cell_phone,
    rc1.street || CASE WHEN rc1.linetwo IS NOT NULL THEN ' ' || rc1.linetwo END AS parent_1_residential_address,
    rc1.city AS parent_1_residential_city,
    rc1.postalcode AS parent_1_residential_zip_code,

    rc2.lastname AS parent_2_last_name,
    rc2.firstname AS parent_2_first_name,
    rc2.relationship AS parent_2_relationship,
    dem.parented2 AS parent_2_education_level,
    NULL AS parent_2_language,
    rc2.emailaddress AS parent_2_email,
    rc2.phonenumberasentered AS parent_2_cell_phone,
    rc2.street || CASE WHEN rc2.linetwo IS NOT NULL THEN ' ' || rc2.linetwo END AS parent_2_residential_address,
    rc2.city AS parent_2_residential_city,
    rc2.postalcode AS parent_2_residential_zip_code

FROM students s
LEFT JOIN S_CA_STU_X dem
    ON dem.studentsdcid = s.dcid
LEFT JOIN schools sch
    ON sch.school_number = s.schoolid
LEFT JOIN (
    SELECT * FROM ranked_contacts WHERE rn = 1
) rc1
    ON rc1.dcid = s.dcid
LEFT JOIN (
    SELECT * FROM ranked_contacts WHERE rn = 2
) rc2
    ON rc2.dcid = s.dcid
WHERE s.grade_level BETWEEN -1 AND 3
    AND s.schoolid NOT IN ('777777', '888888', '1', '2', '4168890') 
    AND TO_CHAR(s.exitdate, 'YYYY') = :P1_YEAR
ORDER BY s.last_name;