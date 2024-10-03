--PAYMENT_HISTORY
--	Created this to help Carin Hodson with some data...
--	Report needed to choose a thrudate to see what the Statement would look like in the past
--	Guess I might try to make it look like a re-created statement so I will copy from that report.

/*
SELECT * 
FROM VW_RPT_PAYMENT_HISTORY (NOLOCK) 
WHERE COMPANYID = 'SB'
----------------------
AND CUSTOMERID = '10043' 
--and consigneeid = '828834'
--AND TRANSDATE <= '09/01/2024'
----------------------
ORDER BY
	GROUPID, CUSTOMERID, CONSIGNEEID, 
	duepayDATE, TRANSACTIONNUMBER
	--TRANSDATE, TRANSACTIONNUMBER



--UPDATE: CANNOT PROVIDE THESE FIELDS BECAUSE THEY WANT TO SELECT A PAYMENTDATE CUTOFF
--			SO NO REFERENCE DUEDATE CAN BE ESTABLISHED INSIDE THE VIEW TO CALCULATE
--	MIGHT BE ABLE TO GET MAX(PAYMENTDATE) TO REPRESENT A REFERENCE DUEDATE INSIDE THE REPORT???
--	OTHERWISE NO WAY TO GET THERE...

----------STATEMENTS (MIGHT NEED TO STEAL FROM THIS REPORT SO HERE ARE SOME DETAILS)
--------SELECT *, 
--------	IIF(CURRENTDAYSDUE <= 0, BALANCE, 0.00) AS BUCKET1, 
--------	IIF(CURRENTDAYSDUE BETWEEN 1 AND 30, BALANCE, 0.00) AS BUCKET2, 
--------	IIF(CURRENTDAYSDUE BETWEEN 31 AND 60, BALANCE, 0.00) AS BUCKET3, 
--------	IIF(CURRENTDAYSDUE BETWEEN 61 AND 90, BALANCE, 0.00) AS BUCKET4, 
--------	IIF(CURRENTDAYSDUE BETWEEN 91 AND 120, BALANCE, 0.00) AS BUCKET5, 
--------	IIF(CURRENTDAYSDUE > 120, BALANCE, 0.00) AS BUCKET6 
--------FROM VW_RPT_STATEMENT (NOLOCK) 
--------WHERE RECORDTYPE = 'U' 

---------------------------------------------------
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_PAYMENT_HISTORY] 
AS 
SELECT * FROM (
		SELECT 
			WH.COMPANYID, 
			WH.IDENTITYID AS WAREHOUSEID, WH.NAME AS WAREHOUSENAME, 
			CUST.IDGROUP AS GROUPID, 
			CUST.IDENTITYID AS CUSTOMERID, CUST.NAME AS CUSTOMERNAME, 
			CONS.IDENTITYID AS CONSIGNEEID, CONS.NAME AS CONSIGNEENAME, 
			DBO.FN_DATE2PERIOD(OH.TRANSACTIONDATE) AS REPORTPERIOD, 
			DBO.FN_DATE2YEAR(OH.TRANSACTIONDATE) AS REPORTYEAR, 
			'INVOICE' AS AMOUNTTYPE, 
			OH.TRANSACTIONNUMBER, 'PO#: '+OH.PURCHASEORDERNUMBER AS REFERENCE, 
			DBO.FN_ORDERVALUE(OH.ROWID,NULL) AS AMOUNT, 
			0 AS UNAPPLIED, 
			OH.TRANSACTIONDATE AS TRANSDATE, OH.TRANSACTIONDUEDATE AS DUEPAYDATE 
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
		JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
		JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER 
		JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 

		WHERE OH.RECORDTYPE = 'Z' 
		--AND CUST.IDENTITYID = '10043' 
		--ORDER BY 
		--	CUST.IDGROUP, CUST.IDENTITYID, CONS.IDENTITYID, 
		--	OH.TRANSACTIONDUEDATE, OH.TRANSACTIONDATE, OH.TRANSACTIONNUMBER 

		UNION ALL

		SELECT 
			WH.COMPANYID, 
			WH.IDENTITYID AS WAREHOUSEID, WH.NAME AS WAREHOUSENAME, 
			CUST.IDGROUP AS GROUPID, 
			CUST.IDENTITYID AS CUSTOMERID, CUST.NAME AS CUSTOMERNAME, 
			CONS.IDENTITYID AS CONSIGNEEID, CONS.NAME AS CONSIGNEENAME, 
			DBO.FN_DATE2PERIOD(ARPAY.PAYMENTDATE) AS REPORTPERIOD, 
			DBO.FN_DATE2YEAR(ARPAY.PAYMENTDATE) AS REPORTYEAR, 
			'PAYMENT' AS AMOUNTTYPE, 
			OH.TRANSACTIONNUMBER, 'CK#: '+ARPAY.CHECKNUMBER AS REFERENCE, 
			CRD.AMOUNTAPPLIED * -1 AS AMOUNT, 
			ISNULL(CRH.OPENCREDITAMOUNT,0) * -1 AS UNAPPLIED, 
			ARPAY.PAYMENTDATE AS TRANSDATE, ARPAY.PAYMENTDATE AS DUEPAYDATE 
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
		JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
		JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER 
		JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 

		JOIN AROPENITEMHEADER AH (NOLOCK) ON AH.R_SOURCEID = OH.ROWID 
		JOIN ARCASHRECEIPTSDETAIL CRD (NOLOCK) ON CRD.R_AROPENITEMHEADER = AH.ROWID 
		JOIN ARCASHRECEIPTSHEADER CRH (NOLOCK) ON CRH.ROWID = CRD.R_CASHRECEIPTSHEADER
		JOIN ARCASHRECEIPTSPAYMENTS ARPAY (NOLOCK) ON ARPAY.R_ARCASHRECEIPTSHEADER = CRH.ROWID 

		WHERE OH.RECORDTYPE = 'Z' 
		--AND CUST.IDENTITYID = '10043' 
		--ORDER BY 
		--	CUST.IDGROUP, CUST.IDENTITYID, CONS.IDENTITYID, 
		--	ARPAY.PAYMENTDATE, OH.TRANSACTIONNUMBER 
) X
--WHERE  CUSTOMERID = '10043' 
--ORDER BY
--	GROUPID, CUSTOMERID, CONSIGNEEID, 
--	DUEPAYDATE, TRANSDATE, TRANSACTIONNUMBER

----------------------
--	ORIGINAL PLAN	--DON'T WANT TO LOSE THIS WORK JUST YET.
----------------------
/*
SELECT 
	WH.COMPANYID, 
	WH.IDENTITYID AS WAREHOUSEID, WH.NAME AS WAREHOUSENAME, 
	CUST.IDGROUP AS GROUPID, 
	CUST.IDENTITYID AS CUSTOMERID, CUST.NAME AS CUSTOMERNAME, 
	CONS.IDENTITYID AS CONSIGNEEID, CONS.NAME AS CONSIGNEENAME, 
	OH.TRANSACTIONNUMBER, OH.TRANSACTIONTYPE, OH.RECORDTYPE, 
	DBO.FN_ORDERVALUE(OH.ROWID,NULL) AS ORDERTOTAL, OH.TRANSACTIONDATE, OH.TRANSACTIONDUEDATE, 
	CRD.AMOUNTAPPLIED, ARPAY.PAYMENTDATE, 
	CRH.FISCALPERIOD, CRH.FISCALYEAR, CRH.CONTROLAMOUNT, CRH.OPENCREDITAMOUNT, ARPAY.CHECKNUMBER
FROM OMTRANSACTIONHEADER OH (NOLOCK) 
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER 
JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 

JOIN AROPENITEMHEADER AH (NOLOCK) ON AH.R_SOURCEID = OH.ROWID 
JOIN ARCASHRECEIPTSDETAIL CRD (NOLOCK) ON CRD.R_AROPENITEMHEADER = AH.ROWID 
JOIN ARCASHRECEIPTSHEADER CRH (NOLOCK) ON CRH.ROWID = CRD.R_CASHRECEIPTSHEADER
JOIN ARCASHRECEIPTSPAYMENTS ARPAY (NOLOCK) ON ARPAY.R_ARCASHRECEIPTSHEADER = CRH.ROWID 

WHERE OH.RECORDTYPE = 'Z' 
--AND CUST.IDENTITYID = '10043' 
--ORDER BY 
--	CUST.IDGROUP, CUST.IDENTITYID, CONS.IDENTITYID, OH.TRANSACTIONDATE, ARPAY.PAYMENTDATE, ARPAY.CHECKNUMBER 
*/

