--USE [ABECAS_GNC_PROD]
--GO

/****** Object:  Trigger [dbo].[IMTRANSACTIONLOCATION_UPDATE]    Script Date: 3/15/2024 9:01:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---HEADER
CREATE OR ALTER TRIGGER [dbo].[IMTRANSACTIONLOCATION_UPDATE] ON [dbo].[IMTRANSACTIONLOCATION]
FOR UPDATE
AS
SET NOCOUNT ON

---DEFAULT

-- Declare system variables
DECLARE
  @SYS_DATETIME DATETIME,
  @SYS_USER CHAR(50)
-- SET SYSTEM VARIABLES
SET @SYS_DATETIME = GETDATE()
SET @SYS_DATETIME = DATEADD(MS,(-1) * (DATEPART(MS, @SYS_DATETIME) % 10), @SYS_DATETIME)
SET @SYS_USER = SUBSTRING(RTRIM(SYSTEM_USER), PATINDEX('%\%', RTRIM(SYSTEM_USER))+1, 50)


---BEFORE SYSTEM

---SYSTEM

  IF (NOT UPDATE(LASTUPDATEDATETIME)) OR (NOT UPDATE(LASTUPDATEUSERID))
  BEGIN
    UPDATE IMTRANSACTIONLOCATION
      SET LASTUPDATEDATETIME = @SYS_DATETIME,
        LASTUPDATEUSERID = @SYS_USER
    FROM IMTRANSACTIONLOCATION
      JOIN INSERTED ON (IMTRANSACTIONLOCATION.ROWID = INSERTED.ROWID)
  END


---AFTER SYSTEM
-- 03/11/2022 Saad Tahir
--            Create or update Master Codes from PO Receipt Detail only when Status changes from some 
--            value other then commit (Status != 'Z') to commit (Status = 'Z')
-- 02/10/2022 Dave Yost
--            Changed total for in_backorder to include committed transactions as well 
--            as uncommitted transactions
-- 01/06/2004 Kent Meyer
--            Changed float to decimal(26,10) and added rounding to 2 decimal places
--            Also removed initial if because ROWID will ALWAYS have a value


-- IF ( (SELECT TOP 1 ROWID
--       FROM INSERTED) IS NOT NULL) AND
--      (UPDATE(R_LOCATION)        or

IF (  UPDATE(R_LOCATION)        or
      UPDATE(R_ITEM)            or
      UPDATE(R_LOT)             or
      UPDATE(R_SUBLOT)          or
      UPDATE(R_UNIT)            or
      UPDATE(IN_ORDERED)        or
      UPDATE(OUT_ORDERED)       or
      UPDATE(IN_RECEIVING)      or
      UPDATE(OUT_SHIPPED)       or
      UPDATE(IN_BACKORDER)      or
      UPDATE(OUT_BACKORDER)     or
      UPDATE(IN_UNAVAILABLE)    or
      UPDATE(OUT_UNAVAILABLE)   or
      UPDATE(IN_FUTURE)         or
      UPDATE(OUT_FUTURE)        or
      UPDATE(QUANTITYINVENTORY) or
      UPDATE(RECORDTYPE)        or
      UPDATE(COMPANYID)         or
      UPDATE(STATUS) )
BEGIN
  DECLARE @LocationSummary TABLE
  ( R_LocationSummary UNIQUEIDENTIFIER NULL,
    CompanyID CHAR(2) NULL,
    Module CHAR(2) NULL,
    R_Location UNIQUEIDENTIFIER NULL,
    R_ITEM UNIQUEIDENTIFIER NULL,
    R_LOT UNIQUEIDENTIFIER NULL,
    R_SUBLOT UNIQUEIDENTIFIER NULL,
    R_UNIT UNIQUEIDENTIFIER NULL,
    ON_HAND DECIMAL(26,10) NULL,
    IN_ORDERED DECIMAL(26,10) NULL,
    OUT_ORDERED DECIMAL(26,10) NULL,
    IN_RECEIVING DECIMAL(26,10) NULL,
    OUT_SHIPPED DECIMAL(26,10) NULL,
    IN_BACKORDER DECIMAL(26,10) NULL,
    OUT_BACKORDER DECIMAL(26,10) NULL,
    IN_UNAVAILABLE DECIMAL(26,10) NULL,
    OUT_UNAVAILABLE DECIMAL(26,10) NULL,
    IN_FUTURE DECIMAL(26,10) NULL,
    OUT_FUTURE DECIMAL(26,10) NULL )

  DECLARE @NewTotals TABLE
  ( Pointer UNIQUEIDENTIFIER NULL,
    ON_HAND DECIMAL(26,10) NULL,
    IN_ORDERED DECIMAL(26,10) NULL,
    OUT_ORDERED DECIMAL(26,10) NULL,
    IN_RECEIVING DECIMAL(26,10) NULL,
    OUT_SHIPPED DECIMAL(26,10) NULL,
    IN_BACKORDER DECIMAL(26,10) NULL,
    OUT_BACKORDER DECIMAL(26,10) NULL,
    IN_UNAVAILABLE DECIMAL(26,10) NULL,
    OUT_UNAVAILABLE DECIMAL(26,10) NULL,
    IN_FUTURE DECIMAL(26,10) NULL,
    OUT_FUTURE DECIMAL(26,10) NULL )

  -- Populate Location summary table variable with summarised values from the inserted table
  INSERT INTO @LocationSummary (CompanyID,
                                Module,
                                R_Location,
                                R_ITEM,
                                R_LOT,
                                R_SUBLOT,
                                R_UNIT,
                                ON_HAND,
                                IN_ORDERED,
                                OUT_ORDERED,
                                IN_RECEIVING,
                                OUT_SHIPPED,
                                IN_BACKORDER,
                                OUT_BACKORDER,
                                IN_UNAVAILABLE,
                                OUT_UNAVAILABLE,
                                IN_FUTURE,
                                OUT_FUTURE)
  SELECT INSERTED.CompanyID,
         INSERTED.Module,
         INSERTED.R_Location,
         INSERTED.R_ITEM,
         INSERTED.R_LOT,
         INSERTED.R_SUBLOT,
         INSERTED.R_UNIT,

         -- ON_HAND
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN 0
                WHEN 'Z' THEN ROUND((ISNULL(INSERTED.IN_RECEIVING, 0) - ISNULL(INSERTED.OUT_SHIPPED, 0)) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
              END ),

         -- IN_ORDERED
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.IN_ORDERED, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END ),

         -- OUT_ORDERED
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.OUT_ORDERED, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END ),

         -- IN_RECEIVING
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.IN_RECEIVING, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END  ),

         -- AS OUT_SHIPPED
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.OUT_SHIPPED, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END ),

         -- AS IN_BACKORDER
		 --DSY
         SUM(ROUND(ISNULL(INSERTED.IN_BACKORDER, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)),
		 --SUM( CASE INSERTED.STATUS
         --       WHEN 'O' THEN ROUND(ISNULL(INSERTED.IN_BACKORDER, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
         --       WHEN 'Z' THEN 0
         --     END ),

         -- AS OUT_BACKORDER
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.OUT_BACKORDER, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END ),

         -- AS IN_UNAVAILABLE
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.IN_UNAVAILABLE, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END ),

         -- Out_Unavailable
         SUM( ROUND(ISNULL(INSERTED.OUT_UNAVAILABLE, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2) ),

         -- IN_FUTURE,
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.IN_FUTURE, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END ),

         -- OUT_FUTURE
         SUM( CASE INSERTED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(INSERTED.OUT_FUTURE, 0) * ISNULL(INSERTED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END )
  FROM INSERTED
  WHERE (INSERTED.RECORDTYPE in ('R', 'T'))
  GROUP BY INSERTED.CompanyID,
           INSERTED.Module,
           INSERTED.R_LOCATION,
           INSERTED.R_ITEM,
           INSERTED.R_LOT,
           INSERTED.R_SUBLOT,
           INSERTED.R_UNIT

  -- Populate Location summary table variable with summarised values from the DELETED table
  INSERT INTO @LocationSummary (CompanyID,
                                Module,
                                R_Location,
                                R_ITEM,
                                R_LOT,
                                R_SUBLOT,
                                R_UNIT,
                                ON_HAND,
                                IN_ORDERED,
                                OUT_ORDERED,
                                IN_RECEIVING,
                                OUT_SHIPPED,
                                IN_BACKORDER,
                                OUT_BACKORDER,
                                IN_UNAVAILABLE,
                                OUT_UNAVAILABLE,
                                IN_FUTURE,
                                OUT_FUTURE)
  SELECT DELETED.CompanyID,
         DELETED.Module,
         DELETED.R_Location,
         DELETED.R_ITEM,
         DELETED.R_LOT,
         DELETED.R_SUBLOT,
         DELETED.R_UNIT,
         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN 0
                WHEN 'Z' THEN ROUND((ISNULL(DELETED.IN_RECEIVING, 0) - ISNULL(DELETED.OUT_SHIPPED, 0)) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
              END) * -1,                                                  -- ON_HAND

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.IN_ORDERED, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                  -- IN_ORDERED

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.OUT_ORDERED, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                  -- OUT_ORDERED

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.IN_RECEIVING, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                  -- IN_RECEIVING

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.OUT_SHIPPED, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                  -- AS OUT_SHIPPED

         --DSY
         SUM(ROUND(ISNULL(DELETED.IN_BACKORDER, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)) * -1, 
         --SUM( CASE DELETED.STATUS
         --       WHEN 'O' THEN ROUND(ISNULL(DELETED.IN_BACKORDER, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
         --       WHEN 'Z' THEN 0
         --     END) * -1,                                                  -- AS IN_BACKORDER

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.OUT_BACKORDER, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                 -- AS OUT_BACKORDER

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.IN_UNAVAILABLE, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                 -- AS IN_UNAVAILABLE

         SUM(ROUND(ISNULL(DELETED.OUT_UNAVAILABLE, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)) * -1,    -- Out_Unavailable

         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.IN_FUTURE, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1,                                                 -- IN_FUTURE,
         SUM( CASE DELETED.STATUS
                WHEN 'O' THEN ROUND(ISNULL(DELETED.OUT_FUTURE, 0) * ISNULL(DELETED.QUANTITYINVENTORY, 1),2)
                WHEN 'Z' THEN 0
              END) * -1                                                  -- OUT_FUTURE
  FROM DELETED
  WHERE (DELETED.RECORDTYPE in ('R', 'T'))
  GROUP BY DELETED.CompanyID,
           DELETED.Module,
           DELETED.R_LOCATION,
           DELETED.R_ITEM,
           DELETED.R_LOT,
           DELETED.R_SUBLOT,
           DELETED.R_UNIT

  -- delete summaries that are all 0 - those will have no effect whatsoever so no need to
  -- create overhead
  DELETE @LocationSummary
  WHERE (ON_HAND           = 0.00) AND
        (IN_ORDERED        = 0.00) AND
        (OUT_ORDERED       = 0.00) AND
        (IN_RECEIVING      = 0.00) AND
        (OUT_SHIPPED       = 0.00) AND
        (IN_BACKORDER      = 0.00) AND
        (OUT_BACKORDER     = 0.00) AND
        (IN_UNAVAILABLE    = 0.00) AND
        (OUT_UNAVAILABLE   = 0.00) AND
        (IN_FUTURE         = 0.00) AND
        (OUT_FUTURE        = 0.00)

  -- the order of updating inventory values is reversed (Unit, Sublot, Lot, Item)
  -- this is done to reduce the lock time on most used tables (IMItem, IMLot...etc)
  -- because up to the IMItem update it will not be locked

  -- Unit


  -- Get the ROWIDs of Location Summary records that already exist and
  -- do not need to be created
  UPDATE @LocationSummary
  SET R_LocationSummary = LS.ROWID
  FROM @LocationSummary AS NLS,
       IMLOCATIONQUANTITYSUMMARY AS LS
  WHERE (LS.RecordType in ('R', 'T')) AND
        (LS.R_Item = NLS.R_Item)
        AND
        ( ( (LS.R_Location IS NULL) AND (NLS.R_Location IS NULL) ) OR
          (LS.R_Location = NLS.R_Location) )
        AND
        ( ( (LS.R_Lot IS NULL) AND (NLS.R_Lot IS NULL) ) OR
          (LS.R_Lot = NLS.R_Lot) )
        AND
        ( ( (LS.R_SubLot IS NULL) AND (NLS.R_SubLot IS NULL) ) OR
          (LS.R_SubLot = NLS.R_SubLot) )
        AND
        ( ( (LS.R_Unit IS NULL) AND (NLS.R_Unit IS NULL) ) OR
          (LS.R_Unit = NLS.R_Unit) )

  -- Insert into Quantity summaries records for Item/Lot/sublot/unit combinations that do not exist
  INSERT INTO IMLOCATIONQUANTITYSUMMARY (COMPANYID,
                                         MODULE,
                                         RECORDTYPE,
                                         R_LOCATION,
                                         R_ITEM,
                                         R_LOT,
                                         R_SUBLOT,
                                         R_UNIT,
                                         ON_HAND,
                                         IN_ORDERED,
                                         OUT_ORDERED,
                                         IN_RECEIVING,
                                         OUT_SHIPPED,
                                         IN_BACKORDER,
                                         OUT_BACKORDER,
                                         IN_UNAVAILABLE,
                                         OUT_UNAVAILABLE,
                                         IN_FUTURE,
                                         OUT_FUTURE,
                                         AVAILABLE,
                                         NETAVAILABLE)
  SELECT CompanyID,
         'IM',
         'R',
         R_Location,
         R_Item,
         R_Lot,
         R_SubLot,
         R_Unit,
         SUM(ON_HAND),
         SUM(IN_ORDERED),
         SUM(OUT_ORDERED),
         SUM(IN_RECEIVING),
         SUM(OUT_SHIPPED),
         SUM(IN_BACKORDER),
         SUM(OUT_BACKORDER),
         SUM(IN_UNAVAILABLE),
         SUM(OUT_UNAVAILABLE),
         SUM(IN_FUTURE),
         SUM(OUT_FUTURE),
         SUM(ON_HAND + IN_RECEIVING - (OUT_SHIPPED + OUT_UNAVAILABLE)),
         SUM(ON_HAND + IN_RECEIVING + IN_ORDERED + IN_BACKORDER - (OUT_SHIPPED + OUT_UNAVAILABLE + OUT_ORDERED + OUT_BACKORDER))
  FROM @LocationSummary
  WHERE (R_LocationSummary IS NULL)
  GROUP BY CompanyID,
           Module,
           R_LOCATION,
           R_ITEM,
           R_LOT,
           R_SUBLOT,
           R_UNIT

  -- update location summary records that do already exist
  UPDATE IMLOCATIONQUANTITYSUMMARY
  SET LASTUPDATEDATETIME = @SYS_DATETIME,
      LASTUPDATEUSERID   = @SYS_USER,
      ON_HAND          = ISNULL(IMLOCATIONQUANTITYSUMMARY.ON_HAND,0)         + LocationSummary.ON_HAND,
      IN_ORDERED       = ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_ORDERED,0)      + LocationSummary.IN_ORDERED,
      OUT_ORDERED      = ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_ORDERED,0)     + LocationSummary.OUT_ORDERED,
      IN_RECEIVING     = ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_RECEIVING,0)    + LocationSummary.IN_RECEIVING,
      OUT_SHIPPED      = ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_SHIPPED,0)     + LocationSummary.OUT_SHIPPED,
      IN_BACKORDER     = ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_BACKORDER,0)    + LocationSummary.IN_BACKORDER,
      OUT_BACKORDER    = ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_BACKORDER,0)   + LocationSummary.OUT_BACKORDER,
      IN_UNAVAILABLE   = ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_UNAVAILABLE,0)  + LocationSummary.IN_UNAVAILABLE,
      OUT_UNAVAILABLE  = ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_UNAVAILABLE,0) + LocationSummary.OUT_UNAVAILABLE,
      IN_FUTURE        = ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_FUTURE,0)       + LocationSummary.IN_FUTURE,
      OUT_FUTURE       = ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_FUTURE,0)      + LocationSummary.OUT_FUTURE,
      AVAILABLE        = ((ISNULL(IMLOCATIONQUANTITYSUMMARY.ON_HAND,0)       + LocationSummary.ON_HAND)
                        + (ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_RECEIVING,0)    + LocationSummary.IN_RECEIVING))
                       - ((ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_SHIPPED,0)     + LocationSummary.OUT_SHIPPED)
                        + (ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_UNAVAILABLE,0) + LocationSummary.OUT_UNAVAILABLE)),
      NETAVAILABLE     = ((((ISNULL(IMLOCATIONQUANTITYSUMMARY.ON_HAND,0)        + LocationSummary.ON_HAND)
                          + (ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_RECEIVING,0)    + LocationSummary.IN_RECEIVING))
                         - ((ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_SHIPPED,0)     + LocationSummary.OUT_SHIPPED)
                          + (ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_UNAVAILABLE,0) + LocationSummary.OUT_UNAVAILABLE)))
                         + ((ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_ORDERED,0)      + LocationSummary.IN_ORDERED)
                          + (ISNULL(IMLOCATIONQUANTITYSUMMARY.IN_BACKORDER,0)    + LocationSummary.IN_BACKORDER)))
                         - ((ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_ORDERED,0)      + LocationSummary.OUT_ORDERED)
                          + (ISNULL(IMLOCATIONQUANTITYSUMMARY.OUT_BACKORDER,0)    + LocationSummary.OUT_BACKORDER))
  FROM IMLOCATIONQUANTITYSUMMARY,
  ( SELECT R_LocationSummary,
           SUM(ON_HAND) AS ON_HAND,
           SUM(IN_ORDERED) AS IN_ORDERED,
           SUM(OUT_ORDERED) AS OUT_ORDERED,
           SUM(IN_RECEIVING) AS IN_RECEIVING,
           SUM(OUT_SHIPPED) AS OUT_SHIPPED,
           SUM(IN_BACKORDER) AS IN_BACKORDER,
           SUM(OUT_BACKORDER) AS OUT_BACKORDER,
           SUM(IN_UNAVAILABLE) AS IN_UNAVAILABLE,
           SUM(OUT_UNAVAILABLE) AS OUT_UNAVAILABLE,
           SUM(IN_FUTURE) AS IN_FUTURE,
           SUM(OUT_FUTURE) AS OUT_FUTURE
    FROM @LocationSummary
    GROUP BY R_LocationSummary) AS LocationSummary
  WHERE LocationSummary.R_LocationSummary = IMLOCATIONQUANTITYSUMMARY.ROWID


  -- delete location summary records for the recordset just inserded/updated with 0 in all quantity buckets
  DELETE IMLOCATIONQUANTITYSUMMARY
  FROM @LocationSummary AS LocationSummary
  WHERE (LocationSummary.R_LocationSummary = IMLOCATIONQUANTITYSUMMARY.ROWID) AND
        (IMLOCATIONQUANTITYSUMMARY.ON_HAND           = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.IN_ORDERED        = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.OUT_ORDERED       = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.IN_RECEIVING      = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.OUT_SHIPPED       = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.IN_BACKORDER      = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.OUT_BACKORDER     = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.IN_UNAVAILABLE    = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.OUT_UNAVAILABLE   = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.IN_FUTURE         = 0.00) AND
        (IMLOCATIONQUANTITYSUMMARY.OUT_FUTURE        = 0.00)

	
	DECLARE @RecordIDs VARCHAR(MAX) 
	set @RecordIDs = ''

	Select @RecordIDs = @RecordIDs + ''''+ Convert(VARCHAR(100), i.ROWID) + ''','
	FROM inserted as i
	JOIN IMTRANSACTIONDETAIL on IMTRANSACTIONDETAIL.RowID = i.R_TRANSACTIONDETAIL
	JOIN IMTRANSACTIONHEADER on IMTRANSACTIONHEADER.RowID = IMTRANSACTIONDETAIL.R_TRANSACTIONHEADER
	JOIN IMTRANSACTIONDP as p on IMTRANSACTIONHEADER.R_PROFILE = p.ROWID
	WHERE i.SOURCETABLENAME = 'IMTRANSACTIONDETAIL' 
		AND i.STATUS = 'Z' AND IMTRANSACTIONHEADER.TRANSACTIONTYPE IN ('C','A')
		AND i.R_ITEM IS NOT NULL
		AND i.R_LOT IS NOT NULL
		AND i.R_LOCATION IS NOT NULL
		AND i.AVAILABLEFLAG = 'Y'
		AND p.PTRASSIGNEDSTAGEFLAG = 'Y'
	
	DECLARE @AttributesSQL1 VARCHAR(MAX)
	DECLARE @AttributesSQL2 VARCHAR(MAX)
	DECLARE @AttributesSQL3 VARCHAR(MAX)
	DECLARE @AttributesSQL4 VARCHAR(MAX)
	DECLARE @AttributesSQL5 VARCHAR(MAX)
	DECLARE @AttributesSQL6 VARCHAR(MAX)
	DECLARE @AttributesSQL7 VARCHAR(MAX)
	DECLARE @SQLScript VARCHAR(MAX)

	set @AttributesSQL1 = ''
	set @AttributesSQL2 = ''
	set @AttributesSQL3 = ''
	set @AttributesSQL4 = ''
	set @AttributesSQL5 = ''
	set @AttributesSQL6 = ''
	set @AttributesSQL7 = ''
	set @SQLScript = ''

	IF ISNULL(@RecordIDs, '') != ''
	BEGIN
		
		SET @RecordIDs = @RecordIDs + '''' + '00000000-0000-0000-0000-000000000000' + ''''

		SELECT 
			@AttributesSQL1 = @AttributesSQL1 + 'DECLARE @' + dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + 'AttributeRowID UNIQUEIDENTIFIER' + CHAR(13) +
				+ 'SELECT TOP 1 @' + dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  +  'AttributeRowID = ROWID FROM OMREVIEWATTRIBUTES WHERE NAME = ''' + NAME + '''' + CHAR(13),
			@AttributesSQL3 = @AttributesSQL3 +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + ',' + CHAR(13),
			@AttributesSQL4 = @AttributesSQL4 + RTRIM(LTRIM(MASTERCODEIMSOURCE)) + ',' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		WHERE ISNULL(RTRIM(LTRIM(MASTERCODEIMSOURCE)), '') != ''
		ORDER BY NAME

		SELECT @AttributesSQL2 = @AttributesSQL2 +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + ' ' +  (CASE WHEN DATA_TYPE IN ('char', 'varchar') THEN DATA_TYPE + '(' + CONVERT(VARCHAR(25), CHARACTER_MAXIMUM_LENGTH) + ')' ELSE DATA_TYPE END) + ',' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		JOIN INFORMATION_SCHEMA.COLUMNS ON TABLE_NAME = SUBSTRING(RTRIM(LTRIM(MASTERCODEIMSOURCE)), 0 , CHARINDEX('.', RTRIM(LTRIM(MASTERCODEIMSOURCE)))) AND COLUMN_NAME = SUBSTRING(RTRIM(LTRIM(MASTERCODEIMSOURCE)), CHARINDEX('.', RTRIM(LTRIM(MASTERCODEIMSOURCE))) + 1, 100)
		WHERE ISNULL(RTRIM(LTRIM(MASTERCODEIMSOURCE)), '') != ''
		ORDER BY NAME

		SELECT 
			@AttributesSQL5 = @AttributesSQL5 + ' AND ISNULL((SELECT TOP 1 ma.[VALUE] FROM Omreviewmastercodeattributes as ma WHERE ma.R_MASTERCODE = m.ROWID AND ma.R_ATTRIBUTE = @' + dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + 'AttributeRowID), '''') = ISNULL(' +  RTRIM(LTRIM(MASTERCODEIMSOURCE)) + ', '''')' + CHAR(13),
			@AttributesSQL6 = @AttributesSQL6 + '
				IF (@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID IS NOT NULL)
				BEGIN
					INSERT INTO Omreviewmastercodeattributes
					(
						RowID,
						Creationdatetime,
						Creationuserid,
						Lastupdatedatetime,
						Lastupdateuserid,
						CompanyId,
						R_MASTERCODE,
						R_ATTRIBUTE,
						Value
					)
					SELECT
						NEWID(),
						m.CREATIONDATETIME,
						m.CREATIONUSERID,
						m.LASTUPDATEDATETIME,
						m.LASTUPDATEUSERID,
						m.COMPANYID,
						m.ROWID,
						@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID,
						mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + '
					FROM OMREVIEWMASTERCODES as m
					JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
					WHERE Operation = ''Insert'' AND mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ' IS NOT NULL
				END' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		WHERE ISNULL(ISMASTERCODEKEY, 0) = 1  AND ISNULL(RTRIM(LTRIM(MASTERCODEIMSOURCE)), '') != ''
		ORDER BY NAME


		SELECT @AttributesSQL7 = @AttributesSQL7 + '
			IF (@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID IS NOT NULL)
			BEGIN
				INSERT INTO Omreviewmastercodeattributes
				(
					RowID,
					Creationdatetime,
					Creationuserid,
					Lastupdatedatetime,
					Lastupdateuserid,
					CompanyId,
					R_MASTERCODE,
					R_ATTRIBUTE,
					Value
				)
				SELECT
					NEWID(),
					m.CREATIONDATETIME,
					m.CREATIONUSERID,
					m.LASTUPDATEDATETIME,
					m.LASTUPDATEUSERID,
					m.COMPANYID,
					m.ROWID,
					@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID,
					mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + '
				FROM OMREVIEWMASTERCODES as m
				JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
				WHERE Operation = ''Insert'' AND mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ' IS NOT NULL


				UPDATE mca
					SET VALUE = mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ',
					LASTUPDATEDATETIME = GetDate(),
					LASTUPDATEUSERID = ''sa''
				FROM Omreviewmastercodeattributes as mca
				JOIN @MasterCodeOperations as mc on mc.ROWID = mca.R_MASTERCODE
				WHERE Operation = ''Update'' AND  mca.R_ATTRIBUTE = @' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID

				INSERT INTO Omreviewmastercodeattributes
				(
					RowID,
					Creationdatetime,
					Creationuserid,
					Lastupdatedatetime,
					Lastupdateuserid,
					CompanyId,
					R_MASTERCODE,
					R_ATTRIBUTE,
					Value
				)
				SELECT
					NEWID(),
					GetDate(),
					''sa'',
					GetDate(),
					''sa'',
					m.COMPANYID,
					m.ROWID,
					@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID,
					mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + '
				FROM OMREVIEWMASTERCODES as m
				JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
				WHERE Operation = ''Update'' AND mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ' IS NOT NULL
				AND ISNULL((Select Count(*) FROM Omreviewmastercodeattributes WHERE R_ATTRIBUTE = @' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID AND R_MASTERCODE = m.ROWID), 1) = 0
			END' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		WHERE ISNULL(ISMASTERCODEKEY, 0) = 0 AND ISNULL(RTRIM(LTRIM(MASTERCODEIMSOURCE)), '') != ''
		ORDER BY NAME


		SET @SQLScript = @AttributesSQL1 +  
		'DECLARE @MasterCodeOperations TABLE 
		(
			ROWID UNIQUEIDENTIFIER,
			Operation Varchar(10),
			CompanyID CHAR(2),
			ItemRowID UNIQUEIDENTIFIER,
			LotRowID UNIQUEIDENTIFIER,
			LocationRowID UNIQUEIDENTIFIER,
			InReceiving DECIMAL(29, 10),' + CHAR(13) + @AttributesSQL2 + '
			DateAvailable DATETIME
		)

		INSERT @MasterCodeOperations(
			ROWID,
			Operation,
			CompanyID,
			ItemRowID,
			LotRowID,
			LocationRowID,
			InReceiving,' + CHAR(13) +  @AttributesSQL3 + '
			DateAvailable)
		SELECT 
			CASE WHEN m.ROWID IS NOT NULL THEN m.ROWID ELSE NEWID() END,
			CASE WHEN m.ROWID IS NOT NULL THEN ''Update'' ELSE ''Insert'' END,
			i.CompanyID,
			i.R_ITEM,
			i.R_LOT,
			i.R_LOCATION,
			i.IN_RECEIVING,' + CHAR(13) +  @AttributesSQL4 + '
			IMLOT.DateAvailable
		FROM IMTRANSACTIONLOCATION as i
		JOIN IMTRANSACTIONDETAIL on IMTRANSACTIONDETAIL.RowID = i.R_TRANSACTIONDETAIL
		JOIN IMTRANSACTIONHEADER on IMTRANSACTIONHEADER.RowID = IMTRANSACTIONDETAIL.R_TRANSACTIONHEADER
		LEFT JOIN IMITEM on IMITEM.ROWID = i.R_ITEM
		LEFT JOIN IMLOT on IMLOT.ROWID = i.R_LOT
		LEFT JOIN  OMREVIEWMASTERCODES as m on i.R_ITEM = m.R_ITEM AND i.R_LOT = m.R_LOT AND i.R_LOCATION = m.R_LOCATION ANd m.COMPANYID = i.COMPANYID' + CHAR(13) +  @AttributesSQL5 + '
		WHERE i.ROWID IN (' + @RecordIDs + ')
	
		INSERT INTO OMREVIEWMASTERCODES
		(
			ROWID,
			CREATIONDATETIME,
			CREATIONUSERID,
			LASTUPDATEDATETIME,
			LASTUPDATEUSERID,
			COMPANYID,
			R_CUSTOMER,
			R_ITEM,
			R_LOT,
			R_LOCATION,
			ISINVENTORYRECORD,
			PRODUCTIONQUANTITY,
			STARTDATE,
			ENDDATE
		)
		SELECT 
			ROWID,
			GetDate(),
			''sa'',
			GetDate(),
			''sa'',
			CompanyID,
			NULL,
			ItemRowID,
			LotRowID,
			LocationRowID,
			1,
			InReceiving,
			DateAvailable,
			NULL
		FROM @MasterCodeOperations
		WHERE Operation = ''Insert''

		UPDATE m
			SET PRODUCTIONQUANTITY = PRODUCTIONQUANTITY +  mc.InReceiving,
			LASTUPDATEDATETIME = GetDate(),
			LASTUPDATEUSERID = ''sa''
		FROM OMREVIEWMASTERCODES as m
		JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
		WHERE Operation = ''Update''
		' +  CHAR(13) +  @AttributesSQL6 +
		+  CHAR(13) +  @AttributesSQL7

		EXEC (@SQLScript) 

	END
	
	Set @RecordIDs = ''

	Select @RecordIDs = @RecordIDs + ''''+ Convert(VARCHAR(100), i.ROWID) + ''','
	FROM inserted as i
	JOIN DELETED as d on i.ROWID = d.ROWID
	JOIN PORECEIPTSDETAIL on PORECEIPTSDETAIL.RowID = i.R_TRANSACTIONDETAIL
	JOIN PORECEIPTSHEADER on PORECEIPTSHEADER.RowID = PORECEIPTSDETAIL.R_RECEIPTSHEADER
	JOIN PORECEIPTSHEADERDP as p on PORECEIPTSHEADER.R_PROFILE = p.ROWID
	WHERE 
		i.SOURCETABLENAME = 'PORECEIPTSDETAIL' 
		AND d.STATUS != 'Z' AND i.STATUS = 'Z' 
		AND PORECEIPTSDETAIL.INVENTORYTYPE = 'I'
		AND i.R_ITEM IS NOT NULL
		AND i.R_LOT IS NOT NULL
		AND i.R_LOCATION IS NOT NULL
		AND i.AVAILABLEFLAG = 'Y'
		AND p.PTRASSIGNEDSTAGEFLAG = 'Y'
		ORDER BY i.CREATIONDATETIME DESC
		
	IF ISNULL(@RecordIDs, '') != ''
	BEGIN

		SET @RecordIDs = @RecordIDs + '''' + '00000000-0000-0000-0000-000000000000' + ''''

		SET @AttributesSQL1 = ''
		SET @AttributesSQL2 = ''
		SET @AttributesSQL3 = ''
		SET @AttributesSQL4 = ''
		SET @AttributesSQL5 = ''
		SET @AttributesSQL6 = ''
		SET @AttributesSQL7 = ''

		SELECT 
			@AttributesSQL1 = @AttributesSQL1 + 'DECLARE @' + dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + 'AttributeRowID UNIQUEIDENTIFIER' + CHAR(13) +
				+ 'SELECT TOP 1 @' + dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  +  'AttributeRowID = ROWID FROM OMREVIEWATTRIBUTES WHERE NAME = ''' + NAME + '''' + CHAR(13),
			@AttributesSQL3 = @AttributesSQL3 +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + ',' + CHAR(13),
			@AttributesSQL4 = @AttributesSQL4 + RTRIM(LTRIM(MASTERCODEPOSOURCE)) + ',' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		WHERE ISNULL(RTRIM(LTRIM(MASTERCODEPOSOURCE)), '') != ''
		ORDER BY NAME

		SELECT @AttributesSQL2 = @AttributesSQL2 +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + ' ' +  (CASE WHEN DATA_TYPE IN ('char', 'varchar') THEN DATA_TYPE + '(' + CONVERT(VARCHAR(25), CHARACTER_MAXIMUM_LENGTH) + ')' ELSE DATA_TYPE END) + ',' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		JOIN INFORMATION_SCHEMA.COLUMNS ON TABLE_NAME = SUBSTRING(RTRIM(LTRIM(MASTERCODEPOSOURCE)), 0 , CHARINDEX('.', RTRIM(LTRIM(MASTERCODEPOSOURCE)))) AND COLUMN_NAME = SUBSTRING(RTRIM(LTRIM(MASTERCODEPOSOURCE)), CHARINDEX('.', RTRIM(LTRIM(MASTERCODEPOSOURCE))) + 1, 100)
		WHERE ISNULL(RTRIM(LTRIM(MASTERCODEPOSOURCE)), '') != ''
		ORDER BY NAME

		SELECT 
			@AttributesSQL5 = @AttributesSQL5 + ' AND ISNULL((SELECT TOP 1 ma.[VALUE] FROM Omreviewmastercodeattributes as ma WHERE ma.R_MASTERCODE = m.ROWID AND ma.R_ATTRIBUTE = @' + dbo.[FNOM_GETATTRIBUTESQLNAME](NAME)  + 'AttributeRowID), '''') = ISNULL(' +  RTRIM(LTRIM(MASTERCODEPOSOURCE)) + ', '''')' + CHAR(13),
			@AttributesSQL6 = @AttributesSQL6 + '
				IF (@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID IS NOT NULL)
				BEGIN
					INSERT INTO Omreviewmastercodeattributes
					(
						RowID,
						Creationdatetime,
						Creationuserid,
						Lastupdatedatetime,
						Lastupdateuserid,
						CompanyId,
						R_MASTERCODE,
						R_ATTRIBUTE,
						Value
					)
					SELECT
						NEWID(),
						m.CREATIONDATETIME,
						m.CREATIONUSERID,
						m.LASTUPDATEDATETIME,
						m.LASTUPDATEUSERID,
						m.COMPANYID,
						m.ROWID,
						@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID,
						mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + '
					FROM OMREVIEWMASTERCODES as m
					JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
					WHERE Operation = ''Insert'' AND mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ' IS NOT NULL
				END' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		WHERE ISNULL(ISMASTERCODEKEY, 0) = 1  AND ISNULL(RTRIM(LTRIM(MASTERCODEPOSOURCE)), '') != ''
		ORDER BY NAME


		SELECT @AttributesSQL7 = @AttributesSQL7 + '
			IF (@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID IS NOT NULL)
			BEGIN
				INSERT INTO Omreviewmastercodeattributes
				(
					RowID,
					Creationdatetime,
					Creationuserid,
					Lastupdatedatetime,
					Lastupdateuserid,
					CompanyId,
					R_MASTERCODE,
					R_ATTRIBUTE,
					Value
				)
				SELECT
					NEWID(),
					m.CREATIONDATETIME,
					m.CREATIONUSERID,
					m.LASTUPDATEDATETIME,
					m.LASTUPDATEUSERID,
					m.COMPANYID,
					m.ROWID,
					@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID,
					mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + '
				FROM OMREVIEWMASTERCODES as m
				JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
				WHERE Operation = ''Insert'' AND mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ' IS NOT NULL


				UPDATE mca
					SET VALUE = mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ',
					LASTUPDATEDATETIME = GetDate(),
					LASTUPDATEUSERID = ''sa''
				FROM Omreviewmastercodeattributes as mca
				JOIN @MasterCodeOperations as mc on mc.ROWID = mca.R_MASTERCODE
				WHERE Operation = ''Update'' AND  mca.R_ATTRIBUTE = @' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID

				INSERT INTO Omreviewmastercodeattributes
				(
					RowID,
					Creationdatetime,
					Creationuserid,
					Lastupdatedatetime,
					Lastupdateuserid,
					CompanyId,
					R_MASTERCODE,
					R_ATTRIBUTE,
					Value
				)
				SELECT
					NEWID(),
					GetDate(),
					''sa'',
					GetDate(),
					''sa'',
					m.COMPANYID,
					m.ROWID,
					@' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID,
					mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + '
				FROM OMREVIEWMASTERCODES as m
				JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
				WHERE Operation = ''Update'' AND mc.' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + ' IS NOT NULL
				AND ISNULL((Select Count(*) FROM Omreviewmastercodeattributes WHERE R_ATTRIBUTE = @' +  dbo.[FNOM_GETATTRIBUTESQLNAME](NAME) + 'AttributeRowID AND R_MASTERCODE = m.ROWID), 1) = 0
			END' + CHAR(13)
		FROM OMREVIEWATTRIBUTES 
		WHERE ISNULL(ISMASTERCODEKEY, 0) = 0 AND ISNULL(RTRIM(LTRIM(MASTERCODEPOSOURCE)), '') != ''
		ORDER BY NAME


		
		SET @SQLScript = @AttributesSQL1 +  
		'DECLARE @MasterCodeOperations TABLE 
		(
			ROWID UNIQUEIDENTIFIER,
			Operation Varchar(10),
			CompanyID CHAR(2),
			ItemRowID UNIQUEIDENTIFIER,
			LotRowID UNIQUEIDENTIFIER,
			LocationRowID UNIQUEIDENTIFIER,
			InReceiving DECIMAL(29, 10),' + CHAR(13) + @AttributesSQL2 + '
			DateAvailable DATETIME
		)

		INSERT @MasterCodeOperations(
			ROWID,
			Operation,
			CompanyID,
			ItemRowID,
			LotRowID,
			LocationRowID,
			InReceiving,' + CHAR(13) +  @AttributesSQL3 + '
			DateAvailable)
		SELECT 
			CASE WHEN m.ROWID IS NOT NULL THEN m.ROWID ELSE NEWID() END,
			CASE WHEN m.ROWID IS NOT NULL THEN ''Update'' ELSE ''Insert'' END,
			i.CompanyID,
			i.R_ITEM,
			i.R_LOT,
			i.R_LOCATION,
			i.IN_RECEIVING,' + CHAR(13) +  @AttributesSQL4 + '
			IMLOT.DateAvailable
		FROM IMTRANSACTIONLOCATION as i
		JOIN PORECEIPTSDETAIL on PORECEIPTSDETAIL.RowID = i.R_TRANSACTIONDETAIL
		JOIN PORECEIPTSHEADER on PORECEIPTSHEADER.RowID = PORECEIPTSDETAIL.R_RECEIPTSHEADER
		LEFT JOIN IMITEM on IMITEM.ROWID = i.R_ITEM
		LEFT JOIN IMLOT on IMLOT.ROWID = i.R_LOT
		LEFT JOIN  OMREVIEWMASTERCODES as m on i.R_ITEM = m.R_ITEM AND i.R_LOT = m.R_LOT AND i.R_LOCATION = m.R_LOCATION ANd m.COMPANYID = i.COMPANYID' + CHAR(13) +  @AttributesSQL5 + '
		WHERE i.ROWID IN (' + @RecordIDs + ')
	
		INSERT INTO OMREVIEWMASTERCODES
		(
			ROWID,
			CREATIONDATETIME,
			CREATIONUSERID,
			LASTUPDATEDATETIME,
			LASTUPDATEUSERID,
			COMPANYID,
			R_CUSTOMER,
			R_ITEM,
			R_LOT,
			R_LOCATION,
			ISINVENTORYRECORD,
			PRODUCTIONQUANTITY,
			STARTDATE,
			ENDDATE
		)
		SELECT 
			ROWID,
			GetDate(),
			''sa'',
			GetDate(),
			''sa'',
			CompanyID,
			NULL,
			ItemRowID,
			LotRowID,
			LocationRowID,
			1,
			InReceiving,
			DateAvailable,
			NULL
		FROM @MasterCodeOperations
		WHERE Operation = ''Insert''

		UPDATE m
			SET PRODUCTIONQUANTITY = PRODUCTIONQUANTITY +  mc.InReceiving,
			LASTUPDATEDATETIME = GetDate(),
			LASTUPDATEUSERID = ''sa''
		FROM OMREVIEWMASTERCODES as m
		JOIN @MasterCodeOperations as mc on mc.ROWID = m.ROWID
		WHERE Operation = ''Update''
		' +  CHAR(13) +  @AttributesSQL6 +
		+  CHAR(13) +  @AttributesSQL7

		EXEC (@SQLScript) 

	END

END
---FOOTER
GO

ALTER TABLE [dbo].[IMTRANSACTIONLOCATION] ENABLE TRIGGER [IMTRANSACTIONLOCATION_UPDATE]
GO

EXEC sp_settriggerorder @triggername=N'[dbo].[IMTRANSACTIONLOCATION_UPDATE]', @order=N'First', @stmttype=N'UPDATE'
GO


