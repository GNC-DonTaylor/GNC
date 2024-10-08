--ALTSHIP - HOW TO LINK R_SYNONYMSALTSHIPTO TO FIELDS IN IDCONSIGNEE TABLE_SITEONE WANTED ALTSTORENUMBER

SELECT	OH.TRANSACTIONNUMBER, OH.TRANSACTIONDATE, 
		CONS.ROWID AS CONSROWID, CONS.IDENTITYID AS CONSID, CONS.NAME AS CONSNAME, 
		ICONS.R_IDENTITY AS ICONSR_ID, ICONS.USERDEFINEDREFERENCE_2 AS ICONS_STORE, 
		OH.R_SYNONYMSALTSHIPTO, ALTSHIP.NAME AS ALTSHIPNAME, 
		ALTACONS.R_IDENTITY AS ALTACONSR_ID, ALTACONS.ADDRESS_1 AS ALTACONSNAME_ADDR1,  
		ALTICONS.R_IDENTITY AS ALTICONSR_ID, ALTICONS.USERDEFINEDREFERENCE_2 AS ALTICONSSTORE,  
1
FROM OMTRANSACTIONHEADER OH (NOLOCK) 
JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = CONS.ROWID 
--TO GET TO THE ALTERNATE STORENUMBER IN IDCONSIGNEE TABLE: (A LINK WHERE ONE DOESN'T EXIST)
LEFT JOIN IDSYNONYMS ALTSHIP (NOLOCK) ON ALTSHIP.ROWID = OH.R_SYNONYMSALTSHIPTO 
--	LEFT JOIN IDADDRESSES THAT MATCH THE ALTSHIP.NAME (NO ROWIDS LINKING THIS POINT, ALTSHIPNAME ONLY):
	LEFT JOIN IDADDRESS ALTACONS (NOLOCK) ON ALTACONS.ADDRESS_1 = ALTSHIP.NAME 
--	LEFT JOIN IDCONSIGNEES THAT MATCH THE RECORD THE ADDRESS IS POINTING TO:
	LEFT JOIN IDCONSIGNEE ALTICONS (NOLOCK) ON ALTICONS.R_IDENTITY = ALTACONS.R_IDENTITY 

WHERE CONS.IDENTITYID LIKE '826953%'--'51234%'--
ORDER BY OH.TRANSACTIONNUMBER
