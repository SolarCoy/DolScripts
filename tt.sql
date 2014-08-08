SELECT distinct to_char(add_months(b.qtr_end_date, -6),'yyyy') py, b.qtr_end_date report_period, decode(to_char(b.qtr_end_date + 45,'D'), 7, b.qtr_end_date + 47, 1, b.qtr_end_date + 46, b.qtr_end_date + 45) Report_Due_Date, decode((select count(*) from trade_act_particip_2009 tap, taa_report tr where (tap.state_name='NJ' and tap.qtr_end_date=b.qtr_end_date) or (tr.state_abbr='NJ' and tr.qtr_date=b.qtr_end_date)), 0,'Not Submitted', 'Submitted') STATUS, (select decode(date_upd,null,date_ins,date_upd) from taa_report where state_abbr='NJ' and qtr_date=b.qtr_end_date) date_inserted FROM trade_act_particip_exit_date b left join trade_act_particip_2009 a on b.qtr_end_date=a.qtr_end_date and a.state_name='NJ' WHERE b.qtr_end_date between '31-DEC-09' and sysdate union SELECT distinct to_char(add_months(b.qtr_end_date, -6),'yyyy') py, b.qtr_end_date report_period, decode(to_char(b.qtr_end_date + 45,'D'), 7, b.qtr_end_date + 47, 1, b.qtr_end_date + 46, b.qtr_end_date + 45) Report_Due_Date, decode((select count(*) from trade_act_particip_2005 where state='NJ' and qtr_end_date=b.qtr_end_date), 0,'Not Submitted', 'Submitted') STATUS, date_inserted FROM trade_act_particip_exit_date b left join trade_act_particip_2005 a on b.qtr_end_date=a.qtr_end_date and a.state='NJ' WHERE b.qtr_end_date between '31-DEC-05' and '30-SEP-09' union SELECT distinct to_char(add_months(b.qtr_end_date, -6),'yyyy') py, b.qtr_end_date report_period, decode(to_char(b.qtr_end_date + 45,'D'), 7, b.qtr_end_date + 47, 1, b.qtr_end_date + 46, b.qtr_end_date + 45) Report_Due_Date, decode((select count(*) from trade_act_particip where state='NJ' and qtr_end_date=b.qtr_end_date), 0,'Not Submitted', 'Submitted') STATUS, date_inserted FROM trade_act_particip_exit_date b left join trade_act_particip a on b.qtr_end_date=a.qtr_end_date and a.state='NJ' WHERE b.qtr_end_date between '31-DEC-00' and '30-SEP-05' order by 2 desc