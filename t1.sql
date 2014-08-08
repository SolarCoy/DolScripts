set term on
set head off 
set feed off
spool on 
spool grant_award_mod_dataset.csv`
SELECT        
	    g.gk_no||','||
            MOD_NO||','||
            MOD_AMT||','||
            to_char(MOD_BEGIN_DATE,'MM/DD/YYYY')||','||
            to_char(MOD_END_DATE,'MM/DD/YYYY')||','||            
            to_char(m.EFFECTIVE_DATE,'MM/DD/YYYY')||','||
            m.PROCESS_STATUS||','||
            MOD_TYPE_ID||','||
            par.PAR_NO||','||
            MOD_AMT||','||
            wdip.FY||','||
            wdip.HHS_CODE
     FROM   gts_gk g,
            gts_gk_mod m,
            gk_mod_details md,        
            par, 
            wdip
    WHERE       m.gts_gk_mod_id = md.gts_gk_mod_id
            AND m.gts_gk_cntl_no = g.gts_gk_cntl_no
            AND md.PAR_ID = par.par_id
            AND md.wdip_id = wdip.wdip_id;          
spool off;
