--TEMPLATE: EDI535-824

--EDI535_824_HEADER (Create Rural King 824 Email Header Record)

DECLARE
@IDGROUP VARCHAR(10)= '535'				,
@ST01	VARCHAR(3)	= '824'				,	--DOCTYPE
@BGN01  VARCHAR(2)	= '44'				,	--DOCACTION
@BGN02  VARCHAR(30)	= '283327967',--10-53753'		,	--DOCNUMBER
@BGN03  VARCHAR(8)	= '20230214'			,	--DOCDATE
@BGN04  VARCHAR(8)	= '1335'				,	--DOCTIME
@OTI01  VARCHAR(2)	= 'TR'				,	--TRANSCODE
@OTI02  VARCHAR(3)	= 'PR',--'IV'			,	--TRANSTYPE
@OTI03  VARCHAR(30)	= '283327967',--'10-53753'		,	--TRANSNUMBER
@OTI08  VARCHAR(9)	= '2'				,	--GSCNTRLNO
@OTI09  VARCHAR(9)	= '0002'				,	--STCNTRLNO
@TED01  VARCHAR(3)	= '024'				,	--ERRTYPE
@TED02  VARCHAR(60)	= 'Warning Error Code: E SegmentType: SAC'	--ERRMSG

DECLARE @ROWID UNIQUEIDENTIFIER
SET @ROWID = NEWID() 

DECLARE @OHROWID UNIQUEIDENTIFIER
SET @OHROWID = 
	(	SELECT TOP 1 ROWID 
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
		WHERE @BGN02 = 
			(	CASE 
				WHEN @OTI02 = 'IV' THEN TRANSACTIONNUMBER 
				WHEN @OTI02 = 'PR' THEN PURCHASEORDERNUMBER 
			END) 
		ORDER BY CHARINDEX(OH.RECORDTYPE,'ZREI')
	)

--SELECT @ROWID AS ROWID -->TEST THE LOOKUPDEFINITION

--POPULATE GNC_EDI_EMAILHEADER:
INSERT INTO GNC_EDI_EMAILHEADER 
SELECT 
	@ROWID AS ROWID, 
	GETDATE() AS CREATIONDATETIME, 
	'N' AS EMAILSENTFLAG, 
	@ST01 AS DOCTYPE, 
	EDI.IDGROUP, 
	EDI.WAREHOUSEID, 
	OH.TRANSACTIONNUMBER, 
	OH.PURCHASEORDERNUMBER AS PONUMBER, 
	ICONS.USERDEFINEDREFERENCE_2 AS STORENUMBER, 
	@BGN03 AS DATETIME, 
	@BGN01 + ' - ' + DBO.FN_EDI_CODE_DESCRIPTION('BGN01',@BGN01) AS ACTION, 
	@BGN02 AS REFERENCE, 
	@OTI01 + ' - ' + DBO.FN_EDI_CODE_DESCRIPTION('OTI01',@OTI01) AS RESULT, 
	@OTI02 + ' - ' + @OTI03 AS INDENTIFIERS, 
	@TED01 + ' - ' + @TED02 AS SUBJECT
FROM GNC_EDI_TRANSLATION EDI (NOLOCK) 
JOIN OMTRANSACTIONHEADER OH (NOLOCK) ON OH.ROWID = @OHROWID 
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = OH.R_SHIPPER 
WHERE EDI.IDGROUP = @IDGROUP
AND EDI.WAREHOUSEID = WH.IDENTITYID
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--EDI535_824_DETAIL (Create Rural King 824 Email Detail Record)

DECLARE 
@IDGROUP VARCHAR(10)= '535'			,
@ST01	VARCHAR(3)	= '824'			,	--DOCTYPE
@NTE01 VARCHAR(3)	= 'GEN'			,	--MSGTYPE
@NTE02 VARCHAR(80)	= 'ERRORMSG'		--MESSAGE

DECLARE @REMAILHEADER VARCHAR(38)
SET @REMAILHEADER = (	SELECT TOP 1 ROWID 
			FROM GNC_EDI_EMAILHEADER (NOLOCK) 
			ORDER BY CREATIONDATETIME DESC)

DECLARE @TRANSACTIONNUMBER VARCHAR(20)
SET @TRANSACTIONNUMBER = (	SELECT TOP 1 TRANSACTIONNUMBER 
			FROM GNC_EDI_EMAILHEADER (NOLOCK) 
			ORDER BY CREATIONDATETIME DESC)

--SELECT @REMAILHEADER AS REMAILHEADER	-->TEST THE LOOKUPDEFINITION:

--POPULATE GNC_EDI_EMAILDETAIL:
INSERT INTO GNC_EDI_EMAILDETAIL 
SELECT 
	@REMAILHEADER AS R_EMAILHEADER, 
	@ST01 AS DOCTYPE, 
	@IDGROUP AS IDGROUP, 
	EDI.WAREHOUSEID AS WAREHOUSEID,
	@TRANSACTIONNUMBER AS TRANSACTIONUMBER, 
	(	SELECT OH.PURCHASEORDERNUMBER 
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
		WHERE OH.TRANSACTIONNUMBER = @TRANSACTIONNUMBER
		) AS PONUMBER, 
	(	SELECT ICONS.USERDEFINEDREFERENCE_2  
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
		JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = OH.R_SHIPPER 
		WHERE OH.TRANSACTIONNUMBER = @TRANSACTIONNUMBER
		) AS STORENUMBER, 
	(SELECT COUNT(*) FROM GNC_EDI_EMAILDETAIL CNT (NOLOCK) WHERE CNT.R_EMAILHEADER = @REMAILHEADER)+1 AS LINENUMBER, --COUNT MESSAGELINES.
	@NTE01 + ' - ' + @NTE02 AS DETAIL
FROM GNC_EDI_TRANSLATION EDI (NOLOCK) 
WHERE EDI.IDGROUP = @IDGROUP
AND EDI.WAREHOUSEID =	LEFT(@TRANSACTIONNUMBER,2)
