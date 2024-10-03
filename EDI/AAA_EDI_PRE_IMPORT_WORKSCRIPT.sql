--AAA_EDI_PRE_IMPORT_WORKSCRIPT

/* 
SELECT * FROM GNC_EDI_TRANSLATION

--NEED A LIST OF DATA THAT RURALKING850MAP PRODUCES SO I CAN SEE WHAT I AM UP AGAINST TO FILL OUT EVERYTHING ELSE:
BEG02		PURCHASEORDERNUMBER	'9999999999'
BEG05		TRANSACTIONDATE		'20220320'			--PODATE
ITD12		TERMSCODE			'NET 60'
DTM02	038	SHIPPINGDATE		'20220420'			--REQUESTDATE OR DELIVERYDATE
DTM02	037	UDD_19				'20220401'			--SHIPNOTBEFOREDATE
DTM02	118	DON'T STORE			'20220420'			--IGNORE?
TD505		COMMENT				'XXXXXXXX'			--CARRIERDETAILSTEXT
N902/MTX02	USERDEFINEDCOMMENT	'YYYYYYYY'			--REFERENCETEXT
N104	SF	VENDERNUMBER		'801560001'			--RK ASSIGNED SUPPLIER SITE ID: NEEDED TO DETERMINE WH
N102	ST	CONSIGNEENAME		'RURAL KING 10'		--IGNORE?
N104	ST	STORENUMBER			'010'				--REQUIRED FOR ST: NEEDED TO DETERMINE CUSTOMER/CONSIGNEE VALUES
N301	ST	CONSIGNEEADDR1		'4600 ELM DR'		--IGNORE?
N401	ST	CONSIGNEECITY		'BOULDER'			--IGNORE?
N402	ST	CONSIGNEESTATE		'CO'				--IGNORE?
N403	ST	CONSIGNEEZIP		'80301-3292'		--IGNORE?
N404	ST	CONSIGNEECOUNTRY	'US'				--IGNORE?
PO101		LINENUMBER			'001'
PO102		QUANTITYORDERED		50
PO103		UNITOFMEASURE		'EA'				--IGNORE?
PO104		UNITPRICE			2.57
PO107	IN	ALTERNATESKU		'123456789'

SAMPLE RURAL KING 850:
------------------------------------------------------------
1.) DSD (Direct Store Delivery) PO for 1 Store:
Original Generic Sample given at the end of 850 Spec
------------------------------------------------------------
ST*850*000000001~
BEG*00*NE*260001**20200923~
CUR*BY*USD~
REF*IA*28897~
ITD************60~
DTM*037*20200923~
DTM*038*20200923~
N1*SF*Ship From Name*92*2889700001~
N1*ST*Store# 65*92*65~
PO1*1*2100*EA*195.50**CB*27120018~
PID*F****LED MOTION LIGHT 2000 LUM WHT~
CTT*1*2100~
SE*13*000000001~

------------------------------------------------------------
Modified GNC Version: FOR PO#2029359001 Store 1
------------------------------------------------------------
ST*850*000000001~
BEG*00*NE*2029359001**20210816~
CUR*BY*USD~
REF*IA*80156~
ITD************60~
DTM*037*20210801~
DTM*038*20210830~
N1*SF*GREENLEAF NURSERY*92*801560001~
N1*ST*Store# 1*92*1~
PO1*1*10*EA*12.06**CB*801560166~
PID*F****ASIAN MOON BUTTERFLY BUSH~
PO1*1*15*EA*14.96**CB*801560155~
PID*F****BABY GEM BOXWOOD~
PO1*1*20*EA*12.96**CB*801560168~
PID*F****GREEN VELVET BOXWOOD~
PO1*1*20*EA*10.75**CB*801560166~
PID*F****DWARF BURNING BUSH~
PO1*1*15*EA*10.55**CB*801560170~
PID*F****BLUEBERRY SMOOTHIE ALTHEA~
PO1*1*20*EA*12.70**CB*801560172~
PID*F****LITTLE LIME HYDRANGEA~
PO1*1*10*EA*12.96**CB*801560181~
PID*F****ENDURING RED CRAPEMYRTLE~
PO1*1*10*EA*10.35**CB*801560182~
PID*F****POKOMOKE CRAPEMYRTLE~
PO1*1*40*EA*10.72**CB*801560066~
PID*F****DOUBLE KNOCK OUT ROSE~
PO1*1*20*EA*11.82**CB*801560174~
PID*F****SUNNY KNOCK OUT ROSE~
PO1*1*30*EA*16.59**CB*801560179~
PID*F****GREEN GIANT ARBORVITAE~
CTT*11*210~
SE*33*000000001~

Assumptions I am making:
DTM*037*20210801~
	>>	Arbitrarily sending 2021/08/01 as Ship Not Before date.
DTM*038*20210830~
	>>	Arbitrarily sending 2021/08/30 as Ship No Later date.
N1*SF*GREENLEAF NURSERY*92*801560001~
	>>	801560001 is a number that RK will send(Rural King assigned Supplier Site ID) value based off of a hint from Kathy data.
N1*ST*Store# 1*92*1~
	>>	Insight Store# is 0001, but I am assuming they may only send as 1, per Kathy data.
PO1*1*10*EA*12.06**CB*801560166~
	>>	The RK sample shows PO106 as CB but spec seems to expect IN, I don't know which they will send. CB not mentioned in spec.
*/

