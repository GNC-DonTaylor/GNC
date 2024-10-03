------------------------------
-- FUNCTION: FN_ONHANDROLLUP
-- 
-- FN_ONHANDROLLUP(ITEMROWID,NUMERIC OR [PY/CY/NY/NULL=PY+CY],[X/Y/Z/F/S/U/F1..U3/NULL=FSU/%=ALL],[HSFILTER/NOFILTER=NULL])
------------------------------
-- RETURNS THE ONHAND QTY FOR THE @LOTYEAR, @LOTSEASON PARAMETERS PASSED TO IT:
--		USE NUMERIC UNLESS YOU LITERALLY WANT TO FORCE THE CALCULATION ALGORITHM:
--			NUMERIC @LOTYEAR WILL ROLLUP PY+CY FOR VALUES <= CURRENTYEAR, AND ROLLUP @LOTYEAR FOR ALL OTHERS
--			NULL @LOTYEAR WILL ROLLUP PY+CY REGARDLESS
------------------------------
-- DON TAYLOR @ 03/13/2024
------------------------------
CREATE OR ALTER   FUNCTION [DBO].[FN_ONHANDROLLUP]
(	@ITMROWID UNIQUEIDENTIFIER,
	@LOTYEAR VARCHAR(2),
	@LOTSEASON VARCHAR(3),
	@HSFILTER VARCHAR(1)
) RETURNS BIGINT 
AS
BEGIN
	DECLARE @RESULT BIGINT 
	DECLARE @CY VARCHAR(2)

	IF @ITMROWID IS NULL 
		RETURN NULL
	IF @LOTSEASON IS NULL
		SET @LOTSEASON = 'FSU'
	IF @HSFILTER IS NULL
		SET @HSFILTER = '%'
	SET @CY = TRIM(STR(DBO.FN_SALEYEAR(NULL) % 100))
	IF @LOTYEAR IS NULL
		SET @LOTYEAR = @CY
	BEGIN
		IF @LOTSEASON = 'FSU'
			BEGIN --MULTIPLE LOTSEASON CALCULATIONS--FSU with Wildcards
				SET @RESULT =
				(
					SELECT 
						DBO.FN_ONHANDROLLUP(@ITMROWID,@LOTYEAR,'F%',@HSFILTER) +
						DBO.FN_ONHANDROLLUP(@ITMROWID,@LOTYEAR,'S%',@HSFILTER) +
						DBO.FN_ONHANDROLLUP(@ITMROWID,@LOTYEAR,'U%',@HSFILTER)
				)
			END
		ELSE
			BEGIN --SINGLE LOTSEASON CALCULATIONS--
				IF ISNUMERIC(@LOTYEAR) = 1
					BEGIN --NUMERIC VALUE PASSED AS @LOTYEAR
						IF @LOTYEAR <= @CY
							SET @RESULT = 
							( --COMBINED CURRENT/PREVIOUS YEARS
								SELECT	SUM(DBO.FN_ONHAND(@ITMROWID, VLOT.ROWID)) 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @ITMROWID 
								AND		ISNULL(VLOT.USERDEFINEDCODE_3,'') LIKE @HSFILTER
								AND		SUBSTRING(VLOT.LOTCODE,4,2) LIKE @LOTSEASON
								AND		SUBSTRING(VLOT.LOTCODE, 1, 2) <= @CY
							)
						ELSE
							SET @RESULT = 
							( --USE LOTYEAR VALUES ONLY
								SELECT	SUM(DBO.FN_ONHAND(@ITMROWID, VLOT.ROWID)) 
								FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
								WHERE	VLOT.R_ITEM = @ITMROWID 
								AND		ISNULL(VLOT.USERDEFINEDCODE_3,'') LIKE @HSFILTER
								AND		SUBSTRING(VLOT.LOTCODE,4,2) LIKE @LOTSEASON
								AND		SUBSTRING(VLOT.LOTCODE, 1, 2) = @LOTYEAR
							)
					END
--------------------------------------------------------------------------
				-- LITERAL VALUES PASSED AS @LOTYEAR
				IF @LOTYEAR = 'PY'
					SET @RESULT = 
					( --PREVIOUS YEAR
						SELECT	SUM(DBO.FN_ONHAND(@ITMROWID, VLOT.ROWID)) 
						FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
						WHERE	VLOT.R_ITEM = @ITMROWID 
						AND		ISNULL(VLOT.USERDEFINEDCODE_3,'') LIKE @HSFILTER
						AND		SUBSTRING(VLOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		SUBSTRING(VLOT.LOTCODE, 1, 2) < @CY
					)
				IF @LOTYEAR = 'CY'
					SET @RESULT = 
					( --CURRENT YEAR
						SELECT	SUM(DBO.FN_ONHAND(@ITMROWID, VLOT.ROWID)) 
						FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
						WHERE	VLOT.R_ITEM = @ITMROWID 
						AND		ISNULL(VLOT.USERDEFINEDCODE_3,'') LIKE @HSFILTER
						AND		SUBSTRING(VLOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		SUBSTRING(VLOT.LOTCODE, 1, 2) = @CY
					)
				--IF @LOTYEAR IS NULL
				--	SET @RESULT = 
				--	( --COMBINED CURRENT/PREVIOUS YEARS
				--		SELECT	SUM(DBO.FN_ONHAND(@ITMROWID, VLOT.ROWID)) 
				--		FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
				--		WHERE	VLOT.R_ITEM = @ITMROWID 
				--		AND		ISNULL(VLOT.USERDEFINEDCODE_3,'') LIKE @HSFILTER
				--		AND		SUBSTRING(VLOT.LOTCODE,4,2) LIKE @LOTSEASON
				--		AND		SUBSTRING(VLOT.LOTCODE, 1, 2) <= @CY
				--	)
				--IF @LOTYEAR = 'NY'
				--	SET @RESULT = 
				--	( --NEXT YEAR
				--		SELECT	SUM(DBO.FN_ONHAND(@ITMROWID, VLOT.ROWID)) 
				--		FROM	VW_IMLOTVIEW2 VLOT (NOLOCK) 
				--		WHERE	VLOT.R_ITEM = @ITMROWID 
				--		AND		ISNULL(VLOT.USERDEFINEDCODE_3,'') LIKE @HSFILTER
				--		AND		SUBSTRING(VLOT.LOTCODE,4,2) LIKE @LOTSEASON
				--		AND		SUBSTRING(VLOT.LOTCODE, 1, 2) = @CY + 1
				--	)
			END
	END
	RETURN ISNULL(@RESULT,0) 
END
