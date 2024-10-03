/*T09851
--182 PULL TAGS 
--183 PULL TAG SELECT SCREEN INQUIRY
SELECT * 
FROM VW_RPT_PULLTAGS (NOLOCK) 
WHERE VW_RPT_PULLTAGS.RECORDTYPE = 'R' 
AND VW_RPT_PULLTAGS.QUANTITYSHIPPED > 0 
--and trip = 'T09851'
--order by tagno
------- 
AND QACODE <> ''							--RT= 1:46 (1,643 ROWS)
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_PULLTAGS]
AS
SELECT 
	--OD.USERDEFINEDQUANTITY_1 AS ELLENSUNIQUETAGNO,
	NULLIF(OD.REVIEWBACKORDERFLAG,'N') AS REVIEWBACKORDERFLAG, OD.QUANTITYBACKORDER AS TESTQTYBO, OD.QUANTITYORDERED AS TESTQTYORD, OD.QUANTITYSHIPPED AS TESTQTYSHIP,
	--ADDED PER SAAD FOR INTEGRATION WITH INSIGHT PROCESSES:
	OH.ROWID AS OMTRANSACTIONHEADERROWID,
	OD.ROWID AS OMTRANSACTIONDETAILROWID,
	CO.COMPANYID,
	CO.NAME AS COMPANYNAME,
	ITM.RECORDTYPE,

	--FIELDS ONLY USED FOR #183 PULL TAG SELECT SCREEN INQUIRY
	WH.IDENTITYID AS WAREHOUSEID,
	WH.NAME AS WAREHOUSENAME,
	FMH.PLANSTART AS TRIPDATE,
	FMH.STATUS,
	(SELECT FLAGDESCRIPTION FROM ABFLAGFIELD (NOLOCK) WHERE TABLENAME='FMTRIPHEADER' AND FIELDNAME='STATUS' AND FLAGVALUE = FMH.STATUS) AS STATUSDESC,
	(SELECT CARR.NAME FROM IDMASTER CARR (NOLOCK) WHERE CARR.ROWID = FMH.R_CARRIER) AS CARRIER,
	(SELECT ISNULL(NULLIF(CARR.NAME,''),'ZZZ') FROM IDMASTER CARR (NOLOCK) WHERE CARR.ROWID = FMH.R_CARRIER) AS CARRIERSORT,
	OH.FMPUSTOPNUMBER AS STOP,
	OH.STAGE AS STAGE,
	SUBSTRING(DBO.FN_STAGESORT(OH.STAGE,'OM'),4,18) AS STAGENAME,
	OH.USERDEFINEDCODE_2 AS STEP,
	(SELECT OMCODES.DESCRIPTION_1 FROM OMCODES (NOLOCK) WHERE CODETYPE = '03' AND OMCODES.CODE = OH.USERDEFINEDCODE_2) AS STEPDESC,

	----PULL TAG FIELDS: 
	----SETNO + TAGSORTORDER:SUSPEND+SUSPENDTO+SHIPPINGRESPONSIBILITY+SPECIALPULLER+PICKSEQUENCE+PLANTGROUPCODE+CONTAINERSORT+SORTNAME
	--	ISNULL(OH.SETNO,'')+'|'+
	--	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Suspend'), ISNULL(LOT.USERDEFINEDCODE_5,''))+'|'+
	--	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'SuspendTo'), ISNULL(LOT.USERDEFINEDREFERENCE_3,''))+'|'+
	--	ISNULL(ITM.USERDEFINEDCODE_10,'')+'|'+
	--	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Special Puller'), ISNULL(LOT.USERDEFINEDCODE_4,''))+'|'+
	--	ISNULL(TRIM(STR(LOC.PICKSEQUENCE)),'')+'|'+
	--	ISNULL(PGC.PRODUCTCATEGORYCODE,'')+'|'+
	--	ISNULL(CNT.CONTAINERSORT,'')+'|'+
	--	ISNULL(ITM.REFERENCE_5,'')
	--AS TAGSORTORDER,
	--SETNO + TAGSORTORDER:SUSPEND+SUSPENDTO+SHIPPINGRESPONSIBILITY+SPECIALPULLER+PICKSEQUENCE+PLANTGROUPCODE+CONTAINERSORT+SORTNAME
		ISNULL(OH.SETNO,'')+'|'+
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Suspend'), '')+'|'+
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'SuspendTo'), '')+'|'+
		ISNULL(ITM.USERDEFINEDCODE_10,'')+'|'+
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Special Puller'), '')+'|'+
		ISNULL(TRIM(STR(LOC.PICKSEQUENCE)),'')+'|'+
		ISNULL(PGC.PRODUCTCATEGORYCODE,'')+'|'+
		ISNULL(CNT.CONTAINERSORT,'')+'|'+
		ISNULL(ITM.REFERENCE_5,'')
	AS TAGSORTORDER,

--HERE ARE THE FIELDS THAT NEED PTROVERRIDES WITH THEIR DEFAULT FALLBACK FIELDS:
	--ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'PullTagNote1'), LOT.USERDEFINEDREFERENCE_1) AS PULLTAGNOTE1,
	--ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'PullTagNote2'), LOT.USERDEFINEDREFERENCE_2) AS PULLTAGNOTE2,
	--NEW LOGIC BY ELLEN: PRINT LOCATIONPTNOTE IF AVAILABLE OTHERWISE PRINT PULLTAGNOTE:
	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'LocationPTN1'), ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'PullTagNote1'), LOT.USERDEFINEDREFERENCE_1)) AS PULLTAGNOTE1,
	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'LocationPTN2'), ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'PullTagNote2'), LOT.USERDEFINEDREFERENCE_2)) AS PULLTAGNOTE2,

	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'PickNote'), ISNULL(OD.COMMENT, '')) AS PICKNOTE, 
	--NULLIF('*****' + ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Suspend'), LOT.USERDEFINEDCODE_5), '*****')
	--	+ ISNULL(' ' + LEFT(ISNULL(	DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'SuspendTo'), ISNULL(LOT.USERDEFINEDREFERENCE_3,'')), 5), '') AS [SUSPEND],
	NULLIF('*****' + ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Suspend'),''), '*****')
		+ ISNULL(' ' + LEFT(ISNULL(	DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'SuspendTo'), ''), 5), '') AS [SUSPEND],
	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'Special Puller'), '') AS SPECIALPULLER,
	ISNULL(OD.QUANTITYSHIPPED, 0) AS QUANTITYSHIPPED,
	ISNULL(IL.OUT_SHIPPED,0) AS OUT_SHIPPED,
	ISNULL(ICONS.USERDEFINEDCODE_10, '') AS TAGCODE,
--After complaints that QA code is missing, I found that FIELD MANIFEST uses ICONS.UDC_11
-- and PULLTAGS uses the function. Which one do they want to use??????
	ICONS.USERDEFINEDCODE_11 AS QUALITYASSURANCECODE,
	--ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, NULL ,'QA CODE'), '') AS QACODE,
	ISNULL(ITM.USERDEFINEDCODE_10, '') AS PULLERRESPONSIBILITY,
	ISNULL(OH.TRANSACTIONNUMBER, '')  AS ORDERNO,
	ISNULL(CONS.NAME, '') AS [CONSIGNEE/SHIPTO],
	ISNULL(ACONS.STATE, '') AS CONSIGNEESTATE,
--	NULLIF(LEFT(ACONT.TELEPHONE_1,8)+'-'+RIGHT(ACONT.TELEPHONE_1,4),'-') AS CONTACTTELEPHONE_1,
	ISNULL(FMH.EQUIPMENT, '') AS TRUCKTYPE,
	ISNULL(FMH.TRIPNO, '') AS TRIP,
/*	I dunno what this is, but imma keep it for a minute:
	ROW_NUMBER() OVER (
		PARTITION BY OD.ROWID, LOC.ROWID
		ORDER BY OD.ROWID)  AS TAGNO,
*/
	(SELECT TOP 1 PULLTAGNO FROM OMREVIEWINVENTORYASSIGNMENT IA (NOLOCK) WHERE IA.R_IMTRANSACTIONLOCATION = IL.ROWID AND IA.R_TRANSACTIONDETAIL = OD.ROWID) AS TAGNO,
	ISNULL(ITM.ITEMCODE, '') AS ITEMCODE,
	CASE ITM.SUBCLASSCODE WHEN '1' THEN '' ELSE ISNULL((SELECT TOP 1 DESCRIPTION_1 FROM IMCODES (NOLOCK) WHERE CODETYPE = '02' AND CODE = ITM.SUBCLASSCODE), '') END AS QUALITY,
	ISNULL(ITM.DESCRIPTION_1, '') AS SHORTCOMMON,
	ISNULL(ITM.REFERENCE_1, '') AS COMMONNAME,
	ISNULL((SELECT TOP 1 DESCRIPTION_1 FROM FMCODES (NOLOCK) WHERE CODETYPE = '52' AND CODE = FMH.USERDEFINEDCODE_2), '') AS DOCK,
	ISNULL(ITM.CLASSCODE, '') AS CONTSIZE,
	ISNULL(ITM.SPECIFICATIONCODE, '') AS STDINTERNALSPECS,
	ISNULL(LOC.LOCATIONCODE, '') AS BLOCKLOCATION,
	'STOP (' + ISNULL(CONVERT(VARCHAR(25), OH.FMPUSTOPNUMBER), '') + ')' AS STOPNO,
	ISNULL(PART.IDENTITYID, '') AS SALESMAN,
	ISNULL(FID.DESCRIPTION_2, 'No') + ' Field ID' AS FIELDIDTAGCOLOR,
	ITM.USERDEFINEDCODE_19 * IL.OUT_SHIPPED AS PULLERUNITS,
	ISNULL(ITM.USERDEFINEDCODE_11, '') AS GRADELABELCOLOR,
	NULLIF(ISNULL(ITM.USERDEFINEDCODE_12, 'NONE'),'NONE') AS BRANDPOTREQ,
	ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID ,'HOLD/STOP'), '') AS HOLDSTOP,
	(SELECT DESCRIPTION_1 FROM IMCODES (NOLOCK) WHERE CODE = ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID ,'HOLD/STOP'), '') AND CODETYPE = '13') AS HOLDSTOPTEXT,
	OH.REVIEWSTAGE AS OHREVIEWSTAGE,
	OD.REVIEWSTAGE AS ODREVIEWSTAGE,
	OH.SETNO,
	OH.REVIEWER,
	TRIM(LOT.LOTCODE) + '.' + 
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'SOURCE'),'') + '.' + 
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'DesigCust'),'') + '.' + 
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'DesigItem'),'') + '.' + 
		ISNULL(DBO.FN_OMATTRIBUTES(OD.ROWID, IL.ROWID, 'DesigLoc'),'') AS Mastercode