--FIELDS THAT WOULD BE SUPPLIED BY INBOUND 850 DOCUMENT IN FORM OF TRANSACTION RECORDTYPE = 'I' RECORDS:
DECLARE @PONUMBER VARCHAR(20),	@PODATE DATETIME,			@REQUESTDATE DATETIME
DECLARE	@CANCELDATE DATETIME,	@SHIPNOTBEFORE DATETIME,	@SHIPNOTAFTER DATETIME
DECLARE @COMMENTS VARCHAR(250),	@EXTRACOMMENTS VARCHAR(250)
DECLARE @VENDOR CHAR(12),		@DEPT CHAR(12),				@STORENUMBER VARCHAR(50),		@GLN VARCHAR(50)
DECLARE @LINENUMBER INT,		@QTYORDERED DECIMAL(29,10),	@LANDEDPRICE DECIMAL(29,10),	@SKU VARCHAR(30)

--ARBITRARILY SETTING THESE VALUES TO SIMILATE RECORDTYPE = 'I' RECORDS:
SET @PONUMBER = ''--'7882353-93'
SET @PODATE = CAST('2022-02-03 08:14:21.000' AS DATETIME)
SET @REQUESTDATE = CAST('2022-04-04 08:14:21.000' AS DATETIME)
SET @SHIPNOTBEFORE = CAST('20170428' AS DATETIME)
SET @SHIPNOTAFTER = CAST(NULL AS DATETIME)
SET @COMMENTS = 'TEST CARRIER DETAILS'
SET @EXTRACOMMENTS = 'TEST EXTRA NOTES'
SET @VENDOR ='999990001'--'67886'--'80156'--'67886'
SET @DEPT = NULL
--IDGROUP = '456'
SET @STORENUMBER = '0093'--null--'0093'
SET @GLN = NULL
--CUSTOMERID = '10456'
--CONSIGNEEID = '826091'
SET @LINENUMBER = 2
SET @QTYORDERED = 260.0000000000--5.0000000000
SET @LANDEDPRICE = 10.5500000000--13.3900000000
SET @SKU = NULL--'801560170'--'100050282'

