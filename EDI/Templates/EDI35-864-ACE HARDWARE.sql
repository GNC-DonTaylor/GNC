--TEMPLATE: EDI35-864-ACE HARDWARE

--EDI535_864_HEADER (Create Ace Hardware 864 Email Header Record)

DECLARE
@IDGROUP VARCHAR(10)= '35'				, 
@ST01	VARCHAR(3)	= '864'				,	--DOCTYPE 
@BMG01  VARCHAR(2)	= '44'				,	--DOCACTION 
@BMG02  VARCHAR(999) = 'REJECTED INVOICE, CORRECT & RESEND',	--DOCMSG 
@DTM01  VARCHAR(3)	= '003'			,	--DOCDATETYPE 
@DTM02	VARCHAR(8)	= '20230214'	,	--DOCDATE 
@MIT	VARCHAR(20)	= '10-20305-1'--'10-60593'		--INVOICENUMBER

DECLARE @ROWID UNIQUEIDENTIFIER
SET @ROWID = NEWID() 

DECLARE @OHROWID UNIQUEIDENTIFIER
SET @OHROWID = 
	(	SELECT TOP 1 ROWID 
		FROM OMTRANSACTIONHEADER OH (NOLOCK) 
		WHERE @MIT = TRANSACTIONNUMBER
		ORDER BY CHARINDEX(OH.RECORDTYPE,'ZREI')
	)

--SELECT @ROWID AS ROWID -->TEST THE LOOKUPDEFINITION

--POPULATE GNC_EDI_EMAILHEADER:
--INSERT INTO GNC_EDI_EMAILHEADER 
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
	@DTM02 AS DATETIME, 
	@BMG01 + ' - ' + DBO.FN_EDI_CODE_DESCRIPTION('BMG01',@BMG01) AS ACTION, 
	@BMG02 AS REFERENCE, 
	NULL AS RESULT, 
	'INVOICE# ' + @MIT AS INDENTIFIERS, 
	NULL AS SUBJECT
FROM GNC_EDI_TRANSLATION EDI (NOLOCK) 
JOIN OMTRANSACTIONHEADER OH (NOLOCK) ON OH.ROWID = @OHROWID 
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = OH.R_SHIPPER 
WHERE EDI.IDGROUP = @IDGROUP
AND EDI.WAREHOUSEID = '99'--LEFT(@MIT,2) --DERIVE TRANSACTIONNUMBER FROM BCD07 WHEN MULTIPLE VENDORS ARE CREATED FOR ACE IN THE FUTURE. FOR NOW WHID = 99

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--EDI35_864_DETAIL (Create Ace Hardware 864 Email Detail Record)

DECLARE 
@IDGROUP VARCHAR(10)= '535'			,
@ST01	VARCHAR(3)	= '824'			,	--DOCTYPE
@MSG    VARCHAR(999) = 'BLAH BLAH'		--MESSAGE

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
--INSERT INTO GNC_EDI_EMAILDETAIL 
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
	@MSG AS DETAIL
FROM GNC_EDI_TRANSLATION EDI (NOLOCK) 
WHERE EDI.IDGROUP = @IDGROUP
AND EDI.WAREHOUSEID =	LEFT(@TRANSACTIONNUMBER,2)
