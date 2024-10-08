/*
--114 Production Reservations MC
--115 Product Reservations W Pricing
SELECT *
FROM VW_RPT_PRODUCT_RESERVATION (NOLOCK)
WHERE RECORDTYPE <> 'P'
AND TRIPNUMBER = 'T14066'
--AND TRANSACTIONNUMBER = '10-25527-82'

--PO Product Reservation Group
SELECT *
FROM VW_RPT_PRODUCT_RESERVATION (NOLOCK)
WHERE CUSTOMERIDGROUP IS NOT NULL
AND INTERDIVPO = 'Y'


*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_PRODUCT_RESERVATION]
AS
SELECT 
	CO.COMPANYID, 
	CO.NAME AS COMPANYNAME,
	WH.IDENTITYID AS WAREHOUSEID,
	WH.NAME AS WAREHOUSENAME,
	OH.RECORDTYPE,
	PART.IDENTITYID AS SALESREP,
	PART.NAME AS SALESREPNAME,
	ICONS.USERDEFINEDCODE_12 AS TERRITORYCODE,
	IDC.DESCRIPTION_1 AS TERRITORYDESC,
	OH.TRANSACTIONDATE,
	ITM.USERDEFINEDREFERENCE_3 AS INTERDIVPO,		-->THE MYSTERY FIELD HAS BEEN IDENTIFIED.
	VCUST.CUSTOMERIDGROUP,
	(SELECT DESCRIPTION_1 FROM IDCODES (NOLOCK) WHERE CODETYPE = 'Z7' AND CODE = VCUST.CUSTOMERIDGROUP) AS CUSTOMERGROUPNAME,
	ISNULL(VCUST.CustomerUserDefinedCode_8, 'N') AS MAJORACCT,
	VCUST.CUSTOMERIDENTITYID,
	VCUST.CUSTOMERNAME,
	VCONS.CONSIGNEEIDGROUP,
	VCONS.CONSIGNEEIDENTITYID,
	VCONS.CONSIGNEENAME,
	ISNULL(ALTSHIP.CITY, VCONS.CONSIGNEECITY) AS CONSIGNEECITY,
	ISNULL(ALTSHIP.STATE, VCONS.CONSIGNEESTATE) AS CONSIGNEESTATE,
	TRIM(ISNULL(ALTSHIP.CITY, VCONS.CONSIGNEECITY))+', '+TRIM(ISNULL(ALTSHIP.STATE, VCONS.CONSIGNEESTATE)) AS CONSIGNEECITYSTATE,
	OH.FMTRIPNUMBER AS TRIPNUMBER, 
	OH.FMPUSTOPNUMBER AS STOPNUMBER,
	TRIM(OH.FMTRIPNUMBER) + ' / ' + TRIM(STR(OH.FMPUSTOPNUMBER)) AS TRIPSTOPTEXT,
	OH.USERDEFINEDDATE_1 AS TRIPDATE,	--This gets updated VIA a TA job from FMTRIPHEADER.PLANSTART
	OH.TRANSACTIONNUMBER,
	LOT.USERDEFINEDCODE_3 AS HOLDSTOPCODE,
	LOT.LOTCODE,
	LOC.LOCATIONCODE,
	--HAD TO GET DOCK FROM FMTRIPHEADER TABLE
	(	SELECT HDR.USERDEFINEDCODE_2
		FROM FMDISPATCHOBJECT OBJ (NOLOCK) 
		JOIN FMTRIPDETAIL DTL (NOLOCK) ON DTL.R_FMDISPATCHOBJECT = OBJ.ROWID
		JOIN FMTRIPHEADER HDR (NOLOCK) ON HDR.ROWID = DTL.R_TRIPHEADER
		WHERE OBJ.R_SOURCEID = OH.ROWID 
	) AS DOCK,
	DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'SOURCE') AS SOURCE,
	DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'DesigCust') AS DesigCust,
	DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'DesigItem') AS DesigItem,
	DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'DesigLoc') AS DesigLoc,
	--THIS DOESN'T WORK, USE QUANTITYATSTAGE AND HOPE NOBODY CARES.
	(SELECT TOP 1 MC.PRODUCTIONQUANTITY FROM OMREVIEWMASTERCODES MC (NOLOCK)
	WHERE ITM.ROWID = MC.R_ITEM AND LOT.ROWID = MC.R_LOT AND LOC.ROWID = MC.R_LOCATION) AS QUANTITYATMC,
	ITM.ITEMCODE,
	ITM.REFERENCE_1 AS COMMONNAME,
	OD.ORIGINALQUANTITYORDERED,
	OD.QUANTITYORDERED,
	OD.QUANTITYSHIPPED,
	OD.QUANTITYBACKORDER,
	IL.OUT_SHIPPED,
	OH.STAGE,
	DBO.FN_STAGESORT(OH.STAGE,'OM') AS STAGESORT,
	SUBSTRING(DBO.FN_STAGESORT(OH.STAGE,'OM'),4,18) AS STAGENAME,
	IIF(CHARINDEX(OH.STAGE,'A;S;C') > 0, OD.QUANTITYSHIPPED, OD.QUANTITYORDERED) AS QUANTITYATSTAGE,
	OH.USERDEFINEDCODE_2 AS STEP,
	DBO.FN_STEPSORT(OH.USERDEFINEDCODE_2) AS STEPSORT,
	SUBSTRING(DBO.FN_STEPSORT(OH.USERDEFINEDCODE_2),4,9) AS STEPNAME,
	OH.REVIEWSTAGE,
	(SELECT IIF(AB.FLAGDESCRIPTION='Review Required','*',NULL) FROM ABFLAGFIELD AB (NOLOCK) 
		WHERE AB.FLAGVALUE = OH.CREDITSTATUSREVIEW AND AB.FIELDNAME = 'CREDITSTATUSREVIEW') AS CREDITSTATUSREVIEWMARK,
	(SELECT AB.FLAGDESCRIPTION FROM ABFLAGFIELD AB (NOLOCK) 
		WHERE AB.FLAGVALUE = OH.CREDITSTATUSREVIEW AND AB.FIELDNAME = 'CREDITSTATUSREVIEW') AS CREDITSTATUSREVIEWDESC,
	OH.SHIPPINGDATE AS REQUESTDATE,
	OH.USERDEFINEDCODE_1 AS REQUESTDATETYPE,
	ITM.SPECIFICATIONCODE AS GRADEMEASURE,
	DBO.FN_LISTPRICE(ITM.ROWID, OH.SHIPPINGDATE, IIF(CHARINDEX(OH.STAGE,'A;S;C') > 0, OD.QUANTITYSHIPPED, OD.QUANTITYORDERED)) AS LISTPRICE,
	-- UNITPRICE HAS BEEN RE-DEFINED TO BE MERCHPRICE (I.E. LIST MINUS DISCOUNT)
	--OD.UNITPRICE - ROUND(OD.UNITPRICE * (ISNULL(OD.DISCOUNTPERCENT,0)/100),2) AS DISCOUNTPRICE,
	OD.UNITPRICE AS MERCHPRICE,
	ICONS.USERDEFINEDCODE_11 AS QACODE
	
FROM OMTRANSACTIONHEADER OH (NOLOCK)
	JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID
	LEFT JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM
	LEFT JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = OD.R_LOT
	LEFT JOIN IMTRANSACTIONLOCATION IL (NOLOCK) ON IL.R_TRANSACTIONDETAIL = OD.ROWID
	LEFT JOIN IMLOCATION LOC (NOLOCK) ON LOC.ROWID = IL.R_LOCATION
	LEFT JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER
	JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID
	LEFT JOIN IDMASTER PART (NOLOCK) ON PART.ROWID = OH.R_SALESPERSON_1
	LEFT JOIN VW_IDCUSTOMERVIEW VCUST (NOLOCK) ON VCUST.CustomerMasterRowID = OH.R_CUSTOMER
	LEFT JOIN VW_IDCONSIGNEEVIEW VCONS (NOLOCK) ON VCONS.ConsigneeMasterRowID = OH.R_SHIPPER 
	LEFT JOIN IDSYNONYMS ALTSHIP (NOLOCK) ON ALTSHIP.ROWID = OH.R_SYNONYMSALTSHIPTO	-->NEW ALTSHIPTOADDRESS PROJECT 3/31/23 DT
	LEFT JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = OH.R_SHIPPER
	LEFT JOIN IDCODES IDC (NOLOCK) ON IDC.CODETYPE = '3M' AND IDC.CODE = ICONS.USERDEFINEDCODE_12 --TERRITORY
WHERE	OH.RECORDTYPE <> 'P'
---------------------------------------------------
