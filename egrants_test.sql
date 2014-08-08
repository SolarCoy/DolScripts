/* Formatted on 3/21/2011 5:02:48 PM (QP5 v5.163.1008.3004) */
SET TERM ON
SET HEAD OFF
SET FEED OFF
SET PAGESIZE 500
SPOOL ON

SPOOL C:\grantee_award_dataset.csv

--spool C:\grantee_award_dataset.TXT

SELECT    '"'
       || a.GK_NO
       || '","'
       || a.AMT
       || '","'
       || a.PROJ_TITLE
       || '"
            ,"'
       || ir.INSTRMNT_TYPE_DSCR
       || '","'
       || a.FY
       || '","'
       || a.PROJECT_TYPE_ID
       || '"
            ,"'
       || a.ACT
       || '","'
       || r.RCIP_NO
       || '","'
       || r.RCIP_NAME
       || '","'
       || st.STATE_NAME
       || '","'
       || ap.PROJ_CONG_DISTRICT
       || '","'
       || r.ADDR1
       || '","'
       || r.ADDR2
       || '","'
       || r.CITY
       || '","'
       || r.CITY_CD
       || '","'
       || r.COUNTY
       || '","'
       || r.COUNTY_CD
       || '","'
       || st.STATE_ABBRV
       || '","'
       || COUNTRY
       || '","'
       || r.ZIP
       || '","'
       || rg.RGN_NAME
       || '","'
       || rg.RGN_TITLE
       || '","'
       || a.SOLICITATION_ID
       || '","'
       || a.CFDA
       || '","'
       || a.CMMNT
       || '","'
       || TO_CHAR (g.PRPSD_CLOSEOUT, 'MM/DD/YYYY')
       || '","'
       || TO_CHAR (g.ACCEPT_CLOSEOUT, 'MM/DD/YYYY')
       || '","'
       || TO_CHAR (a.min_date, 'MM/DD/YYYY')
       || '","'
       || TO_CHAR (a.max_date, 'MM/DD/YYYY')
       || '","'
       || c.last_name
       || '","'
       || c.first_name
       || '"'
  FROM GTS_GK g,
       gts_gk_mod m,
       GRANT_APP_424 ap,
       CFR_GK_FPO c,
       RCIP_ORG1 r,
       PRG_REF pr,
       STATE_REF st,
       RGN_REF rg,
       INSTRMNT_TYPE_REF ir,
       (  SELECT REPLACE (g.gk_no, '-') gk_no,
                 g.fy,
                 g.act,
                 g.cfda,
                 g.PROJ_TITLE,
                 g.PROJECT_TYPE_ID,
                 rcip_office_id,
                 PRG_ID,
                 g.CMMNT,
                 g.INSTRMNT_TYPE_ID,
                 g.SOLICITATION_ID,
                 DECODE (accept_closeout, NULL, 'Open', 'Closed') closeout,
                 MAX (md.end_date) OVER (PARTITION BY g.gk_no) max_date,
                 MIN (md.begin_date) OVER (PARTITION BY g.gk_no) min_date,
                 SUM (mod_amt) amt
            FROM gts_gk g, gts_gk_mod m, gk_mod_details md
           WHERE     m.gts_gk_mod_id = md.gts_gk_mod_id
                 AND m.gts_gk_cntl_no = g.gts_gk_cntl_no
                 AND md.hhs_cd IS NOT NULL
        GROUP BY gk_no,
                 PROJ_TITLE,
                 accept_closeout,
                 g.fy,
                 g.act,
                 g.cfda,
                 g.PROJECT_TYPE_ID,
                 begin_date,
                 rcip_office_id,
                 PRG_ID,
                 CMMNT,
                 INSTRMNT_TYPE_ID,
                 SOLICITATION_ID,
                 end_date) a
 WHERE     a.gk_no = c.gk_no
       AND a.gk_no = g.gk_no
       AND ap.gts_gk_mod_id = m.gts_gk_mod_id
       AND r.STATE_ID = st.STATE_ID
       AND r.rcip_office_id = a.rcip_office_id
       AND a.INSTRMNT_TYPE_ID = ir.INSTRMNT_TYPE_ID
       AND st.RGN_ID = rg.RGN_ID
       AND a.PRG_ID = pr.PRG_ID;

