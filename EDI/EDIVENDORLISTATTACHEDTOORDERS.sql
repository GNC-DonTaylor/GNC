--EDIVENDORLISTATTACHEDTOORDERS select * from omtransactionheader where stage = 'L'
--BEGIN TRAN
	SELECT H.ROWID, H.RECORDTYPE, H.TRANSACTIONTYPE,
	C.IDGROUP, C.IDENTITYID AS CUSTOMERID, C.NAME AS CUSTOMERNAME, 
	H.EDITRANSMITFLAG EDIFLAG, H.TRANSACTIONNUMBER ORDER#, H.PURCHASEORDERNUMBER PO#, H.FMTRIPNUMBER TRIP#, H.STAGE, 
	IC.USERDEFINEDCODE_7 AS WO#_REQ, H.INVENTORYREVIEW INVREVIEW, V.IDENTITYID AS EDIVENDOR--, H.USERDEFINEDREFERENCE_10
	--UPDATE OMTRANSACTIONHEADER SET USERDEFINEDREFERENCE_10 = V.ROWID
	FROM OMTRANSACTIONHEADER H (NOLOCK)
	JOIN IDMASTER C (NOLOCK) ON C.ROWID = H.R_CUSTOMER
	JOIN IDCUSTOMER IC (NOLOCK) ON IC.R_IDENTITY = C.ROWID
	JOIN IDMASTER V (NOLOCK) ON V.IDENTITYID = 'EDI'+TRIM(C.IDGROUP)
	WHERE --c.idgroup=37--TRANSACTIONNUMBER BETWEEN '20-12811' AND '20-12817'
	--and 
	H.INVENTORYREVIEW = 'N'
	ORDER BY H.EDITRANSMITFLAG DESC, RIGHT('0000'+TRIM(C.IDGROUP),4), H.CREATIONDATETIME
--ROLLBACK
--COMMIT
--------------------------------------------Iif(IsNull([WORKORDERREQUIRED]), [WORKORDERREQUIRED], [LOWESSIZE])
/*
The current job task failed. 
Reason - the current queue task failed [Job task: Task 1: EDI Generate 855]
[Queue task State: Failed, ProcessingResult: Could not insert new Export Event record.\n
Task ID: 05a6d9a9-aa6c-4b38-916b-62a404812c70\n
Task State: Processing\n
Task Processing Result Info: \n
Error: Record for exporting is not specified]


BEGIN TRAN
	--SELECT * FROM GNC_LOWES_MEASUREMENT

	INSERT INTO GNC_LOWES_MEASUREMENT
	VALUES (LEFT('94867'+SPACE(30),30), '99.99-GAL BURFORD HOLLY', GETDATE(), 'don_taylor', NULL, NULL, 'A');  
ROLLBACK
COMMIT
*/
--TA Queries for Triggering EDI Generation:
--------------------------------------------
/*
--TA QUERY Event: EDI Order Committed as Invoiced, Trigger: 810
DELETED.RECORDTYPE <> 'Z' AND		--SELECT INSERTED.TRANSACTIONNUMBER, INSERTED.USERDEFINEDREFERENCE_10 FROM OMTRANSACTIONHEADER INSERTED WHERE 
INSERTED.RECORDTYPE = 'Z' AND 
INSERTED.TRANSACTIONTYPE= 'I' AND
INSERTED.USERDEFINEDREFERENCE_10 = 
(  SELECT V.ROWID FROM IDMASTER C (NOLOCK)
   JOIN IDMASTER V ON V.IDENTITYID = 'EDI'+TRIM(C.IDGROUP)
   WHERE C.ROWID = INSERTED.R_CUSTOMER
)

--TA QUERY Event: ReverseEDI Order Stage changed, Trigger: 855
DELETED.STAGE <> INSERTED.STAGE AND		
--SELECT INSERTED.TRANSACTIONNUMBER, INSERTED.STAGE, INSERTED.INVENTORYREVIEW, INSERTED.TRANSACTIONTYPE, INSERTED.R_CUSTOMER, INSERTED.USERDEFINEDREFERENCE_10 FROM OMTRANSACTIONHEADER INSERTED WHERE 
(  INSERTED.STAGE = 'L' OR 
   (  INSERTED.STAGE IN ('A','S','C') AND 
      ISNULL(INSERTED.INVENTORYREVIEW,'') <> 'Y'
   )
) AND
INSERTED.TRANSACTIONTYPE= 'I' AND
INSERTED.R_CUSTOMER = 
(  SELECT R_IDENTITY FROM IDCUSTOMER (NOLOCK) 
   WHERE USERDEFINEDCODE_7 = 'Y') AND
INSERTED.USERDEFINEDREFERENCE_10 = 
(  SELECT V.ROWID FROM IDMASTER C (NOLOCK)
   JOIN IDMASTER V ON V.IDENTITYID = 'EDI'+TRIM(C.IDGROUP)
   WHERE C.ROWID = INSERTED.R_CUSTOMER
)
SELECT R_IDENTITY,USERDEFINEDCODE_7  FROM IDCUSTOMER WHERE R_IDENTITY = 'A7342E2A-5330-41A3-A63A-0B5D8917CAF3' AND USERDEFINEDCODE_7 = 'Y'
SELECT V.ROWID, V.IDENTITYID, C.IDGROUP FROM IDMASTER C JOIN IDMASTER V ON V.IDENTITYID = 'EDI'+TRIM(C.IDGROUP) WHERE C.ROWID = 'A7342E2A-5330-41A3-A63A-0B5D8917CAF3'
*/

