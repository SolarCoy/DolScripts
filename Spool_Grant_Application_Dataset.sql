set term off
set head off
set feed off
set truncate off
spool on
spool c:\grant_application_dataset.csv

select  '"'||ap.OPP_ID||'","'||
    ap.APP_ID||'","'||
    g.GK_NO||'","'||
    ap.SUB_TYPE||'","'||
    ap.APPLICATION_TYPE||'","'||
    to_char(ap.RCVD_DATE,'MM/DD/YYYY')||'","'||
    ap.APPLICANT_ID||'","'||
    ap.FED_ENTITY_ID||'","'||
    ap.FED_AWARD_ID||'","'||
    to_char(ap.STATE_RCVD_DATE,'MM/DD/YYYY')||'","'||
    ap.STATE_APP_ID||'","'||
    ap.ORG_NAME||'","'||
    ap.EMPLOYER_ID||'","'||
    ap.DUNS||'","'||
    ap.STREET1||'","'||
    ap.STREET2||'","'||
    ap.CITY||'","'||
    ap.COUNTY||'","'||
    ap.STATE||'","'||
    ap.PROVINCE||'","'||
    ap.COUNTRY||'","'||
    ap.ZIP||'","'||
    ap.DEPT||'","'||
    ap.DIVISION||'","'||
    ap.CONT_NAME_PREFIX||'","'||
    ap.CONT_FIRST_NAME||'","'||
    ap.CONT_MID_NAME||'","'||
    ap.CONT_LAST_NAME||'","'||
    ap.CONT_NAME_SUFFIX||'","'||
    ap.CONT_TITLE||'","'||
    ap.CONT_ORG_AFFIL||'","'||
    ap.CONT_PHONE||'","'||
    ap.CONT_FAX||'","'||
    ap.CONT_EMAIL||'","'||
    ap.APPLICANT_TYPE_1||'","'||
    ap.APPLICANT_TYPE_2||'","'||
    ap.APPLICANT_TYPE_3||'","'||
    substr(ap.APPLICANT_OTHER_EXPLANATION,1,300)||'","'||
    trim(ap.FED_AGENCY_NAME)||'","'||
    ap.CFDA||'","'||
    ap.CFDA_TITLE||'","'||
    ap.FUND_OPP_NUM||'","'||
    ap.FUND_OPP_TITLE||'","'||
    ap.COMPETITION_ID||'","'||
    ap.COMPETITION_TITLE||'","'||
    substr(ap.AREAS_AFFECTED,1,200)||'","'||
    substr(ap.PROJ_TITLE,1,100)||'","'||
    substr(ap.APP_CONG_DISTRICT,1,100)||'","'||
    substr(ap.PROJ_CONG_DISTRICT,1,100)||'","'||
    to_char(ap.PROPOSED_START_DATE,'MM/DD/YYYY')||'","'||
    to_char(ap.PROPOSED_END_DATE,'MM/DD/YYYY')||'","'||
    ap.FED_EST_AMT||'","'||
    ap.APPLICANT_EST_AMT||'","'||
    ap.STATE_EST_AMT||'","'||
    ap.LOCAL_EST_AMT||'","'||
    ap.OTHER_EST_AMT||'","'||
    ap.INCOME_EST_AMT||'","'||
    ap.TOTAL_EST_AMT||'","'||
    ap.STATE_REVIEW_CODE||'","'||
    to_char(ap.STATE_REVIEW_DATE,'MM/DD/YYYY')||'","'||
    ap.DFD_INDICATOR||'","'||
    substr(ap.DFD_EXPLANATION,1,200)||'","'||
    ap.CERTIF_AGREE||'","'||
    ap.REP_NAME_PREFIX||'","'||
    trim(ap.REP_FIRST_NAME)||'","'||
    trim( ap.REP_MID_NAME)||'","'||
    trim( ap.REP_LAST_NAME)||'","'||
    ap.REP_NAME_SUFFIX||'","'||
    substr(ap.REP_TITLE,1,100)||'","'||
    ap.REP_PHONE||'","'||
    ap.REP_FAX||'","'||
    trim(ap.REP_EMAIL)||'","'||
    to_char(ap.SIGN_DATE,'MM/DD/YYYY')||'"' as records 
From GRANT_APP_424 ap LEFT OUTER JOIN GTS_GK_MOD m ON ap.GTS_GK_MOD_ID = m.GTS_GK_MOD_ID
    LEFT OUTER JOIN GTS_GK g ON m.GTS_GK_CNTL_NO = g.GTS_GK_CNTL_NO
order by records asc;

spool off;