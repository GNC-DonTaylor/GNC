USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_GETEFFECTIVEDATEPCD]    Script Date: 5/17/2021 8:26:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



------------------------------
-- FUNCTION: FN_GETEFFECTIVEDATEPCD
------------------------------
-- Pass in today's date and return  price schedule start date for most current schedule for reprice SP
------------------------------
-- 2021/04/12 JoAnne Brown
------------------------------
CREATE OR ALTER   FUNCTION [dbo].[FN_GETEFFECTIVEDATEPCD]
( @INDATE DATETIME
) RETURNS DATETIME
AS
BEGIN
	-- LOCAL PARAMETERS --
	DECLARE @RESULT		DATETIME

	IF @INDATE IS NULL 
		SET @INDATE = GETDATE()

	BEGIN	
		  SELECT @RESULT =MAX(EFFECTIVEDATE) from IMPRICECODESDETAIL (NOLOCK) where @INDATE > EFFECTIVEDATE
	END
	RETURN @RESULT
END

GO


