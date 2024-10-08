/*
--Grp Avg DaysToPay-Detail EXCEL
SELECT * 
FROM VW_RPT_DAYSTOPAY (NOLOCK) 
WHERE COMPANYID = 'SB' 

--Grp Avg DaysToPay EXCEL
SELECT *, 
	IIF(YEARCOLUMN = 1, DAYSTOPAY, NULL) AS PYDTP1, 
	IIF(YEARCOLUMN = 2, DAYSTOPAY, NULL) AS PYDTP2, 
	IIF(YEARCOLUMN = 3, DAYSTOPAY, NULL) AS PYDTP3, 
	IIF(YEARCOLUMN = 4, DAYSTOPAY, NULL) AS PYDTP4 
FROM VW_RPT_DAYSTOPAY (NOLOCK) 
WHERE YEARCOLUMN BETWEEN 1 AND 4 
AND TRANSACTIONTYPE = 'I' 


----------------------
AND GROUPID = '19'
--AND TRANSACTIONDATE <= '09/01/2024'
----------------------
ORDER BY
	GROUPID, MCCUSTOMERID, CUSTOMERID, TRANSACTIONNUMBER
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_DAYSTOPAY] 
AS 
SELECT 'SB' AS COMPANYID, 
	X.GROUPID, X.GROUPNAME, X.MCCUSTOMERID, X.CUSTOMERID, X.CUSTOMERNAME, X.TRANSACTIONNUMBER, X.TRANSACTIONTYPE, X.TRANSACTIONDATE, 
	DATEPART(YEAR, DATEADD(month,4,X.TRANSACTIONDATE)) AS FISCALYEAR, 
	DATEPART(YEAR, DATEADD(month,4,GETDATE())) - DATEPART(YEAR, DATEADD(month,4,X.TRANSACTIONDATE)) AS YEARCOLUMN, 
	ISNULL(X.MERCHAMT,0) AS MERCHAMT, 
	ISNULL(X.FREIGHTAMT,0) AS FREIGHTAMT, 
	ISNULL(X.UNKNOWNAMT,0) AS UNKNOWNAMT, 
	ISNULL(X.MERCHAMT,0) + ISNULL(X.FREIGHTAMT,0) + ISNULL(X.UNKNOWNAMT,0) AS TOTAL, 
	SUM(X.AMOUNTPAID) AS AMOUNTPAID, 
	(ISNULL(X.MERCHAMT,0) + ISNULL(X.FREIGHTAMT,0) + ISNULL(X.UNKNOWNAMT,0)) - SUM(X.AMOUNTPAID) AS BALANCE, 
	SUM(X.DAYSTOPAY) AS DAYSTOPAY, 
	SUM(X.DAYSTOPAY*X.AMOUNTPAID)/SUM(X.AMOUNTPAID) AS WEIGHTEDDAYSTOPAY
FROM (
		SELECT 
			--TRIM(CUST.IDGROUP) AS GROUPID, 
			CAST (CUST.IDGROUP AS INT) AS GROUPID, 
			TRIM(GRP.DESCRIPTION_1) AS GROUPNAME, 
			TRIM(MCCUST.IDENTITYID) AS MCCUSTOMERID, 
			TRIM(CUST.IDENTITYID) AS CUSTOMERID, 
			TRIM(CUST.NAME) AS CUSTOMERNAME, 
			CRH.DATERECEIVED, 
			IIF(OIH.TRANSACTIONTYPE IN ('A', 'C'), -1, 1) *
			ISNULL(CRD.AMOUNTAPPLIED,0) + ISNULL(CRD.DISCOUNTTAKEN,0) AS AMOUNTPAID, 
			TRIM(OIH.TRANSACTIONNUMBER) AS TRANSACTIONNUMBER, 
			OIH.TRANSACTIONTYPE, 
			OIH.TRANSACTIONDATE, 
			IIF(OIH.TRANSACTIONTYPE IN ('A', 'C'), -1, 1) *
			(	SELECT SUM(ISNULL(AMOUNT,0)) 
				FROM  AROPENITEMDETAIL OID (NOLOCK) 
				WHERE OID.R_AROPENITEM = OIH.ROWID 
				AND OID.R_CAACTIVITY IS NULL	--ONLY PICKUP MERCH AMTS
			)	AS MERCHAMT, 
			IIF(OIH.TRANSACTIONTYPE IN ('A', 'C'), -1, 1) *
			(	SELECT SUM(ISNULL(AMOUNT,0)) 
				FROM  AROPENITEMDETAIL OID (NOLOCK) 
				WHERE OID.R_AROPENITEM = OIH.ROWID 
				AND OID.R_CAACTIVITY = '4AC7AE85-576D-4C28-9ADA-9FAA2E1FF8E7'	--ONLY PICKUP FREIGHT AMTS
			)	AS FREIGHTAMT, 
			IIF(OIH.TRANSACTIONTYPE IN ('A', 'C'), -1, 1) *
			(	SELECT SUM(ISNULL(AMOUNT,0)) 
				FROM  AROPENITEMDETAIL OID (NOLOCK) 
				WHERE OID.R_AROPENITEM = OIH.ROWID 
				AND OID.R_CAACTIVITY = '00000000-0000-0000-0000-000000000000'	--ONLY PICKUP UNKNOWN AMTS
			)	AS UNKNOWNAMT, 
			ISNULL(DATEDIFF(DAY, OIH.TRANSACTIONDATE, CRH.DATERECEIVED),0) AS DAYSTOPAY
		FROM ARCASHRECEIPTSHEADER CRH (NOLOCK) 
		JOIN ARCASHRECEIPTSDETAIL CRD (NOLOCK) ON CRD.R_CASHRECEIPTSHEADER = CRH.ROWID
										   AND CRD.COMPANYID = 'SB'
										   AND CRD.RECORDTYPE IN ('R','U','Z')
										   AND CRD.MODULE = 'AR'
		JOIN AROPENITEMHEADER OIH (NOLOCK) ON OIH.ROWID = CRD.R_AROPENITEMHEADER
											AND OIH.COMPANYID = 'SB'
											AND OIH.RECORDTYPE IN ('R','U','Z')
											AND OIH.MODULE = 'AR'
		JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OIH.R_CUSTOMER 
		LEFT JOIN IDCODES GRP (NOLOCK) ON GRP.CODE = CUST.IDGROUP AND GRP.CODETYPE = 'Z7'	--CUSTOMERGROUPNAME
		LEFT JOIN IDMASTER MCCUST (NOLOCK) ON MCCUST.ROWID = DBO.FN_MASTERCUSTOMER(OIH.R_CUSTOMER,'INCLUSIVE')
		WHERE  CRH.COMPANYID = 'SB'
		   AND CRH.RECORDTYPE IN ('R','U','Z')
--TESTVALUES:
--AND OIH.TRANSACTIONNUMBER = '10-24578-1'

) X
--TESTRANGE:
--WHERE DATERECEIVED <= GETDATE()-30
GROUP BY
	X.GROUPID, X.GROUPNAME, X.MCCUSTOMERID, X.CUSTOMERID, X.CUSTOMERNAME, X.TRANSACTIONNUMBER, X.TRANSACTIONTYPE, X.TRANSACTIONDATE, X.MERCHAMT, X.FREIGHTAMT, X.UNKNOWNAMT
