USE [ABECAS_GNC_PROD]
GO

/****** Object:  Trigger [dbo].[XMEXPORTDOC_UPDATE]    Script Date: 10/3/2024 9:08:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



---HEADER
CREATE OR ALTER     TRIGGER [dbo].[XMEXPORTDOC_UPDATE] ON [dbo].[XMEXPORTDOC]
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
    UPDATE XMEXPORTDOC
      SET LASTUPDATEDATETIME = @SYS_DATETIME,
        LASTUPDATEUSERID = @SYS_USER
    FROM XMEXPORTDOC
      JOIN INSERTED ON (XMEXPORTDOC.ROWID = INSERTED.ROWID)
  END


---AFTER SYSTEM
/**********************************************************************************************/
/* Revisions       :                                                                          */
/*                                                                                            */
/* 12/04/2023      : DEV-4250 Fahad Malik                                                     */
/*                   Updated XM File Name extension to trade partner FILESUPPORT              */
/* 02/16/2024      : GREENLEAF - Don Taylor                                                   */
/*                   Updated XM File Name to include Service Provider info.                    */
/**********************************************************************************************/

/* TESTING 02/16/2024 CHANGES:
SELECT ISNULL(TRIM((SELECT RIGHT(IDENTITYID,9) FROM IDMASTER (NOLOCK) WHERE ROWID = XMDOCUMENT.R_SERVICEPROVID)),'') + '_' + ISNULL(REPLACE(TRIM(XMTRADEPARTNER.TRADEPARTNERNAME),' ','_'),'') + '_' + --ADDED BY DT 2/16/2024 
ISNULL(INSERTED.DocumentTypeID, isnull(XMExportMapDef.TRANSET, '')) + '_' + 
CONVERT(varchar(20),getdate(),112) + REPLACE(CONVERT(varchar(12),getdate(),114),':','') + (CASE WHEN INSERTED.R_TRADEPARTNER IS NOT NULL THEN XMTRADEPARTNER.FILESUPPORT ELSE '.txt' END)
from XMEXPORTDOC INSERTED (NOLOCK) --INSERTED
join XMExportMessage (NOLOCK) ON XMExportMessage.Rowid = INSERTED.R_EDIMessage
join XMDocument (NOLOCK) ON XMDocument.Rowid = XMExportMessage.R_XMDocument
left outer join XMExportMapDef (NOLOCK) ON XMExportMapDef.Rowid = INSERTED.R_MapDef
left outer join XMTRADEPARTNER (NOLOCK) ON XMTRADEPARTNER.ROWID = INSERTED.R_TRADEPARTNER
*/

update XMDOCUMENT
set [FILENAME] = 
ISNULL(TRIM((SELECT RIGHT(IDENTITYID,9) FROM IDMASTER (NOLOCK) WHERE ROWID = XMDOCUMENT.R_SERVICEPROVID)),'') + '_' + ISNULL(REPLACE(TRIM(XMTRADEPARTNER.TRADEPARTNERNAME),' ','_'),'') + '_' + --ADDED BY DT 2/16/2024 
ISNULL(INSERTED.DocumentTypeID, isnull(XMExportMapDef.TRANSET, '')) + '_' + 
CONVERT(varchar(20),getdate(),112) + REPLACE(CONVERT(varchar(12),getdate(),114),':','') + (CASE WHEN INSERTED.R_TRADEPARTNER IS NOT NULL THEN XMTRADEPARTNER.FILESUPPORT ELSE '.txt' END),
LASTUPDATEDATETIME = @SYS_DATETIME,
LASTUPDATEUSERID = @SYS_USER
from INSERTED
join XMExportMessage (NOLOCK) ON XMExportMessage.Rowid = INSERTED.R_EDIMessage
join XMDocument (NOLOCK) ON XMDocument.Rowid = XMExportMessage.R_XMDocument
left outer join XMExportMapDef (NOLOCK) ON XMExportMapDef.Rowid = INSERTED.R_MapDef
left outer join XMTRADEPARTNER (NOLOCK) ON XMTRADEPARTNER.ROWID = INSERTED.R_TRADEPARTNER
where xmdocument.direction = 1
  and xmdocument.documenttype = 1
  and xmdocument.[status] = 0
  and isnull(xmdocument.[filename], '') <> ''
  
---FOOTER
GO

ALTER TABLE [dbo].[XMEXPORTDOC] ENABLE TRIGGER [XMEXPORTDOC_UPDATE]
GO

EXEC sp_settriggerorder @triggername=N'[dbo].[XMEXPORTDOC_UPDATE]', @order=N'First', @stmttype=N'UPDATE'
GO


