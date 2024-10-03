/* RUNTIME: 4:11 
--BILLING_GOALS	
SELECT *, 
NULL AS BREAKON, 
'Consolidated' AS BREAKONTEXT 
FROM VW_RPT_BILLING_GOALS (NOLOCK) 
WHERE COMPANYID = 'SB' 
and saleyear = 2023
--ALTERNATE TEST FILTER: 
--AND TRANSACTIONDATE BETWEEN '8/1/2021' AND '5/9/2022' -->[RECORD SEASON RT:15:14 (71,728 ROWS) WITH CAST DATETIME AS DATE:14:57]

--TEST FILTERS: 
AND ISCURRYEAR = 'Y' 
AND ISCURRPERIOD = 'Y' -->[RECORD SEASON RT:16:17 (36,569 ROWS) WITH CAST DATETIME AS DATE:15:29]
AND TRANSACTIONDATE BETWEEN '8/1/2021' AND '5/9/2022' -->[RECORD SEASON RT:15:32 (36,113 ROWS) WITH CAST DATETIME AS DATE:15:35]

SELECT * 
P.NATIONALACCOUNT AS BREAKON, 
IIF(P.NATIONALACCOUNT = 'Y', 'Major Accts', 'Independents') AS BREAKONTEXT 
FROM VW_RPT_BILLING_GOALS (NOLOCK) 
WHERE COMPANYID = 'SB' 

--BILLING_GOALS_M 
SELECT *, 
NATIONALACCOUNT AS BREAKON, 
IIF(NATIONALACCOUNT = 'Y', 'Major Accts', 'Independents') AS BREAKONTEXT 
FROM VW_RPT_BILLING_GOALS (NOLOCK) 
WHERE COMPANYID = 'SB' 
--TEST FILTERS: 
AND ISCURRYEAR = 'Y' 
AND ISCURRPERIOD = 'Y' 

--BILLING_GOALS_S 
SELECT *, 
SALESREPID + NATIONALACCOUNT AS BREAKON, 
SALESREPID + ' - ' + SALESREPNAME + IIF(NATIONALACCOUNT = 'Y', '  (Major Accts)', '  (Independents)') AS BREAKONTEXT 
FROM VW_RPT_BILLING_GOALS (NOLOCK) 
WHERE COMPANYID = 'SB' 
--TEST FILTERS: 
AND ISCURRYEAR = 'Y' 
AND ISCURRPERIOD = 'Y' 

*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_BILLING_GOALS]
AS
SELECT U.* 
FROM	(
		----------------------------------
		-- THIS IS THE PERIODIC DATASET --
		----------------------------------
		SELECT 
		NULL AS ISYTD,		--PERIODTODATE
		P.ISCURRYEAR,
		P.ISCURRPERIOD,
--------------------------
		P.RECORDTYPE,
		P.COMPANYID,
		P.SALEYEAR,
		P.PERIOD,
--------------------------
		P.TRANSACTIONDATE,
		P.REPORTNET,
		P.REPORTGROSS,
		P.REPORTGROUP,
		P.REPORTLINE,
		P.REPORTNETDESC,
		P.REPORTGROSSDESC,
		P.REPORTGROUPDESC,
		P.REPORTLINEDESC,
		P.WAREHOUSEID,
		--UNIFYING WAREHOUSENAME USING INSIGHT DATA:
		(	SELECT WH.NAME 
			FROM IDMASTER WH (NOLOCK) 
			WHERE WH.IDENTITYID = P.WAREHOUSEID
			) AS WAREHOUSENAME,
		P.NATIONALACCOUNT,
		P.SALESREPID,
		P.SALESREPNAME,
		P.CURRAMOUNT,
		P.CURRAMOUNT10,
		P.CURRAMOUNT20,
		P.CURRAMOUNT40,
		P.CURRAMOUNT60,
		P.GOALAMOUNT,
		P.GOALAMOUNT10,
		P.GOALAMOUNT20,
		P.GOALAMOUNT40,
		P.GOALAMOUNT60
		FROM VW_RPT_SQL_BILLING_GOALS P (NOLOCK)
		--PEOPLE KEEP COMPLAINING THAT TRENDS != GOALS EVER SINCE DJ ASKED ME TO COMMENT OUT THIS LINE...TURNING IT BACK ON TO SEE IF IT FIXES THINGS:
		WHERE P.TRANSACTIONDATE <= GETDATE()

		UNION ALL

		--------------------------------
		-- THIS IS THE YEARLY DATASET --
		--------------------------------
		SELECT 
		'Y' AS ISYTD,		--YTD
		Y.ISCURRYEAR,
		'Y' AS ISCURRPERIOD, -- 'Y' FOR YTD TOTALS:
--------------------------
		Y.RECORDTYPE,
		Y.COMPANYID,
		Y.SALEYEAR,
		0 AS PERIOD,		--ZERO FOR YTD TOTALS:
--------------------------
		Y.TRANSACTIONDATE,
		Y.REPORTNET,
		Y.REPORTGROSS,
		Y.REPORTGROUP,
		Y.REPORTLINE,
		Y.REPORTNETDESC,
		Y.REPORTGROSSDESC,
		Y.REPORTGROUPDESC,
		Y.REPORTLINEDESC,
		Y.WAREHOUSEID,
		--UNIFYING WAREHOUSENAME USING INSIGHT DATA:
		(	SELECT WH.NAME 
			FROM IDMASTER WH (NOLOCK) 
			WHERE WH.IDENTITYID = Y.WAREHOUSEID
			) AS WAREHOUSENAME,
		Y.NATIONALACCOUNT,
		Y.SALESREPID,
		Y.SALESREPNAME,
		Y.CURRAMOUNT,
		Y.CURRAMOUNT10,
		Y.CURRAMOUNT20,
		Y.CURRAMOUNT40,
		Y.CURRAMOUNT60,
		Y.GOALAMOUNT,
		Y.GOALAMOUNT10,
		Y.GOALAMOUNT20,
		Y.GOALAMOUNT40,
		Y.GOALAMOUNT60
		FROM VW_RPT_SQL_BILLING_GOALS Y (NOLOCK)
		--PEOPLE KEEP COMPLAINING THAT TRENDS != GOALS EVER SINCE DJ ASKED ME TO COMMENT OUT THIS LINE...TURNING IT BACK ON TO SEE IF IT FIXES THINGS:
		WHERE Y.TRANSACTIONDATE <= GETDATE()
		) U
