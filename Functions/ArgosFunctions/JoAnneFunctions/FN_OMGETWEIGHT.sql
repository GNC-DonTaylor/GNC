USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_OMGETWEIGHT]    Script Date: 5/17/2021 8:27:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


------------------------------
-- FUNCTION: [FN_OMGETWEIGHT]
------------------------------
-- RETURNS THE total weight FOR OM Transaction
------------------------------
-- JoAnne Brown 2021/04/26
------------------------------

CREATE OR ALTER   FUNCTION [dbo].[FN_OMGETWEIGHT]
(	@OHROWID UNIQUEIDENTIFIER
)	RETURNS DECIMAL(29,10)
AS
BEGIN
	DECLARE @RESULT  DECIMAL(29,10)

	IF @OHROWID IS NULL 
		RETURN NULL

    select @RESULT = round(IsNull(Sum(case When CharIndex(OMHeader.stage,'A;S;C') > 0 then OMDetail.QuantityShipped else OMDetail.QuantityOrdered end *
                                              Case When Isnull(IMItem.WEIGHTBASISFLAG,'I') = 'L' then isnull(IMLot.GrossWeightQuantity,0) else isnull(IMItem.GrossWeightQuantity,0) end ),0),4)
    FROM OMTRANSACTIONDETAIL (nolock)  OMDetail join
	omtransactionheader OMHeader (nolock) on OMHeader.rowid = OMDetail.R_TRANSACTIONHEADER
    Left OUTER JOIN IMItem (NOLOCK) on (OMDetail.R_Item = IMItem.RowID) and IMItem.CompanyID = 'SB' and IMItem.Module = 'IM' and IMItem.RecordType = 'R'
    Left OUTER JOIN IMLot (NOLOCK) on (OMDetail.R_Lot = IMLot.RowID) and (OMDetail.R_Item = IMLot.R_Item) and IMLot.CompanyID ='SB' and IMLot.Module = 'IM' and IMLot.RecordType = 'R'
    Where OMDetail.DetailType = 'I'
	and OMHeader.rowid = @OHROWID
  
    
	RETURN @RESULT
END
GO


