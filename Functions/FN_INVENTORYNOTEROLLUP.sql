------------------------------
-- FUNCTION: FN_INVENTORYNOTEROLLUP

--  NOT CURRENTLY BEING USED AT ALL
--  NOT CURRENTLY BEING USED AT ALL
--  NOT CURRENTLY BEING USED AT ALL
--  NOT CURRENTLY BEING USED AT ALL
--  NOT CURRENTLY BEING USED AT ALL

-- FN_INVENTORYNOTEROLLUP(ITEMROWID,[PY/CY/NY/NULL=PY+CY/FY/%=ALL],[X/Y/Z/F/S/U/F1..U1/NULL=FSU/%=ALL],[HSFILTER/NOFILTER=NULL])
------------------------------
-- RETURNS THE INVENTORYNOTE FOR THE @LOTYEAR, @LOTSEASON PARAMETERS PASSED TO IT THAT HAS THE MOST RECENT UPDATEDDATETIME VALUE.
-- @LOTYEAR = NULL	: INCLUDES BOTH PREVIOUS AND CURRENT YEAR NOTES
-- @LOTYEAR = '%'	: INCLUDES ALL LOTYEARS
-- @LOTSEASON = NULL: INCLUDES FS&U LOTSEASON NOTES
-- @LOTSEASON = '%'	: INCLUDES ALL LOTSEASON NOTES (INCLUDING XY&Z)
------------------------------
-- DON TAYLOR @ 05/12/2020
------------------------------
-- REMOVING ALL REFERENCE TO DBO.FN_INVENTORYNOTE() - THIS FUNCTION HAS BEEN DEPRECATED
-- INVENTORYNOTE IS SIMPLY USERDEFINEDREFERENCE_6
------------------------------
CREATE OR ALTER   FUNCTION [DBO].[FN_INVENTORYNOTEROLLUP]
(	@ITMROWID UNIQUEIDENTIFIER,
	@LOTYEAR VARCHAR(2),
	@LOTSEASON VARCHAR(3),
	@INDATE DATETIME--,	@HSFILTER VARCHAR(1)
) RETURNS VARCHAR(103) 
AS
BEGIN
	DECLARE @RESULT VARCHAR(103)

	IF @ITMROWID IS NULL 
		RETURN NULL
	IF @LOTSEASON IS NULL
		SET @LOTSEASON = 'FSU'
	IF @INDATE IS NULL
		SET @INDATE = GETDATE()
	--IF @HSFILTER IS NULL
	--	SET @HSFILTER = '%'
	BEGIN
		IF @LOTSEASON = 'FSU'
			BEGIN --MULTIPLE LOTSEASON CALCULATIONS--FSU with Wildcards
				IF @LOTYEAR = 'PY'
					SET @RESULT = 
					( --PREVIOUS YEAR
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND	(	SUBSTRING(LOT.LOTCODE,4,2) LIKE 'F%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'S%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'U%' )
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) < DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = 'CY'
					SET @RESULT = 
					( --CURRENT YEAR
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND	(	SUBSTRING(LOT.LOTCODE,4,2) LIKE 'F%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'S%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'U%' )
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) = DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = 'NY'
					SET @RESULT = 
					( --NEXT YEAR
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND	(	SUBSTRING(LOT.LOTCODE,4,2) LIKE 'F%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'S%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'U%' )
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) = DBO.FN_SALEYEAR(NULL) % 100 + 1
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR IS NULL
					SET @RESULT = 
					( --COMBINED CURRENT/PREVIOUS YEARS
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND	(	SUBSTRING(LOT.LOTCODE,4,2) LIKE 'F%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'S%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'U%' )
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) <= DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = 'FY'
					SET @RESULT = 
					( --ALL FUTURE YEARS
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND	(	SUBSTRING(LOT.LOTCODE,4,2) LIKE 'F%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'S%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'U%' )
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) > DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = '%'
					SET @RESULT = 
					( --ALL LOTYEARS
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND	(	SUBSTRING(LOT.LOTCODE,4,2) LIKE 'F%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'S%' OR
								SUBSTRING(LOT.LOTCODE,4,2) LIKE 'U%' )
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
			END
		ELSE
			BEGIN --SINGLE LOTSEASON CALCULATIONS--
				IF @LOTYEAR = 'PY'
					SET @RESULT = 
					( --PREVIOUS YEAR
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND		SUBSTRING(LOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) < DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = 'CY'
					SET @RESULT = 
					( --CURRENT YEAR
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND		SUBSTRING(LOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) = DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = 'NY'
					SET @RESULT = 
					( --NEXT YEAR
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND		SUBSTRING(LOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) = DBO.FN_SALEYEAR(NULL) % 100 + 1
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR IS NULL
					SET @RESULT = 
					( --COMBINED CURRENT/PREVIOUS YEARS
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND		SUBSTRING(LOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) <= DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = 'FY'
					SET @RESULT = 
					( --ALL FUTURE YEARS
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND		SUBSTRING(LOT.LOTCODE,4,2) LIKE @LOTSEASON
						AND		CAST (SUBSTRING(LOT.LOTCODE, 1, 2) AS INT) > DBO.FN_SALEYEAR(NULL) % 100
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
				IF @LOTYEAR = '%'
					SET @RESULT = 
					( --ALL LOTYEARS
						SELECT	TOP 1 LOT.USERDEFINEDREFERENCE_6
--						SELECT	TOP 1 DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) 
						FROM	IMLOT LOT (NOLOCK) 
						WHERE	LOT.R_ITEM = @ITMROWID 
						AND		LOT.USERDEFINEDREFERENCE_6 IS NOT NULL
--						AND		DBO.FN_INVENTORYNOTE(@ITMROWID, LOT.ROWID, @INDATE) IS NOT NULL
						AND		SUBSTRING(LOT.LOTCODE,4,2) LIKE @LOTSEASON
						--AND		ISNULL(DBO.FN_HOLDSTOP(@ITMROWID,LOT.ROWID,NULL),'') LIKE @HSFILTER
						ORDER BY	LOT.LASTUPDATEDATETIME DESC,
									LOT.LOTCODE DESC
					)
			END
	END
	RETURN @RESULT 
END
