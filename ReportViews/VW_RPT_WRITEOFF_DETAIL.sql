/* 
--WRITEOFF DETAIL EXCEL 
SELECT * 
FROM VW_RPT_WRITEOFF_DETAIL (NOLOCK) 
WHERE PROFILECODE = 'WriteOff' 
*/ 
CREATE OR ALTER VIEW [DBO].[VW_RPT_WRITEOFF_DETAIL] 
AS 
SELECT 
CO.COMPANYID, 
CO.NAME AS COMPANYNAME, 
ADP.PROFILECODE, 
CUST.IDENTITYID AS CUSTOMERID, 
CUST.NAME AS CUSTOMERNAME, 
AH.DATERECEIVED, 
AOH.TRANSACTIONNUMBER, 
AOH.TRANSACTIONTYPE, 
AOH.TRANSACTIONDATE, 
AOH.DESCRIPTION, 
AOH.USERDEFINEDQUANTITY_1 AS AMOUNT, 
--AOH.USERDEFINEDQUANTITY_3, 
--AOH.USERDEFINEDQUANTITY_4, 
AOH.USERDEFINEDQUANTITY_1 - AOH.USERDEFINEDQUANTITY_3 AS ADJUST 
FROM ARCASHRECEIPTSHEADER AH (NOLOCK) 
JOIN ARCASHRECEIPTSDP ADP (NOLOCK) ON ADP.ROWID = AH.R_PROFILE 
JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = AH.R_CUSTOMER 
--JOIN ARCASHRECEIPTSPAYMENTS APAY (NOLOCK) ON APAY.R_ARCASHRECEIPTSHEADER = AH.ROWID 
JOIN ARCASHRECEIPTSDETAIL AD (NOLOCK) ON AD.R_CASHRECEIPTSHEADER = AH.ROWID 
JOIN AROPENITEMHEADER AOH (NOLOCK) ON AOH.ROWID = AD.R_AROPENITEMHEADER 
JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = AH.COMPANYID 
WHERE ADP.PROFILECODE = 'WriteOff' 
--AND CUST.IDENTITYID = '825813' 

--ORDER BY 
--	CUST.IDENTITYID, 
--	AOH.TRANSACTIONTYPE, 
--	AOH.TRANSACTIONDATE 
