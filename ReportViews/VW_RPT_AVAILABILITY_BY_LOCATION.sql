/* RUNTIME 11:27	(VERY LONG RUNNING REPORT) AFTER REFACTOR: 5:29 MUCH BETTER!!!!!
--46 AVAILABILITY BY LOCATION
SELECT *
FROM VW_RPT_AVAILABILITY_BY_LOCATION (NOLOCK)
WHERE RECORDTYPE <> 'P'
--------------------------------- 
AND ITEMCODE LIKE '001993.031.1'
*/

/*	TEST CASE TO SHOW WHY THERE IS PERCEIVED TO BE "MISSING" OVERSELLPERCENTAGES IN THIS REPORT:
SELECT WH.IDENTITYID AS WAREHOUSEID, ITM.ITEMCODE, LOT.LOTCODE, LOT.OVERSELLPERCENTAGE,
DBO.FN_SUPPLY(ITM.ROWID, LOT.ROWID, NULL) AS SUPPLY,
DBO.FN_SUPPLY(ITM.ROWID, LOT.ROWID, 'I') AS ISUPPLY
FROM IMITEM ITM (NOLOCK)
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = ITM.R_WAREHOUSE
JOIN IMLOT LOT (NOLOCK) ON LOT.R_ITEM = ITM.ROWID
WHERE ITM.ITEMCODE = '001993.031.1' AND WH.IDENTITYID = '10'
ORDER BY WH.IDENTITYID, ITM.ITEMCODE, LOT.LOTCODE
*/


CREATE OR ALTER VIEW [DBO].[VW_RPT_AVAILABILITY_BY_LOCATION]
AS

SELECT
	*,
	LOCATIONCODE + LOTCODE + SOURCE + DESIGITEM + DESIGCUST + DESIGLOC AS MC_LOCATIONSORT,
	--CURRENT SEASON:
	LOTYEAR0 + '.' + LOTSEASON0 AS LOTCODE0,
	DBO.FN_SUPPLYROLLUP(ITEMROWID, IIF(LOTYEAR0 = YR.CURR,NULL,LOTYEAR0), LOTSEASON0, NULL, NULL) AS SUPPLY0,
	DBO.FN_SUPPLYROLLUP(ITEMROWID, IIF(LOTYEAR0 = YR.CURR,NULL,LOTYEAR0), LOTSEASON0, NULL, 'I') AS ISUPPLY0,
	DBO.FN_DEMANDROLLUP(ITEMROWID, IIF(LOTYEAR0 = YR.CURR,NULL,LOTYEAR0), LOTSEASON0, NULL) AS DEMAND0,
	--CURRENT SEASON + 1:
	LOTYEAR1 + '.' + LOTSEASON1 AS LOTCODE1,
	DBO.FN_SUPPLYROLLUP(ITEMROWID, IIF(LOTYEAR1 = YR.CURR,NULL,LOTYEAR1), LOTSEASON1, NULL, NULL) AS SUPPLY1,
	DBO.FN_DEMANDROLLUP(ITEMROWID, IIF(LOTYEAR1 = YR.CURR,NULL,LOTYEAR1), LOTSEASON1, NULL) AS DEMAND1,
	--CURRENT SEASON + 2:
	LOTYEAR2 + '.' + LOTSEASON2 AS LOTCODE2,
	DBO.FN_SUPPLYROLLUP(ITEMROWID, IIF(LOTYEAR2 = YR.CURR,NULL,LOTYEAR2), LOTSEASON2, NULL, NULL) AS SUPPLY2,
	DBO.FN_DEMANDROLLUP(ITEMROWID, IIF(LOTYEAR2 = YR.CURR,NULL,LOTYEAR2), LOTSEASON2, NULL) AS DEMAND2
