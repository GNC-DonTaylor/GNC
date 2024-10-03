--USE [ABECAS_GNC_TEST]
--GO

--/****** Object:  UserDefinedFunction [dbo].[FNIM_GETUSERCALCULATEDFIELD]    Script Date: 3/10/2021 1:14:38 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO
---
---
---
---
---
---
---
---
---
---
---

---HEADER
CREATE OR ALTER FUNCTION [dbo].[FNIM_GETUSERCALCULATEDFIELD] 
---PARAMS 
( 
@FieldName Varchar(100), 
@R_Lot uniqueidentifier, 
@R_Item uniqueidentifier 
) 
---RESULTHEADER 
RETURNS ABDECIMAL_10 
---BEGIN 
AS 
BEGIN 
---BODY 
/************************************************************************************/ 
/*																					*/ 
/*  Function   : FNIM_GETUSERCALCULATEDFIELD										*/ 
/*  Author     : Saad Bin Tahir - 02/12/2021										*/ 
/*  Description: This function is for used for returning results for the			*/ 
/*				 User Calculated SQL Fields											*/ 
/*																					*/ 
/************************************************************************************/ 
/*																					*/ 
/*  Revisions:																		*/ 
/*																					*/ 
/************************************************************************************/ 

-- Code to test 
-- select [dbo].[FNIM_GETUSERCALCULATEDFIELD]('UserCalculated_1', 'C842462D-F40D-4055-9E87-453FCF2FD101', 'F9E36C4B-BBB7-4E56-8333-8093F480B331') 
-- select [dbo].[FNIM_GETUSERCALCULATEDFIELD]('UserCalculated_1', 'E9820898-543A-4C53-B612-2F16CDC5A2EE', 'C0794C2A-1254-4F03-AD37-E21C1311FFDE') 

	DECLARE @Result ABDECIMAL_10 

	IF @FieldName = 'UserCalculated_1'	--si-LTS 
	BEGIN 
		SET @Result =	( 
						SELECT 
							IIF(CHARINDEX(SUBSTRING(LOTCODE,4,1),'FSU')>0, 
								DBO.FN_SUPPLYROLLUP(@R_Item, LEFT(LOTCODE,2), SUBSTRING(LOTCODE,4,2)+'%', NULL, 'I') - DBO.FN_DEMANDROLLUP(@R_Item, LEFT(LOTCODE,2), SUBSTRING(LOTCODE,4,2)+'%', NULL), 
								--IIF(LEFT(LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								--	DBO.FN_SUPPLYROLLUP(@R_Item,NULL,SUBSTRING(LOTCODE,4,2)+'%',NULL,'I') - DBO.FN_DEMANDROLLUP(@R_Item,NULL,SUBSTRING(LOTCODE,4,2)+'%',NULL), 
								--	DBO.FN_SUPPLY(@R_Item,@R_Lot,'I') - DBO.FN_DEMAND(@R_Item,@R_Lot) 
								--	), 
								0.00) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_2'	--s-LTS 
	BEGIN 
		SET @Result =	( 
						SELECT 
							IIF(CHARINDEX(SUBSTRING(LOTCODE,4,1),'FSU')>0, 
								DBO.FN_SUPPLYROLLUP(@R_Item, LEFT(LOTCODE,2), SUBSTRING(LOTCODE,4,2)+'%', NULL, NULL) - DBO.FN_DEMANDROLLUP(@R_Item, LEFT(LOTCODE,2), SUBSTRING(LOTCODE,4,2)+'%', NULL), 
								--IIF(LEFT(LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								--	DBO.FN_SUPPLYROLLUP(@R_Item,NULL,SUBSTRING(LOTCODE,4,2)+'%',NULL,NULL) - DBO.FN_DEMANDROLLUP(@R_Item,NULL,SUBSTRING(LOTCODE,4,2)+'%',NULL), 
								--	DBO.FN_SUPPLY(@R_Item,@R_Lot,NULL) - DBO.FN_DEMAND(@R_Item,@R_Lot) 
								--	), 
								0.00) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_3'	--ai-LTS 
	BEGIN 
		SET @Result =	( 
						SELECT 
							IIF(CHARINDEX(SUBSTRING(LOTCODE,4,1),'FSU')>0, 
								--ANNUAL LTS FOR SALEYEARS > CURRENT IS NOW FIXED: 
								DBO.FN_SUPPLYROLLUP(@R_Item, LEFT(LOTCODE,2), NULL, NULL, 'I') - DBO.FN_DEMANDROLLUP(@R_Item, LEFT(LOTCODE,2), NULL, NULL), 
								--IIF(LEFT(LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								--	DBO.FN_SUPPLYROLLUP(@R_Item,NULL,NULL,NULL,'I') - DBO.FN_DEMANDROLLUP(@R_Item,NULL,NULL,NULL), 
								--	--Does not return annual LTS for saleyears > current, it just returns the value of the record for now. 
								--	--I will have to expand the ROLLUP functions to pass in a saleyear value as a parameter to fix this. 
								--	DBO.FN_SUPPLY(@R_Item,@R_Lot,'I') - DBO.FN_DEMAND(@R_Item,@R_Lot) 
								--	), 
								0.00) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_4'	--a-LTS 
	BEGIN 
		SET @Result =	( 
						SELECT 
							IIF(CHARINDEX(SUBSTRING(LOTCODE,4,1),'FSU')>0, 
								--ANNUAL LTS FOR SALEYEARS > CURRENT IS NOW FIXED: 
								DBO.FN_SUPPLYROLLUP(@R_Item, LEFT(LOTCODE,2), NULL, NULL, NULL) - DBO.FN_DEMANDROLLUP(@R_Item, LEFT(LOTCODE,2), NULL, NULL), 
								--IIF(LEFT(LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								--	DBO.FN_SUPPLYROLLUP(@R_Item,NULL,NULL,NULL,NULL) - DBO.FN_DEMANDROLLUP(@R_Item,NULL,NULL,NULL), 
								--	--Does not return annual LTS for saleyears > current, it just returns the value of the record for now. 
								--	--I will have to expand the ROLLUP functions to pass in a saleyear value as a parameter to fix this. 
								--	DBO.FN_SUPPLY(@R_Item,@R_Lot,NULL) - DBO.FN_DEMAND(@R_Item,@R_Lot) 
								--	), 
								0.00) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_5'	--Season Available 
	--User Notes:			ONHAND - INSHIP - INREC - UNAPP 
	--Actual Fieldnames:	ON_HAND - OUT_SHIPPED - IN_RECEIVING - OUT_UNAVAILABLE 
	BEGIN 
		SET @Result =	(--SELECT TOP 1 (ON_HAND - OUT_SHIPPED - IN_RECEIVING - OUT_UNAVAILABLE) FROM VW_IMLOTINVENTORYSTATUS WHERE R_LOT = @R_Lot) 
						SELECT 
							IIF( CAST (LEFT(IMLOT.LOTCODE,2) AS INT)  <= DBO.FN_SALEYEAR(NULL)%100, 
							--IIF(LEFT(IMLOT.LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								( 
								SELECT	SUM(VLOT.AVAILABLE) 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @R_Item 
								AND		SUBSTRING(VLOT.LOTCODE,4,2) = SUBSTRING(IMLOT.LOTCODE,4,2) 
								AND		LEFT(VLOT.LOTCODE,2) <= DBO.FN_SALEYEAR(NULL) % 100 
								), ( 
								SELECT	VLOT.AVAILABLE 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @R_Item 
								AND		VLOT.ROWID = @R_Lot 
								)) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_6'	--Season OnHand 
	BEGIN 
		SET @Result =	(--SELECT TOP 1 (ON_HAND) FROM VW_IMLOTINVENTORYSTATUS WHERE R_LOT = @R_Lot) 
						SELECT 
							IIF( CAST (LEFT(IMLOT.LOTCODE,2) AS INT) <= DBO.FN_SALEYEAR(NULL)%100, 
							--IIF(LEFT(IMLOT.LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								( 
								SELECT	SUM(VLOT.ON_HAND) 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @R_Item 
								AND		SUBSTRING(VLOT.LOTCODE,4,2) = SUBSTRING(IMLOT.LOTCODE,4,2) 
								AND		LEFT(VLOT.LOTCODE,2) <= DBO.FN_SALEYEAR(NULL) % 100 
								), ( 
								SELECT	VLOT.ON_HAND 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @R_Item 
								AND		VLOT.ROWID = @R_Lot 
								)) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_7'	--Season Demand 
	BEGIN 
		SET @Result =	( 
						SELECT 
							DBO.FN_DEMANDROLLUP(@R_Item, LEFT(LOTCODE,2), SUBSTRING(LOTCODE,4,2)+'%', NULL) 
							--IIF(LEFT(LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
							--	DBO.FN_DEMANDROLLUP(@R_Item,NULL,SUBSTRING(LOTCODE,4,2)+'%',NULL), 
							--	DBO.FN_DEMAND(@R_Item,@R_Lot) 
							--	) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_8'	--Season In_Shipping 
	--User Notes:			INSHP 
	--Actual Fieldnames:	OUT_SHIPPED 
	BEGIN 
		SET @Result =	(--SELECT TOP 1 (OUT_SHIPPED) FROM VW_IMLOTINVENTORYSTATUS WHERE R_LOT = @R_Lot) 
						SELECT 
							IIF( CAST (LEFT(IMLOT.LOTCODE,2) AS INT) <= DBO.FN_SALEYEAR(NULL)%100, 
							--IIF(LEFT(IMLOT.LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
								( 
								SELECT	SUM(VLOT.OUT_SHIPPED) 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @R_Item 
								AND		SUBSTRING(VLOT.LOTCODE,4,2) = SUBSTRING(IMLOT.LOTCODE,4,2) 
								AND		LEFT(VLOT.LOTCODE,2) <= DBO.FN_SALEYEAR(NULL) % 100 
								), ( 
								SELECT	VLOT.OUT_SHIPPED 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @R_Item 
								AND		VLOT.ROWID = @R_Lot 
								)) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_9'	--SEASON SUPPLY 
	BEGIN 
		SET @Result =	( 
						SELECT 
							DBO.FN_SUPPLYROLLUP(@R_Item, LEFT(LOTCODE,2), SUBSTRING(LOTCODE,4,2)+'%', NULL, NULL) 
							--IIF(LEFT(LOTCODE,2) <= DBO.FN_SALEYEAR(NULL)%100, 
							--	DBO.FN_SUPPLYROLLUP(@R_Item,NULL,SUBSTRING(LOTCODE,4,2)+'%',NULL,NULL), 
							--	DBO.FN_SUPPLY(@R_Item,@R_Lot,NULL) 
							--	) 
						FROM	IMLOT (NOLOCK) 
						WHERE	IMLOT.ROWID = @R_Lot 
						AND		IMLOT.R_ITEM = @R_Item 
						) 
	END 

	IF @FieldName = 'UserCalculated_10' 
	BEGIN 
		SET @Result = NULL 
	END 

	IF @FieldName = 'InflatedSupply'
	BEGIN
		SET @Result = DBO.FN_SUPPLY(@R_Item, @R_Lot, 'I')
	END

	IF @FieldName = 'InflatedDemand'
	BEGIN
		SET @Result = DBO.FN_DEMAND(@R_Item, @R_Lot)
	END


--RESULTVALUE 
RETURN @RESULT 
---FOOTER 
END 
GO 
