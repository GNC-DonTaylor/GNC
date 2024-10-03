--CUSTOMAVAILABILITY__FN_SEASONDATES_TABLE
USE [GreenleafApps]
GO

/****** Object:  UserDefinedFunction [CustomAvailability].[fn_SeasonDates_Table]    Script Date: 7/29/2024 9:33:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Scottie Wilcoxson
-- Create date: Feb 26, 2021
-- Description:	Builds start and end dates for seasons
-- Added +1 to Year for 2023 seasons to calculate correctly
-- Modified by Don Taylor:
-- To: Use a table to derive dates per JoAnne
-- =============================================
CREATE OR ALTER FUNCTION [CustomAvailability].[fn_SeasonDates_Table] 
(	

)
RETURNS TABLE 
AS
RETURN 
(

-- New Code 2023-08-07
-- If current month is in 8-12, then sales year is a future year
-- If current month is in 1-7, then sales year is the current year 
-- modded some of the calcs to get the right for S1 2024  -- atw 1/29/2024

WITH YearModifier AS 
( 
SELECT CASE WHEN MONTH(GetDate()) BETWEEN 1 AND 7  THEN 1 -- Sale year = calendar year 
          WHEN MONTH(GetDate()) BETWEEN 8 AND 12 THEN 0 -- Sale Year = calendar year + 1
          END		AS BeginYearOffset
       , CASE WHEN MONTH(GetDate())  BETWEEN 1 AND 7  THEN 0 -- Sale year = calendar year 
              WHEN MONTH(GetDate()) BETWEEN 8 AND 12 THEN 1 -- Sale Year = calendar year + 1
          END		AS EndYearOffset
)

--I THINK I WAS GIVEN THE WRONG TABLE TO CREATE THIS FUNCTION
/*
SELECT *
,
	SeasonId, 
	SeasonCode, 
	BeginDate, 
	EndDate,
	YearModifier.BeginYearOffset,
	YearModifier.EndYearOffset

FROM [GreenleafDW].ETL.TimeCalendarYear AS YearTable
JOIN YearModifier ON 1=1
WHERE YearTable.FullDateKey = GETDATE()
*/


SELECT SeasonId
	 , SeasonCode
	 , CASE WHEN SEASONCODE = 'S1' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate())-BeginYearOffset, BeginMonth, BeginDay, 0, 0, 0,0) 
			WHEN SEASONCODE = 'U1' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), BeginMonth, BeginDay, 0, 0, 0,0) 
			WHEN SEASONCODE = 'F1' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate())-0, BeginMonth, BeginDay, 0, 0, 0,0) 
			WHEN SEASONCODE = 'U2' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), BeginMonth, BeginDay, 0, 0, 0,0) 
			ELSE DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), BeginMonth, BeginDay, 0, 0, 0,0) 
		END AS BeginDate
	 , CASE WHEN SEASONCODE = 'S1' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), EndMonth, EndDay, 0, 0, 0,0) 
			WHEN SEASONCODE = 'U1' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), EndMonth, EndDay, 0, 0, 0,0) 
			WHEN SEASONCODE = 'F1' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate())-0, EndMonth, EndDay, 0, 0, 0,0) 
			WHEN SEASONCODE = 'U2' 
	        THEN DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), EndMonth, EndDay, 0, 0, 0,0) 
			ELSE DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate()), EndMonth, EndDay, 0, 0, 0,0) 
		END AS EndDate
	  ,  YearModifier.BeginYearOffset
	  ,  YearModifier.EndYearOffset
   FROM [CustomAvailability].[Seasons]
   JOIN YearModifier ON 1=1

/*-- original code 
	select SeasonId,
	SeasonCode,
	DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate())-YearModifier, BeginMonth, BeginDay, 0, 0, 0,0) as BeginDate,
	DATETIMEFROMPARTS(CustomAvailability.fn_saleyear(getdate())-YearModifier, EndMonth, EndDay, 0, 0, 0, 0) as EndDate
from [CustomAvailability].[Seasons]
*/



)
GO


