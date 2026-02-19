/* LOCATION: web_root/wildcards/d63_spa/el_no_lip.txt
   
   IMPORTANT NOTE ON SYNTAX:
   This file does not follow standard SQL syntax because it uses PowerSchool "Wildcards" (tags inside ~ symbols). 
   PowerSchool processes these tags FIRST, then sends the resulting clean SQL to the database.
*/

(
SELECT 
    s.id,
    s.dcid, 
    s.lastfirst, 
    s.student_number,
    sch.abbreviation AS schoolabbreviation,
    s.grade_level,
    s.track,
    s.entrydate,
    s.exitdate
FROM students s
JOIN S_CA_STU_ELA_C ela ON s.dcid = ela.studentsdcid
LEFT JOIN schools sch ON s.schoolid = sch.school_number
WHERE ~(curschoolid) IN (s.schoolid, s.summerschoolid, 0)

    /* POWERSCHOOL WILDCARD LOGIC:
       The ~[if] tags below are "switches."
       If the preference 'd63spaelnolipschools' is empty, PowerSchool skips this code.
       If it has values, PowerSchool writes the "AND s.schoolid NOT IN..." line into the SQL query 
       dynamically before running it.
    */
    ~[if#IGNORESCHOOLS.~[pref:d63spaelnolipschools]=]
        /* If the 'Exclude Schools' setting is empty, do nothing */
    [else#IGNORESCHOOLS]
        /* If it's NOT empty, inject this filter into the SQL query */
        AND s.schoolid NOT IN (~[pref:d63spaelnolipschools])
    [/if#IGNORESCHOOLS]

    /* Switch for including/excluding Pre-Registered students based on user preference */
    ~[if#INCLUDEPREREG.~[pref:d63spaelnolipprereg]>=1]
        AND s.enroll_status IN (0,-1) 
        ~[if#INCLUDEPREREGCURRENT.~[pref:d63spaelnolipprereg]=1]
            AND s.entrydate < TO_DATE('~(date.information;type=current_year_end)','~[dateformat]')
        [/if#INCLUDEPREREGCURRENT]
    [else#INCLUDEPREREG]
        AND s.enroll_status = 0
    [/if#INCLUDEPREREG]

    /* The actual Database search logic */
    AND ela.ELASTATUS = 'EL'
    AND (ela.ELASTATUSENDDATE IS NULL OR ela.ELASTATUSENDDATE > CURRENT_DATE)
    AND s.dcid NOT IN (
        SELECT studentsdcid 
        FROM S_CA_STU_CALPADSPROGRAMS_C 
        WHERE PROGRAMCODE IN ('300','301','302','303','304','305','306','307')
          AND (ENDDATE IS NULL OR ENDDATE > CURRENT_DATE)
    )
)