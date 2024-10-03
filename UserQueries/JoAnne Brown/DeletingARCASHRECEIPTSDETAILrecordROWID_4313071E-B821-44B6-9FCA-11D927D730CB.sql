--SCRIPT TO FIND THE ISSUE:
SELECT OH.TRANSACTIONNUMBER, 
CRH.ROWID AS CRH_ROWID, 
--CRH.STATUS AS CRH_STATUS, CRH.COMMITDATE AS CRH_COMMITDATE, CRH.CONTROLAMOUNT AS CRH_CONTROLAMOUNT, 
-------
CRD.ROWID AS CRD_ROWID, 
IIF(CRH.ROWID = CRD.R_CASHRECEIPTSHEADER, 'OPEN', IIF(CRD.ROWID IS NULL, 'CLOSED','<--ORPHANED RECORD') ) AS MY_CONCLUSION, 
CRD.RECORDTYPE AS CRD_RECORDTYPE, CRD.R_CASHRECEIPTSHEADER AS CRD_R_CASHRECEIPTSHEADER, CRD.AMOUNTAPPLIED AS CRD_AMOUNTAPPLIED 

FROM OMTRANSACTIONHEADER OH (NOLOCK) 
JOIN AROPENITEMHEADER ARH (NOLOCK) ON ARH.R_SOURCEID = OH.ROWID 
LEFT JOIN ARCASHRECEIPTSDETAIL CRD (NOLOCK) ON CRD.R_AROPENITEMHEADER = ARH.ROWID 
LEFT JOIN ARCASHRECEIPTSHEADER CRH (NOLOCK) ON CRH.ROWID = CRD.R_CASHRECEIPTSHEADER 
WHERE OH.TRANSACTIONNUMBER IN ('20-73085-2', '40-72561-4CM', '40-72561-5', '40-72561-6', '40-72561-6CM')
/*
--SCRIPT TO SOLVE THE PROBLEM:
SELECT * FROM ARCASHRECEIPTSDETAIL (NOLOCK) WHERE ROWID = '4313071E-B821-44B6-9FCA-11D927D730CB'
BEGIN TRAN
DELETE FROM ARCASHRECEIPTSDETAIL WHERE ROWID = '4313071E-B821-44B6-9FCA-11D927D730CB'
SELECT * FROM ARCASHRECEIPTSDETAIL (NOLOCK) WHERE ROWID = '4313071E-B821-44B6-9FCA-11D927D730CB'
ROLLBACK TRAN --COMMIT
*/
