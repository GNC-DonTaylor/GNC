USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_GETMASTERROWID]    Script Date: 5/17/2021 8:26:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


------------------------------
-- FUNCTION: FN_GETMASTERROWID
------------------------------
-- RETURNS THE ROWID OF THE IDENTITYID in IDMASTER
------------------------------
-- JoAnne Brown 2021-01-26
------------------------------
CREATE OR ALTER   FUNCTION [dbo].[FN_GETMASTERROWID]
( @IDENTITY VARCHAR(12)
) RETURNS UniqueIdentifier
AS
BEGIN
	DECLARE @RESULT UniqueIdentifier
	IF @IDENTITY IS NULL 
		SET @IDENTITY = ' '

	SET @RESULT = 
		(
			SELECT ROWID
			FROM IDMASTER (NOLOCK)
			WHERE IDENTITYID = @IDENTITY

		)
	RETURN @RESULT
END
GO


