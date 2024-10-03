------------------------------
-- FUNCTION: FN_ARTVERSIONNUM
-- THIS ALLOWS ME TO USE VERSION LOGIC WITHIN THE ART TOOL BECAUSE STRING LITERALS DON'T WORK, NUMBERS DO.
------------------------------
-- RETURNS THE ARTVERSIONNUM OF THE CUSTOMER ROWID AND DOCTYPE PASSED TO IT
/*
GENERALINVOICE	INVOICE
INVA3/M6/M7		INVOICE1 L Merch Frt Tot Ext
INVA3/M6/M7		INVOICE2 N Merch Frt Tot Ext
INVU2/U3		INVOICE3 L Landed Ext
INVU2/U3		INVOICE4 N Landed Ext
INVSITEONE		INVOICE5 L Merch ExtMerch
*/
------------------------------
-- DON TAYLOR @ 11/30/2020
------------------------------
CREATE OR ALTER FUNCTION [DBO].[FN_ARTVERSIONNUM]
(	@CUSTROWID UNIQUEIDENTIFIER,
	@DOCTYPE VARCHAR(3)
)	RETURNS INT
AS
BEGIN
	DECLARE @RESULT INT
	--IF @CUSTROWID IS NULL 
	--	RETURN NULL
	IF @DOCTYPE IS NULL 
		SET @DOCTYPE = 'INV'
	IF @DOCTYPE = 'INV'
		SET @RESULT = 
			(
			SELECT	CHARINDEX(DBO.FN_ARTVERSION(@CUSTROWID,@DOCTYPE),
							'{Not Defined}<<<<<<<<<<<<<<<<<'+	--{DEFAULT:0}
							'INVOICE1 L Merch Frt Tot Ext<<'+	--1
							'INVOICE2 N Merch Frt Tot Ext<<'+	--2
							'INVOICE3 L Landed Ext<<<<<<<<<'+	--3
							'INVOICE4 N Landed Ext<<<<<<<<<'+	--4
							'INVOICE5 L Merch ExtMerch<<<<<'	--5
							)/30--12
			FROM IDCUSTOMER ICUST (NOLOCK)
			WHERE ICUST.R_IDENTITY = @CUSTROWID
			AND	ICUST.OMINVOICEREPORTTYPE = 'C'
			) 
/*
							'{Not Defined}<<<<<<<<<<<<<<<<<'+	--{DEFAULT:0}
							'DELIVER1  N Merch ExtM PGSort<'+	--1
							'DELIVER2  L Merch ExtM PGSort<'+	--2
							'DELIVER3  N Merch *C<<<<<<<<<<'+	--3
							'DELIVER4  N Merch SA<<<<<<<<<<'+	--4
							'DELIVER5  N NoPrc PGSort<<<<<<'+	--5
							'DELIVER6  N noPrc 0*C<<<<<<<<<'+	--6
							'DELIVER7  N G PGSort<<<<<<<<<<'+	--7
							'DELIVER8  N Landed PGSort<<<<<'+	--8
							'DELIVER9  L Landed PGSort<<<<<'+	--9
							'DELIVER10 N 3 PGSort<<<<<<<<<<'+	--10
							'DELIVER11 N Landed *C<<<<<<<<<'+	--11
*/
	IF @DOCTYPE = 'DEL'
		SET @RESULT = 
			(
			SELECT	CHARINDEX(DBO.FN_ARTVERSION(@CUSTROWID,@DOCTYPE),
							'{Not Defined}<<<<<<<<<<<<<<<<<'+	--{DEFAULT:0}
							'DELIVER_NMPC<<<<<<<<<<<<<<<<<<'+	--1
							'DELIVER_LMPC<<<<<<<<<<<<<<<<<<'+	--2
							'DELIVER_NM*C<<<<<<<<<<<<<<<<<<'+	--3
							'DELIVER_NMSA<<<<<<<<<<<<<<<<<<'+	--4
							'DELIVER_N0PC<<<<<<<<<<<<<<<<<<'+	--5
							'DELIVER_N0*C<<<<<<<<<<<<<<<<<<'+	--6
							'DELIVER_NGPC<<<<<<<<<<<<<<<<<<'+	--7
							'DELIVER_NTPC<<<<<<<<<<<<<<<<<<'+	--8
							'DELIVER_LTPC<<<<<<<<<<<<<<<<<<'+	--9
							'DELIVER_N3PC<<<<<<<<<<<<<<<<<<'+	--10
							'DELIVER_NT*C<<<<<<<<<<<<<<<<<<'+	--11
							'DELIVERY RECEIPT<<<<<<<<<<<<<<'	--12 *-TEST
							)/30--12
			FROM IDCUSTOMER ICUST (NOLOCK)
			WHERE ICUST.R_IDENTITY = @CUSTROWID
			AND	ICUST.OMPICKINGSLIPREPORTTYPE = 'C'
			) 
	IF @DOCTYPE = 'ACK'
		SET @RESULT = 
			(
			SELECT CHARINDEX(DBO.FN_ARTVERSION(@CUSTROWID,@DOCTYPE),
							'{Not Defined}<<<<<<<<<<<<<<<<<'+	--{DEFAULT:0}
							'ACKNOWL1 N All Prices PGSort<<'+	--1
							'ACKNOWL2 L All Prices PGSort<<'+	--2
							'ACKNOWL3 N All Prices<<<<<<<<<'+	--3
							'ACKNOWL4 L All Prices<<<<<<<<<'+	--4
							'ACKNOWL5 N Landed Only PGSort<'+	--5
							'ACKNOWLEDGEMENT<<<<<<<<<<<<<<<'	--6 *-TEST
							)/30--12
			FROM IDCUSTOMER ICUST (NOLOCK)
			WHERE ICUST.R_IDENTITY = @CUSTROWID
			AND	ICUST.OMORDERACKNREPORTTYPE = 'C'
			) 
	RETURN ISNULL(@RESULT,0)
END
