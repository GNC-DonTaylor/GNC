/*
--============-- 
--= SALES_CALENDAR =-- 
--============-- 
SELECT 
* 
FROM VW_RPT_SALES_CALENDAR (NOLOCK) 
WHERE COMPANYID = 'SB' 
-------
ORDER BY Y1, RPTPERIOD, RPTWEEK 
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_SALES_CALENDAR]
AS
SELECT 
	'SB' AS COMPANYID, 
	DBO.FN_DATE2YEAR(NULL) AS CURRYEAR, 
	DBO.FN_DATE2PERIOD(NULL) AS CURRPERIOD, 
	DBO.FN_DATE2WEEK(NULL) AS CURRWEEK, 
	CAST (GETDATE() AS DATE) AS CURRDATE, 
	RPTYEAR-1 AS Y0, 
	RPTYEAR AS Y1, 
	RPTYEAR+1 AS Y2, 
	RPTYEAR+2 AS Y3, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR) AS DATE) AS Y1DATE, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+1) AS DATE) AS Y2DATE, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+2) AS DATE) AS Y3DATE, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+3) AS DATE) AS Y4DATE, 
	RPTPERIOD, RPTWEEK, 
	CASE 
		WHEN RPTPERIOD < 7 THEN 'FALL SEASON'
		WHEN RPTPERIOD > 11 THEN 'SUMMER SEASON'
		ELSE 'SPRING SEASON' 
	END AS RPTSEASON, 
	(RPTPERIOD-1)*4+RPTWEEK AS RPTWEEKNUM, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR)+(28*(RPTPERIOD-1))+(7*(RPTWEEK-1)) AS DATE) AS Y1WKDATE, 	
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+1)+(28*(RPTPERIOD-1))+(7*(RPTWEEK-1)) AS DATE) AS Y2WKDATE, 	
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+2)+(28*(RPTPERIOD-1))+(7*(RPTWEEK-1)) AS DATE) AS Y3WKDATE 
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
	
		FROM (SELECT TOP 50 2010+ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTYEAR FROM MASTER..spt_values (NOLOCK)) Y
		JOIN (SELECT TOP 13 ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTPERIOD FROM MASTER..spt_values (NOLOCK)) P ON 1=1 
		JOIN (SELECT TOP 5 ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTWEEK FROM MASTER..spt_values (NOLOCK)) W 
			ON	(RPTPERIOD < 13 AND RPTWEEK < 5) OR 
				(RPTPERIOD = 13) 
				--NOT NEEDED, THIS IS HANDLED IN THE REPORT INSTEAD FOR EACH OF THE THREE YEARS.
				-- AND DBO.FN_YEAR2DATE(Y.RPTYEAR)+(28*(RPTPERIOD-1))+(7*(W.RPTWEEK))-1 < DBO.FN_YEAR2DATE(Y.RPTYEAR+1))
	) X

--OLD CODE--
/*
SELECT 
	'SB' AS COMPANYID, 
	RPTYEAR-1 AS Y0, 
	RPTYEAR AS Y1, 
	RPTYEAR+1 AS Y2, 
	RPTYEAR+2 AS Y3, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR) AS DATE) AS Y1DATE, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+1) AS DATE) AS Y2DATE, 
	CAST (DBO.FN_YEAR2DATE(RPTYEAR+2) AS DATE) AS Y3DATE 
FROM (SELECT TOP 100 2010+ROW_NUMBER() OVER(ORDER BY NUMBER) AS RPTYEAR FROM MASTER..SPT_VALUES (NOLOCK)) Y 
*/