--NOW TAKE THESE VALUES AND EVALUATE THEM TO FILL IN THE MISSING DATA:
SELECT 
	--VALIDATION CALCULATION FIELD: 
	IIF((	SELECT IIF((COUNT(DISTINCT CPSD.DISCOUNTPRICE) + 
						COUNT(DISTINCT CPSD.FREIGHTCHARGE) + 
						COUNT(DISTINCT CPSD.OTHERCHARGE) + 
						COUNT(DISTINCT CPSD.HANDLINGCHARGE))/4. > 1., 'Y', NULL) 
			FROM IMPRICESCHEDULEDETAIL CPSD (NOLOCK) 
			WHERE CPSD.R_PRICESCHEDULEHEADER = PSH.ROWID 
			AND CPSD.ALTERNATESKU = PSD.ALTERNATESKU 
			AND CPSD.EXPIRATIONDATE > @REQUESTDATE		--OH.SHIPPINGDATE 
			AND ICUST.USERDEFINEDCODE_3 = 'Y' --ONLY IF SKUROLLUP IS REQUIRED BY THE CUSTOMER 
		) = 'Y',																'SKU ROLLUP VIOLATION/',			'') + 
	IIF(ICUST.STATUS <> 'A',													'INACTIVE CUSTOMER/',				'') + 
	IIF(ISNULL(ICUST.USERDEFINEDCODE_9,'') <> 'Y',								'NOT AN EDI CUSTOMER/',				'') + 
	IIF(ISNULL(ICONS.USERDEFINEDREFERENCE_2,'') <> ISNULL(@STORENUMBER,''),		'STORE# NOT SETUP/',				'') + 
	IIF(ISNULL(ICONS.USERDEFINEDREFERENCE_6,'') <> ISNULL(@GLN,''),				'GLN# NOT SETUP/',					'') + 
	IIF(ICUST.OMREQUIREPO = 'Y' AND @PONUMBER IS NULL,							'PO REQUIRED/',						'') + 
	--IIF(ICUST.USERDEFINEDCODE_7 = 'Y' AND OH.USERDEFINEDREFERENCE_4 IS NULL,	'WORK ORDER# REQUIRED/',			'') + --CAN'T DO THIS YET, NO TRANSACTION RECORDTYPE = 'I' RECORDS EXIST.
	IIF(PSH.SKUREQUIRED = 'Y' AND PSD.ALTERNATESKU IS NULL,						'SKU REQUIRED/',					'') + 
	IIF(ISNULL(PSD.ALTERNATESKU,'') <> ISNULL(@SKU,''),							'SKU DIFFERENT FROM PO/',			'') + 
	IIF(PSH.RETAILREQUIRED = 'Y' AND PSD.RETAILPRICE IS NULL,					'RETAIL REQUIRED/',					'') + 
	IIF(PSH.ALLOWUNSPECIFIED = 'N' AND PSD.ROWID IS NULL,						'UNSPECIFICED ITEM NOT ALLOWED',	'') 
		AS VIOLATION,									--> Special Import related field  
	--USER MAINTAINED FIELDS: 
	'Y' AS IMPORTYN,									--> Special Import related field 
	1 AS CLOSEHEADER,	--OH.USERDEFINEDQUANTITY_20,	--> Special Import related field 
	1 AS CLOSEDETAIL,	--OD.USERDEFINEDQUANTITY_10, 	--> Special Import related field 
	--SUBSTRING(SEA.SEASONCODE,4,3)+RIGHT(SEA.SEASONCODE,2) AS DEFAULTLOT,
	SUBSTRING(SEA.SEASONCODE,4,3)
	+	LEFT(SEA.SEASONCODE,3)
	+	RIGHT(SEA.SEASONCODE,2) AS PROFILECODE,			--> USER MAINTAINED FIELD 
	CAST('>PULLRESERVE' AS CHAR(12)) AS PULLRESERVE,	--> USER MAINTAINED FIELD 
	ZONCOD.CODE AS ZONEOVERRIDE,						--> USER MAINTAINED FIELD 
	PSH.PRICESCHEDULECODE,								--> USER MAINTAINED FIELD 

	--HEADER RECORD REQUIRED FIELDS:
	WH.IDENTITYID AS WAREHOUSEID,		
	CUST.IDENTITYID AS CUSTOMERID, 
	CONS.IDENTITYID AS CONSIGNEEID, 
	'>ORDEREDBY' AS ORDEREDBY,							--OH.USERDEFINEDREFERENCE_3
	@PONUMBER AS PURCHASEORDERNUMBER,					--OH.PURCHASEORDERNUMBER 
	CAST(@PODATE AS DATETIME) AS TRANSACTIONDATE,		--OH.TRANSACTIONDATE 
	CAST(@REQUESTDATE AS DATETIME) AS REQUESTDATE,		--OH.SHIPPINGDATE 
	CAST('WEEK OF' AS VARCHAR(10)) AS REQUESTDATETYPE,	--OH.USERDEFINEDCODE_1 {NULL, ASAP, DEL DATE, LOAD DATE, MUST RECBY, WEEK OF}

	--DETAIL RECORD REQUIRED FIELDS: 
	@LINENUMBER AS LINENUMBER,							--OD.LINENUMBER 
	PSD.ALTERNATESKU AS CUSTOMERSKU, 
	DBO.FN_FORMATUPC(PSH.ROWID, WH.ROWID, ITM.ROWID) AS UPCNO, 
	ITM.ITEMCODE,	--MIGHT RETURN MULTIPLE ITEMS IF SKUS ARE SHARED
	ITM.REFERENCE_1 AS COMMONNAME, 
	@QTYORDERED AS QUANTITYORDERED,						--OD.QUANTITYORDERED 
	@LANDEDPRICE AS LANDEDPRICE,						

	--REFERENCE FIELDS: 
	IDTERMS.TERMSCODE, 
	CUST.IDGROUP, 
	ICONS.USERDEFINEDREFERENCE_2 AS STORENUMBER, 
	ICONS.USERDEFINEDREFERENCE_6 AS GLN#, 
	CUST.NAME AS CUSTOMERNAME, 
	CONS.NAME AS CONSIGNEENAME, 
	TRIM(ACONS.CITY) AS CONSIGNEECITY, 
	TRIM(ACONS.STATE) AS CONSIGNEESTATE, 
	@CANCELDATE AS CANCELDATE,							--OH.CANCELDATE 
	CAST(@SHIPNOTBEFORE AS DATETIME) AS SHIPNOTBEFORE,	--OH.USERDEFINEDDATE_19 
	CAST(@SHIPNOTAFTER AS DATETIME) AS SHIPNOTAFTER,	--OH.USERDEFINEDDATE_20 
	'>PICKNOTE' AS PICKNOTE,							--NULLIF(TRIM(CONVERT(VARCHAR(256),OD.COMMENT)),'')

	--GET.WAREHOUSEID, GET.IDGROUP, GET.DEPT, GET.VENDOR, GET.DUNN, 
	--PO VALUES:
	@VENDOR AS PO_VENDOR,				--OH.USERDEFINEDREFERENCE_17 
	@DEPT AS PO_DEPT,					--OH.USERDEFINEDREFERENCE_18 
	@STORENUMBER AS PO_STORENUMBER,		--OH.USERDEFINEDREFERENCE_19 
	@GLN AS PO_GLN,						--OH.USERDEFINEDREFERENCE_20 
	@LINENUMBER AS PO_LINENUMBER,		--OD.USERDEFINEDQUANTITY_9 
	@SKU AS PO_SKU,						--OD.USERDEFINEDREFERENCE_10 

	--HEADER RECORD FOREIGN KEYS:
	WH.ROWID AS HDR_R_FMSHIPPER, CUST.ROWID AS HDR_R_CUSTOMER, CONS.ROWID AS HDR_R_SHIPPER, 
	--DETAIL RECORD FOREIGN KEYS:
	ITM.R_PRODUCTCATEGORY AS DTL_R_PRODUCTCATEGORY, ITM.ROWID AS DTL_R_ITEM
	, ITM_WH.ROWID AS DTL_R_WAREHOUSE, LOT.ROWID AS DTL_R_LOT--CAN I PROVIDE DTL_R_LOT AT THIS TIME????
