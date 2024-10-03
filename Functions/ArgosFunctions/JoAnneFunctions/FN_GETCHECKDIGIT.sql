USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_GETCHECKDIGIT]    Script Date: 5/17/2021 8:26:31 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





------------------------------
-- FUNCTION: FN_GETCHECKDIGIT
------------------------------
-- RETURNS UPC CHECKDIGIT
------------------------------
-- JoAnne Brown 2021-2-19
------------------------------
CREATE OR ALTER   FUNCTION [dbo].[FN_GETCHECKDIGIT]
( @UPC VARCHAR(12)
) RETURNS integer 
AS
BEGIN
	DECLARE @RESULT int 
	DECLARE @str VARCHAR(12)
	DECLARE @odd int
	DECLARE @even int
	--add logic to check if 17 long
set @odd = convert(int,substring(@UPC,1,1))+
convert(int,substring(@UPC,3,1))+
convert(int,substring(@UPC,5,1))+
convert(int,substring(@UPC,7,1))+ 
convert(int,substring(@UPC,9,1))+ 
convert(int,substring(@UPC,11,1))

set @even = convert(int,substring(@UPC,2,1))+
convert(int,substring(@UPC,4,1))+
convert(int,substring(@UPC,6,1))+ 
convert(int,substring(@UPC,8,1))+ 
convert(int,substring(@UPC,10,1))+ 
convert(int,substring(@UPC,12,1))

SET @RESULT = (SELECT (10-((@odd*3) + @even) %10))--% replaces MOD function from Oracle

IF (@RESULT =10)
begin
set @RESULT = 0
end

	RETURN convert(int, @RESULT )
END
GO


