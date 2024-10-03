USE [ABECAS_GNC_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[FNIM_GETUSERCALCULATEDFIELDLABELS]    Script Date: 4/9/2021 11:18:41 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---HEADER
CREATE OR ALTER FUNCTION [dbo].[FNIM_GETUSERCALCULATEDFIELDLABELS]
---PARAMS
()
---RESULTHEADER
RETURNS VARCHAR(8000)
---BEGIN
AS
BEGIN
---BODY
/***********************************************************************************/
/*                                                                                 */
/*  Function   : FNIM_GETUSERCALCULATEDFIELDLABELS								   */
/*  Author     : Saad Bin Tahir - 04/01/2021									   */
/*  Description: This function is for used for returning labels for the	           */
/*				 User Calculated SQL Fields Columns								   */
/*                                                                                 */
/***********************************************************************************/
/*                                                                                 */
/*  Revisions:                                                                     */
/*                                                                                 */
/***********************************************************************************/

-- Code to test
-- select [dbo].[FNIM_GETUSERCALCULATEDFIELDLABELS]()

DECLARE @Result VARCHAR(8000)

SET @Result = 'si-LTS~s-LTS~ai-LTS~a-LTS~Season Avail~Season OH~Season Demand~Season In Shipping~Season Supply~User Calculated 10'
--SET @Result = 'User Calculated 1~User Calculated 2~User Calculated 3~User Calculated 4~User Calculated 5~User Calculated 6~User Calculated 7~User Calculated 8~User Calculated 9~User Calculated 10'
---RESULTVALUE
RETURN @RESULT
---FOOTER
END
GO


