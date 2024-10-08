/*
--============-- 
--= CALENDAR =-- 
--============-- 
SELECT 
* 
FROM VW_RPT_CALENDAR (NOLOCK) 
WHERE COMPANYID = 'SB' 
------- 
ORDER BY RPTYEAR, RPTPERIOD, RPTWEEK 
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_CALENDAR]
AS
SELECT 
	'SB' AS COMPANYID, 
	RPTYEAR, RPTPERIOD, RPTWEEK,
	WSTART AS SUNDAY, 
	WSTART+1 AS MONDAY, 
	WSTART+2 AS TUESDAY, 
	WSTART+3 AS WEDNESDAY, 
	WSTART+4 AS THURSDAY, 
	WSTART+5 AS FRIDAY, 
	WSTART+6 AS SATURDAY
FROM (
		SELECT 
			Y.RPTYEAR, P.RPTPERIOD, W.RPTWEEK, 
			DBO.FN_YEAR2DATE(Y.RPTYEAR) AS YSTART, 
			DBO.FN_YEAR2DATE(Y.RPTYEAR)+(28*(P.RPTPERIOD-1)) AS PSTART, 
			DBO.FN_YEAR2DATE(Y.RPTYEAR)+(28*(P.RPTPERIOD-1))+(7*(W.RPTWEEK-1)) AS WSTART, 
			DBO.FN_YEAR2DATE(Y.RPTYEAR)+(28*(P.RPTPERIOD-1))+(7*(W.RPTWEEK))-1 AS WEND, 
			IIF(RPTPERIOD < 13, DBO.FN_YEAR2DATE(Y.RPTYEAR)+(28*(P.RPTPERIOD))-1, 
								DBO.FN_YEAR2DATE(Y.RPTYEAR+1)-1) AS PEND, 
			DBO.FN_YEAR2DATE(Y.RPTYEAR+1)-1 AS YEND
	
		FROM (SELECT TOP 50 2008+ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTYEAR FROM MASTER..spt_values (NOLOCK)) Y
		JOIN (SELECT TOP 13 ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTPERIOD FROM MASTER..spt_values (NOLOCK)) P ON 1=1 
		JOIN (SELECT TOP 5 ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTWEEK FROM MASTER..spt_values (NOLOCK)) W 
			ON	(RPTPERIOD < 13 AND RPTWEEK < 5) OR 
				(RPTPERIOD = 13 AND DBO.FN_YEAR2DATE(Y.RPTYEAR)+(28*(RPTPERIOD-1))+(7*(W.RPTWEEK))-1 < DBO.FN_YEAR2DATE(Y.RPTYEAR+1))
	) X
