/*	????????????????NOT BEING USED??????????????????-->See VW_RPT_CUSTOMER_RETAIL_SKU instead
--23 MISSING RETAIL & SKU
SELECT
*
FROM VW_RPT_MISSING_RETAIL_SKU (NOLOCK)
WHERE VW_RPT_MISSING_RETAIL_SKU.RECORDTYPE <> 'P'
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_MISSING_RETAIL_SKU]
AS
SELECT
CO.COMPANYID,
CO.NAME AS COMPANYNAME,
WH.IDENTITYID AS WAREHOUSEID,
WH.NAME AS WAREHOUSENAME,
PSH.PRICESCHEDULECODE,
PART.IDENTITYID AS SALESREPID,
PART.NAME AS SALESREPNAME,
CUST.IDENTITYID AS CUSTOMERID,
CUST.NAME AS CUSTOMERNAME,
OH.RECORDTYPE AS RECORDTYPE,
--added Stage and Step fields:
OH.STAGE AS STAGE,
SUBSTRING(DBO.FN_STAGESORT(OH.STAGE,'OM'),4,18) AS STAGENAME,
OH.USERDEFINEDCODE_2 AS STEP,
----------------------
OH.TRANSACTIONNUMBER,
OD.QUANTITYORDERED,
ITM.REFERENCE_1 AS COMMONNAME,
ITM.ITEMCODE,
-- UNITPRICE HAS BEEN RE-DEFINED TO BE MERCHPRICE (I.E. LIST MINUS DISCOUNT)
--ISNULL(OD.UNITPRICE - ((ISNULL(OD.DISCOUNTPERCENT,0)/100)*OD.UNITPRICE),0) AS DISCOUNTPRICE,
OD.UNITPRICE AS DISCOUNTPRICE,
IIF(PSH.RETAILREQUIRED='Y', '*', NULL) AS RETAILREQMARK,
(SELECT TOP 1 PSD.RETAILPRICE FROM IMPRICESCHEDULEDETAIL PSD (NOLOCK) 
	WHERE PSD.R_ITEM = OD.R_ITEM AND PSD.R_PRICESCHEDULEHEADER = PSH.ROWID
	AND PSD.EXPIRATIONDATE > OH.SHIPPINGDATE ORDER BY PSD.EXPIRATIONDATE) AS RETAILPRICE,
ITM.ITEMSUPCCODE,
DBO.FN_FORMATUPC(PSH.ROWID, WH.ROWID, ITM.ROWID) AS FORMATTEDUPC,
IIF(PSH.SKUREQUIRED='Y', '*', NULL) AS SKUREQMARK,
(SELECT TOP 1 PSD.ALTERNATESKU FROM IMPRICESCHEDULEDETAIL PSD (NOLOCK) 
	WHERE PSD.R_ITEM = OD.R_ITEM AND PSD.R_PRICESCHEDULEHEADER = PSH.ROWID
	AND PSD.EXPIRATIONDATE > OH.SHIPPINGDATE ORDER BY PSD.EXPIRATIONDATE DESC) AS ALTERNATESKU
FROM OMTRANSACTIONHEADER OH (NOLOCK)
JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID
LEFT JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OD.R_WAREHOUSE
JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = CUST.ROWID
JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM
LEFT JOIN IDMASTER PART (NOLOCK) ON PART.ROWID = OH.R_SALESPERSON_1
LEFT JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = OH.R_SHIPPER
LEFT JOIN IDCONSIGNEESHIPPERZONE ZON (NOLOCK) ON ZON.R_CONSIGNEE = ICONS.R_IDENTITY AND ZON.R_SHIPPER = WH.ROWID
LEFT JOIN IMPRICESCHEDULEHEADER PSH (NOLOCK) ON PSH.ROWID = ZON.R_PRICESCHEDULE
