------------------------------
-- FUNCTION: FN_STEPSORT
------------------------------
-- RETURNS THE STEP (OH.UDC2) WITH A SORTORDER APPENDED TO IT
-- SORTS STEVE'S STEPS: RESERVE, WAITING, SHIPPABLE, PTR
------------------------------
-- DON TAYLOR @ 12/18/2020
------------------------------
CREATE OR ALTER FUNCTION [DBO].[FN_STEPSORT]
( @STEP VARCHAR(10)
) RETURNS VARCHAR(12)
AS
BEGIN
	DECLARE @RESULT VARCHAR(12)
	IF @STEP IS NULL 
		SET @STEP = ' '

--They've added on to the list which has broken this function now--
--First character of Step value is no longer unique. So now I have to use DESCRIPTION_2
--SELECT * FROM OMCODES WHERE CODETYPE = '03'
--OMCODES.CODE	OMCODES.DESCRIPTION_1	OMCODES.DESCRIPTION_2
----------------------------------------------------------------
--PREEVAL   	Pre-Evaluation			01 - Prior to Evaluation in Future Stage
--EVALUATION	Evaluation				02 - Set as Future Evaluations begin
--RESERVE   	Reservation				03 - Set at end of Evaluation process
--WAITING   	Waiting					04 - Waiting is within Pending Stage
--SHIPPABLE 	Shippable				05 - Set as Stage advanced to Assigned
--PTR       	Pull Tag Review			06 - Set as PTR Set is created
--PTRCOMP   	PTR Complete			07 - Set as PTR is Completed
--LOADAPPR  	Loading Approval		08 - Approval to begin Loading is given
--BEGPICKCON	Begin Pick Confirm		09 - Set before changes at Pick Confirm.
--COMPLETE  	Complete				10 - Set after Pick Confirm

	SET @RESULT = 
		(
			SELECT LEFT(OMCODES.DESCRIPTION_2,2) + '.' + @STEP
			FROM OMCODES (NOLOCK) 
			WHERE OMCODES.CODETYPE = '03' AND OMCODES.CODE = @STEP

			--SELECT SUBSTRING('0. 1. 2. 3. 4. ',	
			--			1+(CHARINDEX(LEFT(@STEP, 1),' RWSP')-1)*3, 3) + @STEP
		)
	RETURN @RESULT
END
GO


