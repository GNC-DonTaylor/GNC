------------------------------
-- FUNCTION: FN_SALEYEAR
------------------------------
-- RETURNS THE 4-DIGIT SALEYEAR OF THE DATE PARAMETER PASSED TO IT
-- NULL DATE ASSUMES CURRENT DATE USING GETDATE()
------------------------------
-- DON TAYLOR @ 05/12/2020
------------------------------
CREATE OR ALTER   FUNCTION [dbo].[FN_SALEYEAR]
( @INDATE DATETIME
) RETURNS INTEGER
AS
BEGIN
	DECLARE @RESULT INTEGER
	IF @INDATE IS NULL 
		SET @INDATE = GETDATE()

	SET @RESULT = DATEPART(YEAR, DATEADD(month,5,@INDATE))
	RETURN @RESULT
END
GO


