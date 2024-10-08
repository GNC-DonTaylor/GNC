--BAD LOGIC HERE: THE ITEMROWID DEPENDS UPON THE WAREHOUSEID AS WELL:
Select *--TOP 1 @ItemCodeRowID  = IMITEM.RowID
FROM IMITEM
WHERE IMITEM.CompanyID = 'SB'--@Companyid
AND IMITEM.ITEMCODE = '001884.030.1'--Trim(@ItemCode)
AND IMITEM.R_WAREHOUSE = '4E1CB3D5-08A1-4084-89FF-4E0ED538EEA2'--(SELECT ROWID FROM IDMASTER WH (NOLOCK) WHERE WH.IDENTITYID = '10')

SELECT --TOP 1 
/*@NEWID = ROWID*/ * FROM OMTRANSACTIONHEADER WHERE RECORDTYPE IN ('R')--,'E')
AND PURCHASEORDERNUMBER = '283249332'
--USERDEFINEDREFERENCE_10 = '535-283249332'--@PORESERVENUMBER AND COMPANYID = @Companyid

--FIND OUT IF ORDERHEADER 'R' RECORD ALREADY EXISTS AND RETURN THE ROWID:
--(VALIDATE WAREHOUSEID, CUSTOMERID, CONSIGNEEID, STORENUMBER AND R_ORIGINALTRANSACTION TO ELIMINATE FALSE HITS.
SELECT OH.ROWID, 
OH.PURCHASEORDERNUMBER, 
WH.IDENTITYID AS WAREHOUSEID, 
CUST.IDENTITYID AS CUSTOMERID, 
CONS.IDENTITYID AS CONSIGNEEID, 
ICONS.USERDEFINEDREFERENCE_2 AS STORENUMBER, 
OH.USERDEFINEDREFERENCE_19 AS PO_STORENUMBER, 
OH.R_ORIGINALTRANSACTION AS SPLITORDER_ROWID
FROM OMTRANSACTIONHEADER OH (NOLOCK) 
JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER 
JOIN IDMASTER CONS (NOLOCK) ON CONS.ROWID = OH.R_SHIPPER 
JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY = CONS.ROWID 
WHERE OH.RECORDTYPE = 'I'--'R' 
AND OH.PURCHASEORDERNUMBER = '283249332' 
AND WH.IDENTITYID = '10' 
AND CUST.IDENTITYID = '10535' 
AND CONS.IDENTITYID = '829194'
AND ICONS.USERDEFINEDREFERENCE_2 = RIGHT('0000'+TRIM('34'),4)
AND R_ORIGINALTRANSACTION IS NULL --ENSURES THIS ISN'T A SPLIT ORDER 

SELECT 
R_PROFILE, COMPANYID, MODULE, 
R_CUSTOMER, TRANSACTIONTYPE, 
R_ZONEFREIGHTRATEOVERRIDE, 
R_FMSHIPPER, 
PURCHASEORDERNUMBER, 
USERDEFINEDREFERENCE_19, USERDEFINEDREFERENCE_20, USERDEFINEDREFERENCE_4, USERDEFINEDDATE_19, USERDEFINEDDATE_20, 
USERDEFINEDREFERENCE_3, SHIPPINGDATE, USERDEFINEDCODE_1, USERDEFINEDQUANTITY_1, USERDEFINEDREFERENCE_10, RECORDTYPE 
FROM OMTRANSACTIONHEADER (NOLOCK) WHERE ROWID = '666EEFA4-72BF-4604-B23B-026BA3D3B9D9'--[Z]'2C4459CF-7901-407B-8250-11F8B4B5ABA6'







