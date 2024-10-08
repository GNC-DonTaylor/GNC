/*
--125 ROYALTY EXPENSE REPORT
--Needs conversation with Steve Coppedge and Vicki Lake
--Distinct Fee list: Mktg Fee, SubLicense, Admin Fee, License Fee1, License Fee2,LH Fee
SELECT
*
FROM VW_RPT_ROYALTY_EXPENSE (NOLOCK)
WHERE COMPANYID = 'SB'
AND LICPRIMARYHOLDERDESC LIKE 'license%'
ORDER BY INVOICEDATE
AND LICPRIMARYHOLDER LIKE 'SOUTHERN PLANT%'
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_ROYALTY_EXPENSE]
AS

SELECT 
	X.*, 
	X.QTYINVOICED + X.QTYMEMOED AS QTYTOTAL,
	X.LICENSERATE * (X.QTYINVOICED + X.QTYMEMOED) AS LICENSERATETOTAL,
	X.INTERDIVRATE * (X.QTYINVOICED + X.QTYMEMOED) AS INTERDIVRATETOTAL,
	X.SUBLICENSERATE * (X.QTYINVOICED + X.QTYMEMOED) AS SUBLICENSERATETOTAL
FROM (
		SELECT 
			CO.COMPANYID, CO.NAME AS COMPANYNAME, 
			WH.IDENTITYID AS WAREHOUSEID, WH.NAME AS WAREHOUSENAME, 
			OH.STAGE, OH.RECORDTYPE, 
			OH.INVOICEDATE, oh.TRANSACTIONNUMBER,	--added Transactionnumber to assist ROYALTY_FEE_INCOME report.
			OH.TRANSACTIONTYPE, od.LINENUMBER,		--added Linenumber to assist ROYALTY_FEE_INCOME report.
			OD.USERDEFINEDCODE_1 AS CREDITREASONCODE, 
			OD.USERDEFINEDREFERENCE_2 AS NETWORKTEXT, 
			IIF(OH.TRANSACTIONTYPE = 'I', OD.QUANTITYSHIPPED, 0) AS QTYINVOICED, 
			IIF(OH.TRANSACTIONTYPE IN ('C','J') AND LEFT(OD.USERDEFINEDCODE_1,2) = 'FC', OD.QUANTITYSHIPPED * -1, 0) AS QTYMEMOED, 
			IIF(OD.USERDEFINEDREFERENCE_2 LIKE '%NETWORK%', OD.QUANTITYSHIPPED, 0) AS QTYNETWORK, 
			ITM.USERDEFINEDCODE_16 AS LICPRIMARYHOLDER, 
			(SELECT C4.DESCRIPTION_1 FROM IMCODES C4 (NOLOCK) WHERE C4.CODE = ITM.USERDEFINEDCODE_16 AND C4.CODETYPE = 'C4') AS LICPRIMARYHOLDERDESC, 
			ITM.ITEMCODE, ITM.REFERENCE_1 AS COMMONNAME, --NULLIF(ITM.USERDEFINEDREFERENCE_1,'') AS PATENT, 
			ITM.USERDEFINEDCODE_2 AS BRAND, 
			OD.R_FEES, 
			ITMP.PROFILECODE AS VARIETY, ITMP.DESCRIPTION VARIETYDESCRIPTION, 
			CNT.PRINTEDCONTAINERCODE, CNT.CONTAINERCODE, CNT.FREIGHTCLASSCODE, 
			FH.MISCFEECODE, 
			FD.RATE AS LICENSERATE, 
			0 AS INTERDIVRATE, 
			0 AS SUBLICENSERATE, 
			FD.EFFECTIVESTARTDATE, 
			VEND.IDENTITYID AS HOLDERID, VEND.NAME AS HOLDERNAME 
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
			JOIN  OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID 
			JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID 
			JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
			JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM 
			JOIN IMITEMDP ITMP (NOLOCK) ON ITMP.ROWID = ITM.R_PROFILE 
			JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE 
			JOIN IMFEESHEADER FH (NOLOCK) ON FH.ROWID = ITM.R_FEES 
			--DO WE ONLY PAY ROYALTEES AFTER THEY ARE INVOICED? 
			JOIN IMFEESDETAIL FD (NOLOCK) ON FD.R_FEESHEADER = FH.ROWID AND FD.EFFECTIVESTARTDATE <= OH.INVOICEDATE AND FD.DESCRIPTION LIKE 'LICENSE%' 
			JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = FD.R_VENDOR 
		WHERE OH.RECORDTYPE <> 'P' 
		AND LEFT(OH.TRANSACTIONNUMBER,2) != 'IC' --EXCLUDE INTERCOMPANY ORDERS 
		AND WH.IDENTITYID < '999' 
		--AND OD.R_FEES = FH.ROWID --I COMMENTED THIS OUT TO WORK WITH LANDON/MATCH THE CUBE DATA. 
) X 

