USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_GETIDENTITYID]    Script Date: 5/17/2021 8:26:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




------------------------------
-- FUNCTION: FN_GETMASTERROWID
------------------------------
-- RETURNS THE IDENTITYID OF THE ROWID in IDMASTER
------------------------------
-- JoAnne Brown 2021-01-26
------------------------------
CREATE OR ALTER   FUNCTION [dbo].[FN_GETIDENTITYID]
( @IROWID UniqueIdentifier
) RETURNS VARCHAR(12)
AS
BEGIN
	DECLARE @RESULT VARCHAR(12)--UniqueIdentifier


	SET @RESULT = 
		(
			SELECT IDENTITYID
			FROM IDMASTER (NOLOCK)
			WHERE ROWID = @IROWID

		)
	RETURN @RESULT
END
GO