FROM	(
		SELECT
			CO.COMPANYID,
			CO.NAME AS COMPANYNAME,
			ITM.RECORDTYPE,
			ITM.ROWID AS ITEMROWID,
			WH.IDENTITYID AS WAREHOUSEID,
			WH.NAME AS WAREHOUSENAME,
			PGC.PRODUCTCATEGORYCODE+ITM.REFERENCE_5+CNT.CONTAINERSORT+ITM.SUBCLASSCODE AS GNC_ITEMSORT,
			LEFT(PGC.PRODUCTCATEGORYCODE,3) AS PLANTGROUPCODE,
			PGC.PRODUCTCATEGORYCODE AS PLANTGROUP,
			ITM.REFERENCE_5 AS SORTNAMEVARIETY,
			CNT.CONTAINERSORT,
			ITM.SUBCLASSCODE AS QUALITYCODE,
		--ITEM LEVEL FIELDS:
			ITM.USERDEFINEDCODE_1 AS GENUSCODE,
			GEN.DESCRIPTION_1 AS GENUSNAME,
			ITM.ITEMCODE,
			(SELECT ITMDP.PROFILECODE FROM IMITEMDP ITMDP (NOLOCK) WHERE ITMDP.ROWID = ITM.R_PROFILE) AS VARIETYCODE,
			CNT.CONTAINERCODE,
			CNT.PRINTEDCONTAINERCODE,
			ITM.REFERENCE_1 AS COMMONNAME,
			ITM.REFERENCE_2 AS BOTANICALNAME,
			ITM.USERDEFINEDREFERENCE_1 AS PATENTNUMBER,
			DBO.FN_LISTPRICE(ITM.ROWID,NULL,NULL) AS LISTPRICE,
			ITM.SPECIFICATIONCODE AS ITEMSPEC,
			ITM.USERDEFINEDCODE_2 AS BRAND, 
			ITM.USERDEFINEDCODE_12 AS BRANDPOTREQ,
			ITM.USERDEFINEDCODE_15 AS FIELDTAGCOLOR,
			ITM.USERDEFINEDCODE_10 AS PULLERRESPONSIBILITY, 
			ITM.SALEMAXQUANTITY AS MAXORDERQUANTITY, 
		--LOT LEVEL FIELDS:
			VLOT.IN_ORDERED AS PENDING_REC,
			VLOT.IN_RECEIVING AS IN_REC,
			LOT.OVERSELLPERCENTAGE,
			LOT.USERDEFINEDCODE_6 AS SALEYEAR,
			LOT.USERDEFINEDCODE_10 AS SEASON,
			TRIM(LOT.LOTCODE) AS LOTCODE,
			LEFT(LOT.LOTCODE,2) AS LOTYEAR,
			LOT.USERDEFINEDCODE_10 AS SEASONCODE, 
			LOT.USERDEFINEDCODE_3 AS HOLDSTOPCODE,
			LOT.USERDEFINEDDATE_1 AS HOLDSTOPSTARTDATE,
			LOT.USERDEFINEDDATE_2 AS HOLDSTOPENDDATE,
			LOT.USERDEFINEDREFERENCE_4 AS HOLDSTOPREASON,
			LOT.USERDEFINEDDATE_4 AS HSREASONSTARTDATE,
			LOT.USERDEFINEDDATE_5 AS HSREASONENDDATE,
			DBO.FN_SALESNOTE(ITM.ROWID,LOT.ROWID,NULL) AS FNSALESNOTE,	--5 sec
			LOT.USERDEFINEDREFERENCE_7 AS SALESNOTE, 
			LOT.USERDEFINEDREFERENCE_1 AS PULLTAGNOTE1,
			LOT.USERDEFINEDREFERENCE_2 AS PULLTAGNOTE2,
			LOT.USERDEFINEDREFERENCE_6 AS INVENTORYNOTE,
			LOT.USERDEFINEDDATE_8 AS INVNOTESTARTDATE,
			LOT.USERDEFINEDDATE_9 AS INVNOTEENDDATE,
		--LOCATION LEVEL FIELDS:
			TRIM(LOC.LOCATIONCODE) AS LOCATIONCODE,
			SUBSTRING(LOC.LOCATIONCODE,1,1) AS BLOCKALPHA,
			SUBSTRING(LOC.LOCATIONCODE,3,2) AS BLOCKNUMBER,
			SUBSTRING(LOC.LOCATIONCODE,6,3) AS BAY,
			ITM.USERDEFINEDQUANTITY_1 AS LARGEPTRQTY, 
			DBO.FN_MCATTRIBUTES(MC.ROWID,'SOURCE') AS SOURCE,
			ISNULL(DBO.FN_MCATTRIBUTES(MC.ROWID,'DESIGCUST'),'') AS DESIGCUST,
			ISNULL(DBO.FN_MCATTRIBUTES(MC.ROWID,'DESIGITEM'),'') AS DESIGITEM,
			ISNULL(DBO.FN_MCATTRIBUTES(MC.ROWID,'DESIGLOC'),'') AS DESIGLOC,
			DBO.FN_MCATTRIBUTES(MC.ROWID,'PRIORITY') AS PRIORITY,
			DBO.FN_MCATTRIBUTES(MC.ROWID,'LOCNOTEDATE') AS LOCNOTEDATE,
			DBO.FN_MCATTRIBUTES(MC.ROWID,'LOCATION NOTE') AS LOCATIONNOTE,
			MC.PRODUCTIONQUANTITY AS AVAILABLE_LOC, --IS THIS RIGHT ELLEN?
			--NEW SPECIAL ATTRIBUTE ADDED TO FN_MCATTRIBUTES:
			DBO.FN_MCATTRIBUTES_IA(MC.ROWID,'ONHAND') AS ONHAND_LOC
			--CAST (DBO.FN_MCATTRIBUTES(MC.ROWID,'ONHAND') AS NUMERIC) AS ONHAND_LOC
		FROM OMREVIEWMASTERCODES MC (NOLOCK)
		JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = MC.R_ITEM
		JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = MC.R_LOT
		JOIN VW_IMLOTVIEW2 VLOT (NOLOCK) ON VLOT.ROWID = MC.R_LOT
		JOIN IMLOCATION LOC (NOLOCK) ON LOC.ROWID = MC.R_LOCATION
		JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = ITM.R_WAREHOUSE
		JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID
		JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE
		JOIN IMPRODUCTCATEGORY PGC (NOLOCK) ON PGC.ROWID = ITM.R_PRODUCTCATEGORY
		JOIN IMCODES GEN (NOLOCK) ON GEN.CODE = ITM.USERDEFINEDCODE_1 AND GEN.CODETYPE = '11'	--GENUSNAME
		WHERE ITM.RECORDTYPE <> 'P' AND WH.IDENTITYID NOT LIKE 'TAG%'
		) X, 
		(	SELECT TRIM(STR(DBO.FN_SALEYEAR(NULL)%100)) AS CURR
		) YR, --ATTACH YR.CURR TO BE USED AS A FIELD INSIDE THIS VIEW
		(	SELECT TOP 1 
				LEFT(SEA0.SEASONCODE,2) AS LOTYEAR0, SUBSTRING(SEA0.SEASONCODE,7,2) AS LOTSEASON0,
				LEFT(SEA1.SEASONCODE,2) AS LOTYEAR1, SUBSTRING(SEA1.SEASONCODE,7,2) AS LOTSEASON1,
				LEFT(SEA2.SEASONCODE,2) AS LOTYEAR2, SUBSTRING(SEA2.SEASONCODE,7,2) AS LOTSEASON2
			FROM IMSEASONCODE SEA0 (NOLOCK) 
			JOIN IMSEASONCODE SEA1 (NOLOCK) ON SEA0.ENDDATE <= SEA1.STARTDATE
			JOIN IMSEASONCODE SEA2 (NOLOCK) ON SEA1.ENDDATE <= SEA2.STARTDATE
			WHERE SEA0.ENDDATE >= GETDATE() ORDER BY SEA0.SEASONCODE,SEA1.SEASONCODE,SEA2.SEASONCODE
		) SC	--ATTACH THREE SUCESSIVE LOTYEAR/LOTSEASON VALUES FOR SUPPLY/DEMAND CALCULATIONS IN THIS VIEW
