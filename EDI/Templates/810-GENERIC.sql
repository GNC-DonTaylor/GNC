--810-GENERIC

/*
SELECT OH.ROWID, VEND.IDENTITYID, VEND.IDSUBGROUP, OH.TRANSACTIONNUMBER, OH.INVOICEDATE FROM OMTRANSACTIONHEADER OH (NOLOCK) 
JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = OH.USERDEFINEDREFERENCE_10 WHERE OH.STAGE NOT IN ('L') ORDER BY VEND.IDENTITYID, OH.TRANSACTIONNUMBER
*/
DECLARE @ROWID UNIQUEIDENTIFIER
SET @ROWID= (	SELECT OH.ROWID FROM OMTRANSACTIONHEADER OH (NOLOCK) 
				JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER 
				WHERE CUST.IDGROUP = '35'-- 
				AND OH.TRANSACTIONNUMBER = '10-60593'--'20-27415            '--'10-13055'--
			)
------------ 
--[HEADER]-- 
------------ 
SELECT 
	OH.INVOICEDATE, 
	ISNULL(POH.TRANSACTIONDATE, OH.TRANSACTIONDATE) AS PODATE, 
	OH.SHIPPINGDATE, 
	OH.TRANSACTIONNUMBER, --DO I NEED TO ADD 'Z.' TO THE FRONT?
	OH.PURCHASEORDERNUMBER, 
	CASE 
		WHEN OH.TRANSACTIONTYPE = 'I' THEN ''								--SPECIAL CASE FOR ACE, ONLY SEND BIG07 IF CREDITMEMO 
		ELSE IIF(ISNULL(DBO.FN_ORDERVALUE(OH.ROWID,NULL),0) < 0, '', 'CR')	--SPECIAL CASE FOR ACE, ONLY SEND BIG07 IF CREDITMEMO 
	END AS TRANSACTIONCODE, 
	WH.IDENTITYID AS WH, 
	ISNULL(OH.USERDEFINEDREFERENCE_17,(SELECT VENDOR FROM GNC_EDI_TRANSLATION (NOLOCK) WHERE IDGROUP = CUST.IDGROUP AND WAREHOUSEID IN (WH.IDENTITYID, '99') )) AS PO_VENDOR, 
	CUST.IDGROUP, 
	CUST.IDENTITYID AS CUSTID, 
	CUST.NAME AS CUSTNAME, 
	CONS.IDENTITYID AS CONSIGNEEID, 
	REPLACE(ISNULL(ALTSHIP.NAME, CONS.NAME), CHAR(39),'') AS CONSIGNEENAME,	--SPECIAL CASE FOR ACE, APOSTROPHES CAUSE EDI ERRORS. 
	ISNULL(ALTSHIP.ADDRESS_1, ACONS.ADDRESS_1) AS CONSIGNEEADDRESS_1, 
	ISNULL(ALTSHIP.ADDRESS_2, ACONS.ADDRESS_2) AS CONSIGNEEADDRESS_2, 
	ISNULL(ALTSHIP.CITY, ACONS.CITY) AS CONSIGNEECITY, 
	ISNULL(ALTSHIP.STATE, ACONS.STATE) AS CONSIGNEESTATE, 
	ISNULL(ALTSHIP.ZIP, ACONS.ZIP) AS CONSIGNEEZIP, 
	IIF(ALTSHIP.ROWID IS NULL, 'N', 'Y') AS ISALTSHIP, 
	DBO.FN_REMITTOADDRESS('NAME') AS COMPANYNAME, 
	DBO.FN_REMITTOADDRESS('ADDRESS') AS COMPANYADDRESS, 
	DBO.FN_REMITTOADDRESS('CITY') AS COMPANYCITY, 
	DBO.FN_REMITTOADDRESS('STATE') AS COMPANYSTATE, 
	DBO.FN_REMITTOADDRESS('ZIP') AS COMPANYZIP, 
	DBO.FN_REMITTOADDRESS('DUNNS') AS COMPANYDUNNS, 
	ISNULL(OH.USERDEFINEDREFERENCE_19, ICONS.USERDEFINEDREFERENCE_2) AS PO_STORENUMBER, 
	ISNULL(OH.USERDEFINEDREFERENCE_20, ICONS.USERDEFINEDREFERENCE_6) AS GLNNUMBER, 
	IIF(HEADER.TDSAMT = HEADER.TOTAL, 'X', IIF(HEADER.TDSAMT < HEADER.TOTAL, 'C', 'A')) AS SAC01VALUE, 
	HEADER.TOTAL - HEADER.TDSAMT AS SAC05VALUE, 
	IIF(HEADER.TDSAMT = HEADER.TOTAL, 'X', IIF(HEADER.TDSAMT < HEADER.TOTAL, 'FREIGHT CHARGE', 'FREIGHT ALLOWANCE')) AS SAC15VALUE, 
	HEADER.TDSAMT, HEADER.TOTAL, DETAIL.LINECOUNT 
FROM OMTRANSACTIONHEADER OH (NOLOCK) 
	LEFT JOIN OMTRANSACTIONHEADER POH (NOLOCK) ON POH.PURCHASEORDERNUMBER = OH.PURCHASEORDERNUMBER AND POH.RECORDTYPE = 'I' 
	JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
	JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER 
	JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = OH.R_CUSTOMER 
	JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 
	JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = CONS.ROWID 
