--USE [ABECAS_CUST_GNC_TEST]
--GO

--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

ALTER VIEW [dbo].[VW_REGISTRYOFTRUCKSHIPMENTSVIEW]
AS

SELECT FMTRIPHEADER.ACTUALSTART,FMTRIPHEADER.STATUS,S.IDENTITYID AS SHIPPERCODE,S.NAME AS SHIPPERNAME,
(ISNULL(FMTRIPHEADER.MILESUNLOADED,0) + ISNULL(FMTRIPHEADER.MILESLOADED,0)) TOTALMILES,
ISNULL(FMTRIPHEADER.MILESUNLOADED,0) AS UNLOADEDMILES,
PLANSTART,TRIPNO,
ISNULL(M.IDENTITYID,'') AS CARRIERCODE,ISNULL(M.NAME,'') AS CARRIERNAME, 
FMTRIPHEADER.EQUIPMENT AS TRUCKTYPE,
ISNULL((SELECT TOP 1 ISNULL(SPOPENITEMS.RATE,0) FROM SPOPENITEMS (NOLOCK)
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='RATE/MILE'),0) AS LOADEDRATEPERMILE,
--ISNULL(FMTRIPHEADER.MILESLOADED,0) AS LOADEDMILES, 
ISNULL((SELECT TOP 1 ISNULL(SPOPENITEMS.BASIS,0) FROM SPOPENITEMS (NOLOCK)
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='RATE/MILE'),0) AS LOADEDMILES,
--LOADEDMILESEXP = lOADEDMILES * LOADEDRATEPERMILE
--(SELECT COUNT(KEYSEQUENCE) FROM FMTRIPDETAIL (NOLOCK) WHERE R_TRIPHEADER = FMTRIPHEADER.ROWID) AS STOPCOUNT,
(SELECT ISNULL(SUM(ISNULL(BASIS,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='DROPPAY') AS STOPCOUNT, 
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='DROPPAY') AS EXTSTOPPAY  , 
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='DHFEE') AS DHFEE, 
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='FSMILES') AS FSEXPENSE,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='RTMILES') AS RTMILES, 
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS  (NOLOCK)
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = FMTRIPHEADER.ROWID AND FC.CHARGECODE ='ADJUST') AS  COSTADJUSTMENT,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
WHERE SPOPENITEMS.R_SOURCEID  =FMTRIPHEADER.ROWID) AS TOTALFREIGHTEXPENSE,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS SO (NOLOCK)
WHERE SO.TRANSACTIONTYPE ='A' AND SO.TRANSACTIONNUMBER =FMTRIPHEADER.TRIPNO) AS DRIVERADVANCE,
(SELECT TOP 1 STH.CHECKDATE FROM SPSETTLEMENTSHEADER STH (NOLOCK) 
JOIN SPSETTLEMENTSDETAIL STD (NOLOCK) ON STD.R_SETTLEMENTSHEADER = STH.ROWID
JOIN SPOPENITEMS SO (NOLOCK) ON SO.ROWID = STD.R_OPENITEM 
WHERE SO.R_SOURCEID  =FMTRIPHEADER.ROWID AND STH.STATUS ='Z'
ORDER BY STH.CHECKDATE DESC) AS FINALPAYMENTDATE,
(SELECT ISNULL(SUM(ISNULL(TD.QUANTITYSHIPPED ,0) * ISNULL(TD.UNITPRICE ,0)),0) FROM OMTRANSACTIONDETAIL TD (NOLOCK)
LEFT JOIN OMTRANSACTIONHEADER TH (NOLOCK) ON TH.ROWID=TD.R_TRANSACTIONHEADER
LEFT JOIN FMDISPATCHOBJECT DO (NOLOCK) ON DO.R_SOURCEID= TH.ROWID
LEFT JOIN FMTRIPDETAIL D (NOLOCK) ON D.R_FMDISPATCHOBJECT = DO.ROWID 
LEFT JOIN FMTRIPHEADER H (NOLOCK) ON H.ROWID  = D.R_TRIPHEADER 
WHERE H.ROWID =FMTRIPHEADER.ROWID) AS EXTMERCH  ,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM OMFREIGHT F (NOLOCK)
LEFT JOIN OMTRANSACTIONHEADER TH (NOLOCK) ON TH.ROWID=F.R_TRANSACTIONHEADER
LEFT JOIN FMDISPATCHOBJECT DO (NOLOCK) ON DO.R_SOURCEID= TH.ROWID
LEFT JOIN FMTRIPDETAIL D (NOLOCK) ON D.R_FMDISPATCHOBJECT = DO.ROWID 
LEFT JOIN FMTRIPHEADER H (NOLOCK) ON H.ROWID  = D.R_TRIPHEADER 
WHERE H.ROWID=FMTRIPHEADER.ROWID) AS FREIGHTREVENUE
--FREIGHT PROFIT = FREIGHT REVENUE - FREIGHT EXPENSE.
FROM FMTRIPHEADER FMTRIPHEADER (NOLOCK)
LEFT JOIN IDMASTER M (NOLOCK) ON M.ROWID = FMTRIPHEADER.R_CARRIER
LEFT JOIN IDMASTER S (NOLOCK) ON S.ROWID = FMTRIPHEADER.R_ORIGIN
WHERE FMTRIPHEADER.RECORDTYPE<>'P'

GO
