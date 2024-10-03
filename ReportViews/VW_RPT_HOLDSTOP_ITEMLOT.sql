/*
--67 HOLD/STOP FOR ITEM/LOT
-- AND HOLD/STOP BY DATE
SELECT *
FROM VW_RPT_HOLDSTOP_ITEMLOT (NOLOCK)
WHERE ISACTIVE IS NOT NULL
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_HOLDSTOP_ITEMLOT]
AS
SELECT
	CO.COMPANYID,
	CO.NAME AS COMPANYNAME,
	ITM.RECORDTYPE,
	NULLIF(ISNULL(VLOT.USERDEFINEDCODE_3,'')+ISNULL(VLOT.USERDEFINEDREFERENCE_4,''),'') AS ISACTIVE,
	WH.IDENTITYID AS WAREHOUSEID, 
	WH.NAME AS WAREHOUSENAME,
	SUBSTRING(PGC.PRODUCTCATEGORYCODE,1,3) AS PLANTGROUPCODE,
	PGC.PRODUCTCATEGORYCODE+ITM.REFERENCE_5+CNT.CONTAINERSORT+ITM.SUBCLASSCODE AS GNC_ITEMSORT,
	PGC.PRODUCTCATEGORYCODE AS PLANTGROUP,
	ITM.REFERENCE_5 AS SORTNAMEVARIETY,
	CNT.CONTAINERSORT,
	ITM.ITEMCODE,
	(SELECT ITMDP.PROFILECODE FROM IMITEMDP ITMDP (NOLOCK) WHERE ITMDP.ROWID = ITM.R_PROFILE) AS VARIETYCODE,
	CNT.CONTAINERCODE,
	ITM.SUBCLASSCODE AS QUALITYCODE,
	CNT.PRINTEDCONTAINERCODE,
	ITM.REFERENCE_1 AS COMMONNAME,
	ITM.DESCRIPTION_1 AS SHORTCOMMON,
	ITM.USERDEFINEDREFERENCE_1 AS PATENTNUMBER,
	DBO.FN_LISTPRICE(ITM.ROWID,NULL,NULL) AS LISTPRICE,
	VLOT.LOTCODE,
	VLOT.ON_HAND,
	LEFT(VLOT.LOTCODE,2) AS LOTYEAR,
	SUBSTRING(VLOT.LOTCODE,4,4) AS LOTSEASON,
	VLOT.USERDEFINEDCODE_5 AS PULLTAGSUSPEND, 
	VLOT.USERDEFINEDREFERENCE_3 AS SUSPENDTO, 
	VLOT.USERDEFINEDCODE_4 AS SPECIALPULLER, 
	VLOT.USERDEFINEDREFERENCE_1 AS PULLTAGNOTE1, 
	VLOT.USERDEFINEDREFERENCE_2 AS PULLTAGNOTE2, 
	VLOT.USERDEFINEDCODE_3 AS HOLDSTOPCODE,
	VLOT.USERDEFINEDDATE_1 AS HOLDSTOPSTARTDATE,
	VLOT.USERDEFINEDDATE_2 AS HOLDSTOPENDDATE,
	VLOT.USERDEFINEDREFERENCE_4 AS HOLDSTOPREASON,
	VLOT.USERDEFINEDDATE_4 AS HSREASONSTARTDATE,
	VLOT.USERDEFINEDDATE_5 AS HSREASONENDDATE,
	VLOT.USERDEFINEDREFERENCE_7 AS SALESNOTE,
	VLOT.USERDEFINEDDATE_6 AS SALESNOTESTARTDATE,
	VLOT.USERDEFINEDDATE_7 AS SALESNOTEENDDATE,
	VLOT.USERDEFINEDREFERENCE_6 AS INVENTORYNOTE,
	VLOT.USERDEFINEDDATE_8 AS INVNOTESTARTDATE,
	VLOT.USERDEFINEDDATE_9 AS INVNOTEENDDATE
FROM IMITEM ITM (NOLOCK)
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = ITM.R_WAREHOUSE
JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID
JOIN VW_IMLOTVIEW2 VLOT (NOLOCK) ON VLOT.R_ITEM = ITM.ROWID
JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = VLOT.ROWID
JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE
JOIN IMPRODUCTCATEGORY PGC (NOLOCK) ON PGC.ROWID = ITM.R_PRODUCTCATEGORY
WHERE ITM.RECORDTYPE <> 'P' AND WH.IDENTITYID < '99'
