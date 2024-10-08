/*
--CREDIT LISTING EXCEL
SELECT * 
FROM VW_RPT_CREDIT_LISTING (NOLOCK) 
WHERE CREDITMANAGERNAME = 'Shelly Cerny' and CUSTOMERID = '10040'--'55276'
ORDER BY
CREDITMANAGERID,
DATEOPENED DESC, 
CUSTOMERID,
TRANSACTIONDATE
--WHERE 1 = 1 
--AND CUSTOMERID = '55276'

*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_CREDIT_LISTING]
AS
SELECT
	X.*, 
	IIF(CURRENTDAYSDUE <= 0, TRANSACTIONBALANCE, 0.00) AS 'CURRENT', 
	IIF(CURRENTDAYSDUE BETWEEN 1 AND 30, TRANSACTIONBALANCE, 0.00) AS '30DAYS', 
	IIF(CURRENTDAYSDUE BETWEEN 31 AND 60, TRANSACTIONBALANCE, 0.00) AS '60DAYS', 
	IIF(CURRENTDAYSDUE BETWEEN 61 AND 90, TRANSACTIONBALANCE, 0.00) AS '90DAYS', 
	IIF(CURRENTDAYSDUE > 91, TRANSACTIONBALANCE, 0.00) AS '120DAYS' 
FROM (
		SELECT 
			CO.COMPANYID, 
			CO.NAME AS COMPANYNAME, 
			CRMGR.IDENTITYID AS CREDITMANAGERID,
			CRMGR.NAME AS CREDITMANAGERNAME,
			VCUST.CUSTOMERIDENTITYID AS CUSTOMERID, 
			VCUST.CUSTOMERNAME, 
			TRIM(VCUST.CUSTOMERIDGROUP) AS CUSTOMERIDGROUP, 
			VCUST.CUSTOMERADDRESSMEMO, 
			VCUST.CUSTOMERADDRESS_1, 
			VCUST.CUSTOMERADDRESS_2, 
			VCUST.CUSTOMERCITY, 
			VCUST.CUSTOMERSTATE, 
			VCUST.CUSTOMERZIP, 
			VCUST.CustomerTelephone_1 AS CUSTOMERPHONE, 
			C1ADDR.TELEPHONE_1 AS PRIMARYCONTACTPHONE, 
			VCUST.CustomerDATEOPENED AS DATEOPENED, 
			VCUST.CustomerCREDITLIMIT AS CREDITLIMIT, 
			VCUST.CustomerHIGHESTSTATEMENTBALANCE AS HIGHESTSTATEMENTBALANCE, 
			(	SELECT MAX(INVOICEDATE) 
				FROM OMTRANSACTIONHEADER OH (NOLOCK)
				JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
				WHERE CUST.IDENTITYID = VCUST.CUSTOMERIDENTITYID
				AND OH.RECORDTYPE = 'Z' AND OH.TRANSACTIONTYPE = 'I' --COMMITTED INVOICES ONLY.
			) AS DATELASTSALE,
			--NULL AS AVGDAYS_TOPAY, 
			OIH.TRANSACTIONTYPE, 
			OIH.TRANSACTIONNUMBER, 
			OIH.DESCRIPTION, 
			OIH.TRANSACTIONDATE, 
			OIH.TRANSACTIONDUEDATE, 
			OIH.RECORDTYPE AS RECORDTYPE, 
	
			(ISNULL(ARINV.AMOUNT,0) - ISNULL(ARINV.AMOUNTAPPLIED_COMMITTED_ONLY,0) - ISNULL(ARINV.DISCOUNTTAKEN_COMMITTED_ONLY,0)) 
				* IIF(OIH.TRANSACTIONTYPE IN ('A','C'), -1, 1) AS TRANSACTIONBALANCE, 
			TERMS.TERMSCODE, 
			TERMS.DESCRIPTION_1 AS TERMS_DESC, 
			GETDATE() AS TODAYSDATE,
			IIF(OIH.RECORDTYPE='U',
				CAST (GETDATE() - OIH.TRANSACTIONDUEDATE AS INT),NULL) AS CURRENTDAYSDUE 
		FROM VW_IDCUSTOMERVIEW VCUST (NOLOCK) 
		LEFT JOIN IDADDRESS C1ADDR (NOLOCK) ON C1ADDR.R_IDENTITY = DBO.FN_GETCONTACT(VCUST.CustomerMasterRowID,'01','C1')
		JOIN IDMASTER CRMGR (NOLOCK) ON CRMGR.ROWID = VCUST.CustomerR_Contact 
		LEFT JOIN IDTERMS TERMS (NOLOCK) ON TERMS.ROWID = VCUST.CUSTOMERR_TERMS
		LEFT JOIN AROPENITEMHEADER OIH (NOLOCK) ON	OIH.R_CUSTOMER = VCUST.CustomerMasterRowID
													--AND OIH.RECORDTYPE = 'U'
		LEFT JOIN VW_ARGETOUTSTANDINGINVOICE ARINV (NOLOCK) ON	ARINV.ROWID = OIH.ROWID	--AND ARINV.ROWID IS NOT NULL
		JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OIH.COMPANYID 
		) X	
--WHERE CREDITMANAGERNAME = 'Shelly Cerny' --CUSTOMERID = '55276'
--ORDER BY
--CREDITMANAGERID,
--DATEOPENED DESC, 
--CUSTOMERID,
--TRANSACTIONDATE



