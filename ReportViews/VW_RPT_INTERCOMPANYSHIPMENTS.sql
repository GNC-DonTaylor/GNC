/* RUNTIME- 1:35--1:00 
--INTERCOMPANY SHIPMENTS 

SELECT * 
FROM VW_RPT_INTERCOMPANYSHIPMENTS (NOLOCK) 
WHERE COMPANYID = 'SB' 
-------------------------------------
AND TRANSACTIONDATE BETWEEN '09/01/2020' AND '08/31/2021' 
*/ 
CREATE OR ALTER VIEW [DBO].[VW_RPT_INTERCOMPANYSHIPMENTS] 
AS 
SELECT 
	CO.COMPANYID,
	WH.IDENTITYID AS SHIPPINGWAREHOUSEID, 
	--WH.NAME AS WAREHOUSENAME, 
	CONS.IDENTITYID AS RECEIVINGWAREHOUSEID, 
	CONS.NAME AS RECEIVINGWAREHOUSENAME, 
	DBO.FN_SALEYEAR(OH.INVOICEDATE) AS SALEYEAR,
	OH.TRANSACTIONNUMBER,
	ITM.ITEMCODE,
	ITM.REFERENCE_1 AS COMMONNAME, 
	ITM.DESCRIPTION_2 AS ABBREVBOTANICALNAME, 
	OD.QUANTITYSHIPPED, 
	OD.UNITPRICE, 
	OH.INVOICEDATE AS TRANSACTIONDATE, 
	DBO.FN_DATE2YEAR(OH.INVOICEDATE) AS REPORTYEAR, 
	DBO.FN_DATE2PERIOD(OH.INVOICEDATE) AS REPORTPERIOD, 
	DBO.FN_DATE2WEEK(OH.INVOICEDATE) AS REPORTWEEK, 
	DATEPART(DW, OH.INVOICEDATE) AS REPORTDAYOFWEEK 
FROM OMTRANSACTIONHEADER OH (NOLOCK) 
	JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID 
	JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
	JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 
	JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM 
	JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID
WHERE OH.RECORDTYPE='Z' --COMMITTED RECORDS ONLY 
AND SUBSTRING(OH.TRANSACTIONNUMBER,1,2)='IC' --INTERCOMPANY ORDERS ONLY 

UNION ALL

SELECT 
	'SB' AS COMPANYID, 
	ePLANT.*
FROM GNC_INTERCOMPANYSHIPMENTS ePLANT (NOLOCK)
