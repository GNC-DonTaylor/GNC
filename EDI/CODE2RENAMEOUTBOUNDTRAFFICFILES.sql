--CODE2RENAMEOUTBOUNDXMTRAFFICFILES
SELECT 
DOC.DIRECTION, 
VEND.IDENTITYID, 
DOC.FILENAME, 
TRIM(VEND.IDENTITYID) + '_' + DOC.FILENAME AS RESULT 
FROM XMDOCUMENT DOC (NOLOCK) 
JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = DOC.R_SERVICEPROVID 
WHERE DOC.DOCUMENTTYPE = 1	--ELIMINATE 'LEGACY' DOCUMENTS.
AND DOC.DIRECTION = 1		--NOT SURE IF WE CAN RENAME THE INBOUND DOCUMENTS THIS WAY.