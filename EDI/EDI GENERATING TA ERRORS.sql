--EDI GENERATING TA ERRORS
SELECT 
OH.TRANSACTIONNUMBER,
OH.INVOICEDATE,
CUST.IDGROUP,
VEND.IDENTITYID,
VEND.NAME, 
VEND.IDSUBGROUP
FROM OMTRANSACTIONHEADER OH (NOLOCK)
JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = OH.USERDEFINEDREFERENCE_10
WHERE OH.INVOICEDATE > GETDATE()-1
AND OH.RECORDTYPE = 'Z' AND OH.TRANSACTIONTYPE = 'I'
AND VEND.IDSUBGROUP IS NULL
--AND CUST.IDGROUP = '43'
ORDER BY OH.INVOICEDATE DESC