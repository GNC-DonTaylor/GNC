USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_OMCHECKMINZONEFREIGHT]    Script Date: 5/17/2021 8:26:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



------------------------------
-- FUNCTION: [FN_OMCHECKMINZONEFREIGHT]
------------------------------
-- RETURNS THE GREATER OF ACTUAL FREIGHT OR MINIUMIM FREIGHT FOR OM Transaction
--Per Donny Johnson, only Zone Line item freight is considered for freight minimums
------------------------------
-- JoAnne Brown 2021/04/26
------------------------------

CREATE OR ALTER   FUNCTION [dbo].[FN_OMCHECKMINZONEFREIGHT]
(	@OHROWID UNIQUEIDENTIFIER
)	RETURNS DECIMAL(29,10)
AS
BEGIN
	DECLARE @RESULT  DECIMAL(29,10)
	DECLARE @MIN     DECIMAL(29,10)
	DECLARE @ACTUAL  DECIMAL(29,10)

	IF @OHROWID IS NULL 
		RETURN NULL
	
	
SET @MIN = (SELECT [dbo].[FNIM_GETFREIGHTMINCHARGEAMOUNT](th.r_fmshipper, th.r_shipper, th.shippingdate, th.R_ZONEFREIGHTRATEOVERRIDE)
 from  omtransactionheader th (NOLOCK)
where th.ROWID = @OHROWID)

SET @ACTUAL = (select sum((
isnull(case when OMTRANSACTIONHEADER.STAGE in ('A', 'S', 'C') then 
isnull(OMTRANSACTIONDETAIL.QUANTITYSHIPPED, 0) else 
isnull(OMTRANSACTIONDETAIL.QUANTITYORDERED, 0) end, 0)
) * OMTRANSACTIONDETAIL.FREIGHTRATEPERITEM)
 from  omtransactiondetail (NOLOCK) join
 omtransactionheader (NOLOCK) on omtransactionheader.rowid = omtransactiondetail.R_TRANSACTIONHEADER
 where R_TRANSACTIONHEADER =  @OHROWID)

SET @RESULT =IIF( @ACTUAL > @MIN,@ACTUAL, @MIN)
    
	RETURN @RESULT
END
GO


