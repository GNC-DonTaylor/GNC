--USE [ABECAS_CUST_GNC_TEST] 
--GO

--/****** Object:  View [dbo].[VW_DAILYSHIPPINGSHEDULEDETAILVIEW]    Script Date: 11/2/2020 6:18:59 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

ALTER VIEW [dbo].[VW_FREIGHTPROFITBYTRUCKTYPEVIEW]
AS
SELECT ISNULL(H.EQUIPMENT,'') AS TRUCKTYPE, H.STATUS ,COUNT(H.KEYSEQUENCE) AS TRIPCOUNT, H.PLANSTART,H.ACTUALSTART,H.TRIPNO,
ISNULL(H.MILESLOADED,0) as LOADEDMILES,
--New Miles field added per DJ request - DT 6/29/21
	(	SELECT ISNULL(SUM(ISNULL(BASIS,0)),0) FROM SPOPENITEMS (NOLOCK) 
		LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
		WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='RATE/MILE') AS TOTALLOADEDMILES,
S.IDENTITYID AS SHIPPERCODE, S.NAME AS SHIPPERNAME,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK)
LEFT JOIN IDFREIGHTCHARGES FC(NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='RATE/MILE') AS LOADEDMILESEXPENSE ,
--LOADED RATE/MILE = LOADEDMILESEXPENSE/LOADEDMILES

--Change calculation for STOPCOUNT per DJ request - DT 6/29/21
--(SELECT COUNT(KEYSEQUENCE) FROM FMTRIPDETAIL D (NOLOCK) WHERE D.R_TRIPHEADER= H.ROWID) AS STOPCOUNT, 
	(SELECT ISNULL(SUM(ISNULL(BASIS,0)),0) FROM SPOPENITEMS (NOLOCK) 
	LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
	WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='DROPPAY') AS STOPCOUNT, 

(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='DROPPAY') AS TOTALSTOPPAY  ,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='DHFEE') AS DEADHEADEXP,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='FSMILES') AS FSCEXPENSE  ,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='RTMILES') AS RETURNMILESEXP,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID AND FC.CHARGECODE ='ADJUST') AS COSTADJUSTMENT, 
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM SPOPENITEMS (NOLOCK) 
LEFT JOIN IDFREIGHTCHARGES FC (NOLOCK) ON FC.ROWID= SPOPENITEMS.R_FREIGHTCHARGE 
WHERE SPOPENITEMS.R_SOURCEID = H.ROWID ) AS TOTALFREIGHTEXPENSE,
(SELECT ISNULL(SUM(ISNULL(AMOUNT,0)),0) FROM OMFREIGHT F (NOLOCK)
LEFT JOIN OMTRANSACTIONHEADER TH (NOLOCK) ON TH.ROWID=F.R_TRANSACTIONHEADER
LEFT JOIN FMDISPATCHOBJECT DO (NOLOCK) ON DO.R_SOURCEID= TH.ROWID
LEFT JOIN FMTRIPDETAIL D (NOLOCK) ON D.R_FMDISPATCHOBJECT = DO.ROWID AND D.R_TRIPHEADER = H.ROWID
LEFT JOIN FMTRIPHEADER H (NOLOCK) ON H.ROWID  = D.R_TRIPHEADER 
WHERE H.ROWID=H.ROWID) AS FREIGHTREVENUE
-- FREIGHTPROFIT = FREIGHTREVENUEV - FREIGHTEXPENSE
-- AVERAFE FREIGHT PROFIT /LOAD
-- AVERAGE FREIGHT PROFIT / MILES
FROM FMTRIPHEADER H (NOLOCK)
LEFT JOIN IDMASTER S (NOLOCK) ON S.ROWID = H.R_ORIGIN
WHERE H.RECORDTYPE <>'P'
GROUP BY H.EQUIPMENT,H.ROWID ,H.STATUS, H.MILESLOADED,S.IDENTITYID,S.NAME,H.PLANSTART,H.ACTUALSTART,H.TRIPNO





GO
