/*
--227 Cust Book Data
SELECT * FROM VW_RPT_CUST_BOOK_DATA (NOLOCK)
WHERE VW_RPT_CUST_BOOK_DATA.RECORDTYPE <> 'P'
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_CUST_BOOK_DATA]
AS
SELECT
CO.COMPANYID,
CO.NAME AS COMPANYNAME,
TRIM(WH.IDENTITYID) AS WAREHOUSEID,
TRIM(WH.NAME) AS WAREHOUSENAME,
OH.SHIPPINGDATE AS TRANSACTIONDATE,
OH.RECORDTYPE,
CUST.IDENTITYID AS CUSTOMERID,
CUST.NAME AS CUSTOMERNAME,
ICUST.CUSTOMERPURCHASEDISCOUNT,
CONS.IDENTITYID AS CONSIGNEEID,
CONS.NAME AS CONSIGNEENAME,
PSH.PRICESCHEDULECODE,
PSH.ALLOWUNSPECIFIED,
PSH.DISCOUNTPERCENT,
OH.TRANSACTIONNUMBER,
TRIM(ITM.ITEMCODE) AS ITEMCODE,
CNT.PRINTEDCONTAINERCODE,
TRIM(ITM.SUBCLASSCODE) AS QUALITYCODE,
ITM.USERDEFINEDREFERENCE_1 AS PATENTNUMBER,
ITM.REFERENCE_1 AS COMMONNAME,
TRIM(PGC.PRODUCTCATEGORYCODE) AS PLANTGROUP,
SUBSTRING(PGC.PRODUCTCATEGORYCODE,1,3) AS PLANTGROUPCODE,
ITM.REFERENCE_5 AS SORTNAMEVARIETY,
CNT.CONTAINERSORT,
PGC.DESCRIPTION AS PLANTGROUPDESCRIPTION,
ITM.SPECIFICATIONCODE AS GRADEMEAS,
ITM.USERDEFINEDCODE_17 AS BRAND,
ITM.ARTRADEDISCOUNTFLAG AS NETPRICED, 
OH.STAGE AS STAGE,
SUBSTRING(DBO.FN_STAGESORT(OH.STAGE,'OM'),4,18) AS STAGENAME,
OH.USERDEFINEDCODE_2 AS STEP,
(SELECT OMCODES.DESCRIPTION_1 FROM OMCODES (NOLOCK) WHERE CODETYPE = '03' AND OMCODES.CODE = OH.USERDEFINEDCODE_2) AS STEPDESC,
OD.QUANTITYORDERED,
OD.QUANTITYSHIPPED,
OD.UNITPRICE,
OD.QUANTITYSHIPPED * OD.UNITPRICE AS EXTUNITPRICE,
PSD.PRICE,
DBO.FN_LISTPRICE(ITM.ROWID,NULL,NULL) AS LISTPRICE,
--APPLY RULES FOR CUSTOMERUNITPRICING
ISNULL(	PSD.PRICE, 
		IIF(ISNULL(ITM.ARTRADEDISCOUNTFLAG, 'N') = 'Y', 
			DBO.FN_LISTPRICE(ITM.ROWID,NULL,NULL), --NETPRICED ITEMS DON'T RECEIVE A DISCOUNT.
			(1 - ISNULL(PSH.DISCOUNTPERCENT, ISNULL(ICUST.CUSTOMERPURCHASEDISCOUNT,0))/100) * DBO.FN_LISTPRICE(ITM.ROWID,NULL,NULL) ) ) 
	AS CUSTOMERUNITPRICING,
--{NULL} LOTYEAR FORCES LTS TO CY+PY ROLLUP: 
DBO.FN_SUPPLYROLLUP(ITM.ROWID, NULL, 'F%', NULL, NULL) - DBO.FN_DEMANDROLLUP(ITM.ROWID, NULL, 'F%', NULL) AS LTS_F,
DBO.FN_SUPPLYROLLUP(ITM.ROWID, NULL, 'S%', NULL, NULL) - DBO.FN_DEMANDROLLUP(ITM.ROWID, NULL, 'S%', NULL) AS LTS_S,
DBO.FN_SUPPLYROLLUP(ITM.ROWID, NULL, 'U%', NULL, NULL) - DBO.FN_DEMANDROLLUP(ITM.ROWID, NULL, 'U%', NULL) AS LTS_U,
DBO.FN_SUPPLYROLLUP(ITM.ROWID, NULL,  NULL, NULL, NULL) - DBO.FN_DEMANDROLLUP(ITM.ROWID, NULL,  NULL, NULL) AS LTS_FSU,
DBO.FN_LISTPRICE(ITM.ROWID, NULL, NULL) * 
	(DBO.FN_SUPPLYROLLUP(ITM.ROWID, NULL, NULL, NULL, NULL) - DBO.FN_DEMANDROLLUP(ITM.ROWID, NULL, NULL, NULL)) 
	AS LTS_FSU_VALUE,
ITM.ITEMSUPCCODE,
PSD.ALTERNATESKU, 
PSD.RETAILPRICE,
LOT.USERDEFINEDCODE_3 AS HOLDSTOPCODE,
SUBSTRING(OD.COMMENT,1,255) AS PICKNOTE
FROM OMTRANSACTIONHEADER OH (NOLOCK)
JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID
JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER
JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = CUST.ROWID
JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = CONS.ROWID
LEFT OUTER JOIN IDCONSIGNEESHIPPERZONE SCONS (NOLOCK) ON SCONS.R_SHIPPER = WH.ROWID AND SCONS.R_CONSIGNEE = CONS.ROWID
LEFT OUTER JOIN IMPRICESCHEDULEHEADER PSH (NOLOCK) ON PSH.ROWID = ISNULL(SCONS.R_PRICESCHEDULE, ICONS.R_PRICESCHEDULE) 
LEFT OUTER JOIN IMPRICESCHEDULEDETAIL PSD (NOLOCK) ON PSD.R_PRICESCHEDULEHEADER = PSH.ROWID AND PSD.R_ITEM = OD.R_ITEM AND PSD.EXPIRATIONDATE >= GETDATE()
LEFT OUTER JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM 
LEFT JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = OD.R_LOT
LEFT OUTER JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE
LEFT OUTER JOIN IMPRODUCTCATEGORY PGC (NOLOCK) ON PGC.ROWID = ITM.R_PRODUCTCATEGORY
---------------------------------------------------------------------------------------------------
UNION
---------------------------------------------------------------------------------------------------
SELECT
CO.COMPANYID,
CO.NAME AS COMPANYNAME,
WH.IDENTITYID AS WAREHOUSEID,
WH.NAME AS WAREHOUSENAME,
NULL AS TRANSACTIONDATE,
NULL AS RECORDTYPE,
NULL AS CUSTOMERID,
NULL AS CUSTOMERNAME,
NULL AS CUSTOMERPURCHASEDISCOUNT,
NULL AS CONSIGNEEID,
NULL AS CONSIGNEENAME,
NULL AS PRICESCHEDULECODE,
NULL AS ALLOWUNSPECIFIED,
NULL AS DISCOUNTPERCENT,
NULL AS TRANSACTIONNUMBER,
VITM.ITEMCODE,
VITM.PRINTEDCONTAINERCODE,--CNT.PRINTEDCONTAINERCODE,
VITM.QUALITYCODE,--ITM.SUBCLASSCODE AS QUALITYCODE,
VITM.PATENTNUMBER,--ITM.USERDEFINEDREFERENCE_1 AS PATENTNUMBER,
VITM.COMMONNAME,--ITM.REFERENCE_1 AS COMMONNAME,
VITM.PLANTGROUPCODE AS PLANTGROUP,--PGC.PRODUCTCATEGORYCODE AS PLANTGROUP,
SUBSTRING(VITM.PLANTGROUPCODE,1,3) AS PLANTGROUPCODE,--SUBSTRING(PGC.PRODUCTCATEGORYCODE,1,3) AS PLANTGROUPCODE,
VITM.SORTNAMEVARIETY,--ITM.REFERENCE_5 AS SORTNAMEVARIETY,
VITM.CONTAINERSORT,--CNT.CONTAINERSORT,
VITM.PLANTGROUPDESCRIPTION,--PGC.DESCRIPTION AS PLANTGROUPDESCRIPTION,
VITM.GRADEMEAS,--ITM.SPECIFICATIONCODE AS GRADEMEAS,
VITM.BRAND,--ITM.USERDEFINEDCODE_17 AS BRAND,
VITM.NETPRICED,--ITM.ARTRADEDISCOUNTFLAG AS NETPRICED, 
NULL AS STAGE,
NULL AS STAGENAME,
NULL AS STEP,
NULL AS STEPDESC,
NULL AS QUANTITYORDERED,
NULL AS QUANTITYSHIPPED,
NULL AS UNITPRICE,
NULL AS EXTUNITPRICE,
NULL AS PRICE,
DBO.FN_LISTPRICE(VITM.ITEM_ROWID,NULL,NULL) AS LISTPRICE,
--APPLY RULES FOR CUSTOMERUNITPRICING
NULL AS CUSTOMERUNITPRICING,
--{NULL} LOTYEAR FORCES LTS TO CY+PY ROLLUP: 
DBO.FN_SUPPLYROLLUP(VITM.ITEM_ROWID, NULL, 'F%', NULL, NULL) - DBO.FN_DEMANDROLLUP(VITM.ITEM_ROWID, NULL, 'F%', NULL) AS LTS_F,
DBO.FN_SUPPLYROLLUP(VITM.ITEM_ROWID, NULL, 'S%', NULL, NULL) - DBO.FN_DEMANDROLLUP(VITM.ITEM_ROWID, NULL, 'S%', NULL) AS LTS_S,
DBO.FN_SUPPLYROLLUP(VITM.ITEM_ROWID, NULL, 'U%', NULL, NULL) - DBO.FN_DEMANDROLLUP(VITM.ITEM_ROWID, NULL, 'U%', NULL) AS LTS_U,
DBO.FN_SUPPLYROLLUP(VITM.ITEM_ROWID, NULL,  NULL, NULL, NULL) - DBO.FN_DEMANDROLLUP(VITM.ITEM_ROWID, NULL,  NULL, NULL) AS LTS_FSU,
DBO.FN_LISTPRICE(VITM.ITEM_ROWID, NULL, NULL) * 
	(DBO.FN_SUPPLYROLLUP(VITM.ITEM_ROWID, NULL, NULL, NULL, NULL) - DBO.FN_DEMANDROLLUP(VITM.ITEM_ROWID, NULL, NULL, NULL)) 
	AS LTS_FSU_VALUE,
VITM.ITEMSUPCCODE,
NULL AS ALTERNATESKU, 
NULL AS RETAILPRICE,
NULL AS HOLDSTOPCODE,
NULL AS PICKNOTE

FROM VW_RPT_ITEM_LISTING VITM (NOLOCK)
--FROM OMTRANSACTIONHEADER OH (NOLOCK)
--JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID
JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = VITM.COMPANYID
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = VITM.WAREHOUSE_ROWID--OH.R_FMSHIPPER
--JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
--JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = CUST.ROWID
--JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER
--JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = CONS.ROWID
--LEFT OUTER JOIN IDCONSIGNEESHIPPERZONE SCONS (NOLOCK) ON SCONS.R_SHIPPER = WH.ROWID AND SCONS.R_CONSIGNEE = CONS.ROWID
--LEFT OUTER JOIN IMPRICESCHEDULEHEADER PSH (NOLOCK) ON PSH.ROWID = ISNULL(SCONS.R_PRICESCHEDULE, ICONS.R_PRICESCHEDULE) 
--LEFT OUTER JOIN IMPRICESCHEDULEDETAIL PSD (NOLOCK) ON PSD.R_PRICESCHEDULEHEADER = PSH.ROWID AND PSD.R_ITEM = OD.R_ITEM AND PSD.EXPIRATIONDATE >= GETDATE()
--LEFT OUTER JOIN IMITEM ITM (NOLOCK) ON ITM.ITEM_ROWID = OD.R_ITEM 
--LEFT OUTER JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE
--LEFT OUTER JOIN IMPRODUCTCATEGORY PGC (NOLOCK) ON PGC.ROWID = ITM.R_PRODUCTCATEGORY


--ORDER BY 
--		WH.IDENTITYID,
--		CUST.IDENTITYID,
--		PSH.PRICESCHEDULECODE,
--		VITM.ITEMCODE