--SELECT *
FROM GNC_EDI_TRANSLATION GET (NOLOCK) 
JOIN IDMASTER CUST (NOLOCK) ON CUST.IDGROUP = GET.IDGROUP 
JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = CUST.ROWID
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ISNULL(ICONS.USERDEFINEDREFERENCE_2,'') = ISNULL(@STORENUMBER,'') AND ISNULL(ICONS.USERDEFINEDREFERENCE_6,'') = ISNULL(@GLN,'')
JOIN IDMASTER CONS (NOLOCK) ON CONS.IDGROUP = GET.IDGROUP AND CONS.ROWID = ICONS.R_IDENTITY
JOIN IDTYPESLINKS TCONS (NOLOCK) ON TCONS.R_IDENTITY = CONS.ROWID AND TCONS.IDTYPE = '02'
JOIN IDADDRESS ACONS (NOLOCK) ON ACONS.ROWID = ISNULL(TCONS.R_ADDRESS, CONS.R_DEFAULTADDRESS)
LEFT JOIN IDTERMS (NOLOCK) ON IDTERMS.ROWID = ICUST.R_TERMS--ISNULL(OH.R_TERMS, ICUST.R_TERMS)
JOIN IDMASTER WH (NOLOCK) ON WH.IDENTITYID = GET.WAREHOUSEID
LEFT JOIN IDCONSIGNEESHIPPERZONE SZ (NOLOCK) ON SZ.R_CONSIGNEE = CONS.ROWID AND SZ.R_SHIPPER = WH.ROWID
LEFT JOIN IMPRICESCHEDULEHEADER PSH (NOLOCK) ON PSH.ROWID = ISNULL(SZ.R_PRICESCHEDULE, ICONS.R_PRICESCHEDULE)
LEFT JOIN IMPRICESCHEDULEDETAIL PSD (NOLOCK) ON PSD.R_PRICESCHEDULEHEADER = PSH.ROWID AND PSD.ALTERNATESKU = @SKU /*PSD.R_ITEM = OD.R_ITEM*/ AND PSD.EXPIRATIONDATE >= GETDATE()
LEFT JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = PSD.R_ITEM
LEFT JOIN IDMASTER ITM_WH (NOLOCK) ON ITM_WH.ROWID = ITM.R_WAREHOUSE 
LEFT JOIN RTZONETABLECODES ZONCOD (NOLOCK) ON ZONCOD.ROWID = ISNULL(PSH.R_ZONE, SZ.R_ZONE)--ISNULL(ISNULL(OH.R_ZONEFREIGHTRATEOVERRIDE, PSH.R_ZONE), SZ.R_ZONE)
JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID
JOIN IMSEASONCODE SEA (NOLOCK) ON SUBSTRING(SEA.SEASONCODE,4,2) = WH.IDENTITYID AND @REQUESTDATE BETWEEN SEA.STARTDATE AND SEA.ENDDATE
LEFT JOIN IMLOT LOT (NOLOCK) ON LOT.LOTCODE = SUBSTRING(SEA.SEASONCODE,4,3)+RIGHT(SEA.SEASONCODE,2)
WHERE ISNULL(GET.VENDOR,'') = ISNULL(@VENDOR,'') AND ISNULL(GET.DEPT,'') = ISNULL(@DEPT,'')
/* 
Notes for JoAnne:
TABLENAME			UDFIELD					DATATYPE	NAME/DESCRIPTION
-------------------	-----------------------	---------	-----------------
OMTRANSACTIONHEADER	USERDEFINEDDATE_19		DATETIME	SHIPNOTBEFORE	
OMTRANSACTIONHEADER	USERDEFINEDDATE_20		DATETIME	SHIPNOTAFTER	
OMTRANSACTIONHEADER	USERDEFINEDREFERENCE_17	CHAR(9)		PO_VENDOR			
OMTRANSACTIONHEADER	USERDEFINEDREFERENCE_18	CHAR(5)		PO_DEPT				
OMTRANSACTIONHEADER	USERDEFINEDREFERENCE_19	CHAR(4)		PO_STORENUMBER		
OMTRANSACTIONHEADER	USERDEFINEDREFERENCE_20	CHAR(13)	PO_GLN				
OMTRANSACTIONHEADER	USERDEFINEDQUANTITY_20				CLOSEHEADER

OMTRANSACTIONDETAIL	USERDEFINEDREFERENCE_10	CHAR(15)	PO_SKU				
OMTRANSACTIONDETAIL	USERDEFINEDQUANTITY_9	INT			PO_LINENUMBER		
OMTRANSACTIONDETAIL	USERDEFINEDQUANTITY_10				CLOSEDETAIL

Questions for Erica:
PROFILECODE:		BASE UPON THE REQUESTDATE AND WAREHOUSE	[*NO VALIDATION BUT USER CAN OVERRIDE THIS]
PULLRESERVE:		USING DEFAULT VALUE: '>PULLRESERVE'		[USER MUST CHANGE THIS FIELD]
ZONEOVERRIDE:		USING DEFAULT PRICESCHEDULE>CONSIGNEE	[*NO VALIDATION BUT USER CAN OVERRIDE THIS]
PRICESCHEDULE:		USING DEFAULT SHIPPER>CONSIGNEE			[*NO VALIDATION BUT USER CAN OVERRIDE THIS]
ORDEREDBY:			USING DEFAULT VALUE: '>ORDEREDBY'		[USER MUST CHANGE THIS FIELD]
REQUESTDATETYPE:	USING DEFAULT VALUE:'WEEK OF'			[*NO VALIDATION]{NULL/ASAP/DEL DATE/LOAD DATE/MUST RECBY/WEEK OF}
TERMSCODE:			USING DEFAULT CUSTOMER TERMS			[*NO VALIDATION BUT USER CAN OVERRIDE THIS]
ITEMCODE:			USING DEFAULT FROM SKU					[MIGHT RETURN MULTIPLE RECORDS WITH SAME LINENUMBER?]
PICKNOTE:			USING DEFAULT VALUE '>PICKNOTE'			[USER MUST CHANGE THIS FIELD]
*/
/*RURAL KING MAPPED VALUES:
POVALUES			OH/OD FIELDS									REFERENCE
----------------	--------------------------------------------	-----------------
@PONUMBER,			OH.PURCHASEORDERNUMBER	
@PODATE,			OH.TRANSACTIONDATE		
@REQUESTDATE,		OH.SHIPPINGDATE			
--@CANCELDATE,		OH.CANCELDATE				
@NOTBEFOREDATE,		OH.USERDEFINEDDATE_19					
--@NOTAFTERDATE,	OH.USERDEFINEDDATE_20					
@COMMENTS,			OH.COMMENT				
@EXTRACOMMENTS,		OH.USERDEFINEDCOMMENT		
@VENDOR				OH.USERDEFINEDREFERENCE_17 AS PO_VENDOR			GET.VENDOR
--@DEPT				OH.USERDEFINEDREFERENCE_18 AS PO_DEPT			GET.DEPT
@STORENUMBER,		OH.USERDEFINEDREFERENCE_19 AS PO_STORENUMBER	ICONS.UDR_2
--@GLN,				OH.USERDEFINEDREFERENCE_20 AS PO_GLN			ICONS.UDR_6
@LINENUMBER,		OD.USERDEFINEDQUANTITY_9 AS PO_LINENUMBER		OD.LINENUMBER
@LINENUMBER,		OD.LINENUMBER
@QTYORDERED,		OD.QUANTITYORDERED		
@LANDEDPRICE,			OD.USERDEFINEDQUANTITY_8 AS PO_LANDEDPRICE		
@SKU,				OD.USERDEFINEDREFERENCE_10 AS PO_SKU			PSD.ALTERNATESKU

*/
