/* 
--SQL_SALES2GOAL 
SELECT * 
FROM VW_RPT_SQL_SALES2GOAL (NOLOCK) 
WHERE RECORDTYPE <> 'P' 
AND SALEYEAR = '2021' 
--AND MAJORACCOUNT = 'Y' 
AND WAREHOUSEID = '10' 
ORDER BY SALESREPID, SALESREPNAME, REPORTGROUP, PERIOD, TRANSACTIONDATE  
*/ 
CREATE OR ALTER VIEW [DBO].[VW_RPT_SQL_SALES2GOAL] 
AS 
SELECT 
'SB' AS COMPANYID, 
'R' AS RECORDTYPE, 
GETDATE() AS CURRDATE, 
IIF(X.SALEYEAR = DBO.FN_DATE2YEAR(NULL),'Y', NULL) AS ISCURRYEAR, 
X.REPORTGROUP, 
X.SALEYEAR, 
X.PERIOD, 
X.TRANSACTIONDATE, 
-------------------------- 
X.WAREHOUSEID, 
X.WAREHOUSENAME, 
NULLIF(X.NATIONALACCOUNT, 'N') AS NATIONALACCOUNT, 
SALESREPID,
SALESREPNAME,
X.CURRAMOUNT, 
ISNULL((SELECT SUM(ISNULL(G.AMOUNT,0)) 
		FROM VW_RPT_SQL_GOALS G (NOLOCK) 
		WHERE G.REPORTGROUP = X.REPORTGROUP
		AND G.SALEYEAR = X.SALEYEAR 
		AND X.PERIOD = 0 --PUT YTD GOAL TOTALS ONLY ON PERIOD = 0 LINES
		AND G.WAREHOUSEID = X.WAREHOUSEID 
		AND G.NATIONALACCOUNT = X.NATIONALACCOUNT 
		AND G.SALESREPID = X.SALESREPID 
		),0) AS GOALAMOUNT 
FROM	(  
		SELECT	REPORTGROUP, 
				SALEYEAR, 
				PERIOD, 
				CAST(TRANSACTIONDATE AS DATE) AS TRANSACTIONDATE, 
				WAREHOUSEID, 
				(SELECT WH.NAME FROM IDMASTER WH (NOLOCK) WHERE WH.IDENTITYID = WAREHOUSEID) AS WAREHOUSENAME, 
				NATIONALACCOUNT, 
				TRIM(SALESREPID) AS SALESREPID, 
				TRIM(SALESREPNAME) AS SALESREPNAME, 
				SUM (CURRAMOUNT) AS CURRAMOUNT 
        FROM	(	
				--BILLING DATA FROM INSIGHT: 
				SELECT	--C.*, 
						C.REPORTGROUP, 
						C.SALEYEAR, 
						C.PERIOD, 
						C.TRANSACTIONDATE, 
						C.WAREHOUSEID, 
						C.NATIONALACCOUNT, 
						C.SALESREPID, 
						C.SALESREPNAME, 
						ISNULL(C.AMOUNT,0) AS CURRAMOUNT 
				FROM	VW_RPT_SQL_ACTUALS C (NOLOCK) 
				WHERE	C.SALEYEAR >= DBO.FN_DATE2YEAR(NULL)-1 
				AND		C.AMOUNT <> 0 
				UNION ALL 
				--MAJORGOAL DATA FROM INSIGHT: THIS JUST BRINGS IN PLACEHOLDER RECORDS SO GOALS W/O ACTUALS WILL BE INCLUDED. 
				SELECT	--G.*, 
						G.REPORTGROUP, 
						G.SALEYEAR, 
						0 AS PERIOD, 
						NULL AS TRANSACTIONDATE, 
						G.WAREHOUSEID, 
						G.NATIONALACCOUNT, 
						G.SALESREPID, 
						G.SALESREPNAME, 
						0 AS CURRAMOUNT 
				FROM	VW_RPT_SQL_GOALS G (NOLOCK) 
				WHERE	G.SALEYEAR >= DBO.FN_DATE2YEAR(NULL)-1 
				AND		G.AMOUNT <> 0 
				UNION ALL 
				--BILLING DATA FROM ePLANT: 
				SELECT	--EC.*, 
						EC.REPORTGROUP, 
						EC.SALEYEAR, 
						EC.PERIOD, 
						EC.TRANSACTIONDATE, 
						EC.WAREHOUSEID, 
						EC.NATIONALACCOUNT, 
						EC.SALESREPID, 
						EC.SALESREPNAME, 
						ISNULL(EC.AMOUNT,0) AS CURRAMOUNT 
				FROM	VW_RPT_SQL_1 EC (NOLOCK) 
				WHERE	EC.SALEYEAR >= DBO.FN_DATE2YEAR(NULL)-1 
				AND		EC.AMOUNT <> 0 
				) U 
		GROUP BY
				U.REPORTGROUP, 
				U.SALEYEAR, 
				U.PERIOD, 
				CAST(TRANSACTIONDATE AS DATE), 
				U.WAREHOUSEID, 
				U.NATIONALACCOUNT, 
				U.SALESREPID, 
				U.SALESREPNAME 
		) X 