--must include tcon link to get proper address, i think because customer is a mastercustomer. (check Rural King and Site One for this)
	JOIN IDTYPESLINKS TCONS (NOLOCK) ON TCONS.R_IDENTITY = CONS.ROWID AND TCONS.IDTYPE = '02'
	JOIN IDADDRESS ACONS (NOLOCK) ON ACONS.ROWID = ISNULL(TCONS.R_ADDRESS, CONS.R_DEFAULTADDRESS)
	LEFT JOIN IDSYNONYMS ALTSHIP (NOLOCK) ON ALTSHIP.ROWID = OH.R_SYNONYMSALTSHIPTO 
	LEFT JOIN	(	SELECT 
						OD.R_TRANSACTIONHEADER, 
						ROUND(SUM(ISNULL(OD.QUANTITYSHIPPED, 0) * 
							(	ISNULL(OD.UNITPRICE, 0) + 
								ISNULL(OD.HANDLINGCHARGEPERITEM,0) + 
								ISNULL(OD.TAGGINGCHARGEPERITEM,0) + 
								IIF(ISNULL(DBO.FN_ORDERFREIGHT(OH.ROWID, 'FRTZONE'),0) = 0, 0, ISNULL(OD.FREIGHTRATEPERITEM, 0)) 
								--ISNULL(OD.FREIGHTRATEPERITEM,0) 
							) 
						),2) AS TDSAMT, 
						DBO.FN_ORDERVALUE(OD.R_TRANSACTIONHEADER, NULL) AS TOTAL 
					FROM OMTRANSACTIONDETAIL OD (NOLOCK) 
					WHERE ISNULL(OD.QUANTITYSHIPPED,0) > 0 
					GROUP BY OD.R_TRANSACTIONHEADER 
				) AS HEADER ON HEADER.R_TRANSACTIONHEADER = OH.ROWID 
	LEFT JOIN	(	SELECT OD.R_TRANSACTIONHEADER, COUNT(*) AS LINECOUNT 
					FROM OMTRANSACTIONDETAIL OD (NOLOCK) 
					WHERE ISNULL(OD.QUANTITYSHIPPED,0) > 0 
					GROUP BY OD.R_TRANSACTIONHEADER 
				) AS DETAIL ON DETAIL.R_TRANSACTIONHEADER = OH.ROWID 
WHERE OH.ROWID = @ROWID AND OH.RECORDTYPE = 'Z' 

------------ 
--[DETAIL]-- 
------------ 
SELECT 
	ISNULL(POD.LINENUMBER,OD.LINENUMBER) AS LINENUMBER, 
	DBO.FN_WHITELIST(ITM.DESCRIPTION_1) AS DESCRIPTION_1, --REMOVE SPECIAL CHARACTERS
	ITM.ITEMCODE, 
	OD.QUANTITYSHIPPED, 
	ISNULL(POD.UNITOFMEASURE, OD.UNITOFMEASURE) AS UNITOFMEASURE, 
	CAST(	ISNULL(OD.UNITPRICE, 0) + 
			ISNULL(OD.HANDLINGCHARGEPERITEM,0) + 
			ISNULL(OD.TAGGINGCHARGEPERITEM,0) + 
			IIF(ISNULL(DBO.FN_ORDERFREIGHT(OH.ROWID, 'FRTZONE'),0) = 0, 0, ISNULL(OD.FREIGHTRATEPERITEM, 0)) 
			--ISNULL(OD.FREIGHTRATEPERITEM,0) 
		AS DECIMAL(15,2)) AS LANDEDPRICE, 
	IIF(ISNULL(PSD.ALTERNATESKU,'')='','','IN') AS SKUSERVICEID, --SPECIAL CASE FOR ACE, BLANK SERVICEID FOR MISSING SKUS. 
	ISNULL(PSD.ALTERNATESKU,'') AS ALTERNATESKU, 
	ITM.ITEMSUPCCODE 
FROM OMTRANSACTIONHEADER OH (NOLOCK) 
JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID 
LEFT JOIN OMTRANSACTIONHEADER POH (NOLOCK) ON POH.PURCHASEORDERNUMBER = OH.PURCHASEORDERNUMBER AND POH.RECORDTYPE = 'I' 
LEFT JOIN OMTRANSACTIONDETAIL POD (NOLOCK) ON POD.R_TRANSACTIONHEADER = POH.ROWID AND POD.LINENUMBER = OD.LINENUMBER 
JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM 
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = OH.R_CUSTOMER 
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = OH.R_SHIPPER 
LEFT JOIN IDCONSIGNEESHIPPERZONE SZ (NOLOCK) ON SZ.R_CONSIGNEE = ICONS.R_IDENTITY AND SZ.R_SHIPPER = WH.ROWID 
LEFT JOIN IMPRICESCHEDULEHEADER PSH (NOLOCK) ON PSH.ROWID = ISNULL(SZ.R_PRICESCHEDULE, ICONS.R_PRICESCHEDULE) 
LEFT JOIN IMPRICESCHEDULEDETAIL PSD (NOLOCK) ON PSD.R_PRICESCHEDULEHEADER = PSH.ROWID AND PSD.R_ITEM = OD.R_ITEM AND PSD.EXPIRATIONDATE >= GETDATE() 
WHERE ISNULL(OD.QUANTITYSHIPPED,0) > 0 
AND OH.ROWID = @ROWID 
ORDER BY OD.LINENUMBER
