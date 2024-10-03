/* WOT: 0:17 (1,784 ROWS) 
--SQL_SALES2GOAL_MAJOR 
SELECT * 
FROM VW_RPT_SQL_SALES2GOAL_MAJOR (NOLOCK) 
WHERE COMPANYID = 'SB' 
AND SALEYEAR = 2024												--RT= 0:10 (429 ROWS)
AND NATIONALACCOUNT = 'Y' 
AND WAREHOUSEID = '10' 
ORDER BY MAJORGROUPNAME, REPORTGROUP, PERIOD, TRANSACTIONDATE	--RT= 0:05 (163 ROWS)--0:14 (2,375 ROWS)
*/ 
CREATE OR ALTER VIEW [DBO].[VW_RPT_SQL_SALES2GOAL_MAJOR] 
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
MAJORGROUPNAME, 
X.CURRAMOUNT, 
ISNULL((SELECT SUM(ISNULL(G.AMOUNT,0)) 
		FROM VW_RPT_SQL_GOALS_MAJOR G (NOLOCK) 
		WHERE G.REPORTGROUP = X.REPORTGROUP
		AND G.SALEYEAR = X.SALEYEAR 
		AND X.PERIOD = 0 --PUT YTD GOAL TOTALS ONLY ON PERIOD = 0 LINES
		AND G.WAREHOUSEID = X.WAREHOUSEID 
		AND G.NATIONALACCOUNT = X.NATIONALACCOUNT 
		AND G.GROUPNAME = X.MAJORGROUPNAME 
		),0) AS GOALAMOUNT 
FROM	(  
		SELECT	REPORTGROUP, 
				SALEYEAR, 
				PERIOD, 
				CAST(TRANSACTIONDATE AS DATE) AS TRANSACTIONDATE, 
				WAREHOUSEID, 
				(SELECT WH.NAME FROM IDMASTER WH (NOLOCK) WHERE WH.IDENTITYID = WAREHOUSEID) AS WAREHOUSENAME, 
				NATIONALACCOUNT, 
				MAJORGROUPNAME, 
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
						--NULL AS GROUPNUMBER, 
						--NULL AS GROUPNAME, 
						IIF	(NATIONALACCOUNT = 'Y', 
							--TRY TWICE TO GET MAJORGROUPNAME, FIRST BY CONSIGNEES PARENT CUSTOMERID, THEN BY CUSTOMER W/O CONSIGNEES TO INCLUDE TAGAWA (829574)
							ISNULL(
									(	SELECT TOP 1 CUST.REFERENCE2 
										FROM IDMASTER CONS (NOLOCK) 
										JOIN IDRELATIONSHIPLINKS LCONS (NOLOCK) ON LCONS.R_IDMEMBER = CONS.ROWID AND LCONS.IDMEMBERTYPE = '02' 
										JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = LCONS.R_IDMASTER 
										WHERE CONS.IDENTITYID = CUSTOMERNUMBER), 
									(	SELECT TOP 1 CUST.REFERENCE2 
										FROM IDMASTER CUST (NOLOCK) 
--I guess this fixes the customers like TAGAWA when other IDTYPES are defined for the customerid:
join IDTYPESLINKS link (nolock) on link.R_IDENTITY = cust.rowid and link.idtype = '01'
										WHERE CUST.IDENTITYID = CUSTOMERNUMBER) 
								),
							NULL) AS MAJORGROUPNAME, 
						--IIF	(NATIONALACCOUNT = 'Y', 
						--	(	SELECT TOP 1 CUST.REFERENCE2 
						--		FROM IDMASTER CONS (NOLOCK) 
						--		JOIN IDRELATIONSHIPLINKS LCONS (NOLOCK) ON LCONS.R_IDMEMBER = CONS.ROWID AND LCONS.IDMEMBERTYPE = '02' 
						--		JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = LCONS.R_IDMASTER 
						--		WHERE CONS.IDENTITYID = CUSTOMERNUMBER), 
						--	NULL) AS MAJORGROUPNAME, 
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
						--G.GROUPNUMBER, 
						--G.GROUPNAME, 
						G.GROUPNAME AS MAJORGROUPNAME, 
						0 AS CURRAMOUNT--,ISNULL(G.AMOUNT,0) AS GOALAMOUNT 
				FROM	VW_RPT_SQL_GOALS_MAJOR G (NOLOCK) 
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
						--NULL AS GROUPNUMBER, 
						--NULL AS GROUPNAME, 
						IIF	(NATIONALACCOUNT = 'Y', 
							--TRY TWICE TO GET MAJORGROUPNAME, FIRST BY CONSIGNEES PARENT CUSTOMERID, THEN BY CUSTOMER W/O CONSIGNEES TO INCLUDE TAGAWA (829574)
							ISNULL(
									(	SELECT TOP 1 CUST.REFERENCE2 
										FROM IDMASTER CONS (NOLOCK) 
										JOIN IDRELATIONSHIPLINKS LCONS (NOLOCK) ON LCONS.R_IDMEMBER = CONS.ROWID AND LCONS.IDMEMBERTYPE = '02' 
										JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = LCONS.R_IDMASTER 
										WHERE CONS.IDENTITYID = CUSTOMERNUMBER), 
									(	SELECT TOP 1 CUST.REFERENCE2 
										FROM IDMASTER CUST (NOLOCK) 
--I guess this fixes the customers like TAGAWA when other IDTYPES are defined for the customerid:
join IDTYPESLINKS link (nolock) on link.R_IDENTITY = cust.rowid and link.idtype = '01'
										WHERE CUST.IDENTITYID = CUSTOMERNUMBER) 
								),
							NULL) AS MAJORGROUPNAME, 
						--IIF	(NATIONALACCOUNT = 'Y', 
						--	(	SELECT TOP 1 CUST.REFERENCE2 
						--		FROM IDMASTER CONS (NOLOCK) 
						--		JOIN IDRELATIONSHIPLINKS LCONS (NOLOCK) ON LCONS.R_IDMEMBER = CONS.ROWID AND LCONS.IDMEMBERTYPE = '02' 
						--		JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = LCONS.R_IDMASTER 
						--		WHERE CONS.IDENTITYID = CUSTOMERNUMBER), 
						--	NULL) AS MAJORGROUPNAME, 
						ISNULL(EC.AMOUNT,0) AS CURRAMOUNT 
				FROM	VW_RPT_SQL_1 EC (NOLOCK) 
				WHERE	EC.SALEYEAR >= DBO.FN_DATE2YEAR(NULL)-1 
				AND		EC.AMOUNT <> 0 AND CUSTOMERNUMBER = 0
				) U 
		GROUP BY
				U.REPORTGROUP, 
				U.SALEYEAR, 
				U.PERIOD, 
				CAST(TRANSACTIONDATE AS DATE), 
				U.WAREHOUSEID, 
				U.NATIONALACCOUNT, 
				U.MAJORGROUPNAME 
		) X 
