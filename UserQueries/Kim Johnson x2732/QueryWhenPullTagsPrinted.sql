--Kim Johnson x2732 QueryWhenPullTagsPrinted
--	The data in question is the CreationDateTime of the Trip I guess.
SELECT 
TH.TRIPNO, 
TH.CREATIONDATETIME AUDITDATE, 
TH.PLANSTART 
FROM FMTRIPHEADER TH (NOLOCK) 