FROM OMTRANSACTIONHEADER OH (NOLOCK)
JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OH.ROWID = OD.R_TRANSACTIONHEADER
JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM
LEFT JOIN IMPRODUCTCATEGORY PGC (NOLOCK) ON PGC.ROWID = ITM.R_PRODUCTCATEGORY
LEFT JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER
JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = OD.R_LOT AND LOT.R_ITEM = ITM.ROWID
JOIN IMTRANSACTIONLOCATION IL (NOLOCK) ON IL.R_TRANSACTIONDETAIL = OD.ROWID AND IL.R_ITEM = ITM.ROWID AND IL.R_LOT = LOT.ROWID
JOIN IMLOCATION LOC (NOLOCK) ON LOC.ROWID = IL.R_LOCATION
JOIN IDMASTER CONS (NOLOCK) ON OH.R_SHIPPER = CONS.ROWID
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = CONS.ROWID
LEFT JOIN FMTRIPHEADER FMH (NOLOCK) ON OH.FMTRIPNUMBER = FMH.TRIPNO
LEFT JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID
LEFT JOIN IDMASTER PART (NOLOCK) ON OH.R_SALESPERSON_1 = PART.ROWID 
LEFT JOIN IMCODES FID (NOLOCK) ON FID.CODE = ITM.USERDEFINEDCODE_15 AND FID.CODETYPE = 'C3'	--FIELDIDTAGCOLOR
LEFT JOIN IDTYPESLINKS IDTYPE (NOLOCK) ON IDTYPE.R_IDENTITY = CONS.ROWID AND IDTYPE.IDTYPE = '02'
LEFT JOIN IDADDRESS ACONS (NOLOCK) ON ACONS.ROWID = ISNULL(IDTYPE.R_ADDRESS,CONS.R_DEFAULTADDRESS)  AND ACONS.R_IDENTITY = CONS.ROWID
--CONTACT DATA
--LEFT JOIN IDRELATIONSHIPLINKS LCONT (NOLOCK) ON LCONT.R_IDMASTER = CONS.ROWID AND LCONT.IDMASTERTYPE = '02' AND LCONT.IDMEMBERTYPE = '22' 
--JOIN IDCONTACTS ICONT (NOLOCK) ON ICONT.R_IDENTITY = LCONT.R_IDMEMBER AND ICONT.USERDEFINEDCODE_1 LIKE 'SHIPPING%'
--LEFT JOIN IDADDRESS ACONT (NOLOCK) ON ACONT.R_IDENTITY = ICONT.R_IDENTITY
