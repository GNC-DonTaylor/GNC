/*
-- FREIGHTRATE EXCEL
BASED ON INFORMATION GLEANED FROM VW_GNC_FREIGHTZONECODES AND REQUEST FOR NEW REPORT BY STEVE COPPEDGE
--SELECT * from VW_GNC_FREIGHTZONECODES (JOIN TO IMCONTAINER CREATES MULTIPLE RECORDS THAT I ELIMINATE IN THIS VIEW)

SELECT * 
FROM VW_RPT_FREIGHTRATE (NOLOCK) 
WHERE 1=1 
--
AND WAREHOUSEID = '10'
ORDER BY
WAREHOUSEID, CODE
*/
CREATE OR ALTER VIEW [dbo].[VW_RPT_FREIGHTRATE]
AS

SELECT
CO.COMPANYID,
TRIM(CO.NAME) AS COMPANYNAME,
WH.IDENTITYID AS WAREHOUSEID,
TRIM(WH.NAME) AS WAREHOUSENAME,
ZON.CODE,
ZON.DESCRIPTION,
FRD.EFFECTIVEDATE,
FRC.FREIGHTCLASSCODE,
FRZ.MINCHARGEAMOUNT,
FRC.RATE

FROM IMFREIGHTRATETABLEZONE FRZ (NOLOCK)
JOIN IMFREIGHTRATETABLEDATE FRD (NOLOCK) ON FRD.ROWID = FRZ.R_FREIGHTRATETABLEDATE
JOIN IMFREIGHTRATETABLECLASSRATE FRC (NOLOCK) ON FRC.R_FREIGHTRATETABLEZONE = FRZ.ROWID
JOIN IMFREIGHTRATETABLE FR (NOLOCK) ON FR.ROWID = FRD.R_FREIGHTRATETABLE
JOIN RTZONETABLECODES ZON (NOLOCK) ON ZON.ROWID = FRZ.R_ZONE
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = FR.R_SHIPPER AND LEFT(ZON.CODE,2) = TRIM(WH.IDENTITYID)
JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID
--CONTAINER LEVEL INFO NOT NEEDED YET..
--JOIN IMCONTAINER CNT (NOLOCK) ON CNT.FREIGHTCLASSCODE = FRC.FREIGHTCLASSCODE
