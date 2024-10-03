/*
--EDI EMAIL DOCS
SELECT 
*
FROM VW_RPT_EDI_EMAIL_DOCS (NOLOCK) 
WHERE /*COMPANYID = 'SB' and*/ doctype = '820'
ORDER BY 
CREATIONDATETIME, 
WAREHOUSEID, IDGROUP, DOCTYPE, STORENUMBER, TRANSACTIONNUMBER, LINENUMBER 

*/

CREATE OR ALTER VIEW [DBO].[VW_RPT_EDI_EMAIL_DOCS]
AS
 
SELECT 
EH.ROWID, EH.CREATIONDATETIME, EH.EMAILSENTFLAG,
ISNULL(CO.COMPANYID,'SB') AS COMPANYID, CO.NAME AS COMPANYNAME, 
EH.DOCTYPE, 
(	SELECT TOP 1 SETH.TRANSSETNAME 
	FROM EDSETHEAD SETH (NOLOCK) 
	WHERE SETH.TRANSSETID = EH.DOCTYPE
	) AS DOCTEXT, 
EH.IDGROUP, 
ISNULL(	--TRY TO GET MASTERCUSTOMER GROUPNAME FIRST
		(	SELECT TOP 1 MCUST.REFERENCE2 
			FROM IDMASTER MCUST (NOLOCK) 
			JOIN IDRELATIONSHIPLINKS LCUST (NOLOCK) ON LCUST.R_IDMEMBER = CUST.ROWID AND LCUST.IDMEMBERTYPE = '02' 
			WHERE MCUST.ROWID = LCUST.R_IDMASTER
			), CUST.REFERENCE2 
	) AS IDGROUPNAME,
EH.WAREHOUSEID, 
(	SELECT WH.NAME 
	FROM IDMASTER WH (NOLOCK) 
	WHERE WH.IDENTITYID = EH.WAREHOUSEID
	) AS WAREHOUSENAME, 
EH.TRANSACTIONNUMBER, EH.PONUMBER, EH.STORENUMBER, 
EH.DATETIME, EH.ACTION, EH.REFERENCE, EH.RESULT, EH.IDENTIFIERS, EH.SUBJECT,
ED.LINENUMBER, ED.DETAIL, 
CASE EH.WAREHOUSEID
	WHEN '10' THEN 
		CASE EH.DOCTYPE 
			WHEN '812' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' 
			WHEN '820' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' 
			WHEN '824' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Erica Washington<erica_washington@greenleafnursery.com>;' + 
							'Stephanie Knight<stephanie_knight@greenleafnursery.com>;' 
			WHEN '864' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Erica Washington<erica_washington@greenleafnursery.com>;' + 
							'Stephanie Knight<stephanie_knight@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '895' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '850' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Erica Washington<erica_washington@greenleafnursery.com>;' + 
							'Katherine Kessler<katherine_kessler@greenleafnursery.com>;' + 
							'Sandra Epperley<sandra_epperley@greenleafnursery.com>;' + 
							'Stephanie Knight<stephanie_knight@greenleafnursery.com>;' 
			ELSE 'Don Taylor<donny_taylor@greenleafnursery.com>'
		END --WAREHOUSE 10
	WHEN '20' THEN 
		CASE EH.DOCTYPE 
			WHEN '812' THEN	'Shelly Cerny<shelly_cerny@greenleafnursery.com>;' 
			WHEN '820' THEN	'Shelly Cerny<shelly_cerny@greenleafnursery.com>;' 
			WHEN '824' THEN	'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			WHEN '864' THEN	'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '895' THEN	'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '850' THEN	'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			ELSE 'Don Taylor<donny_taylor@greenleafnursery.com>'
		END --WAREHOUSE 20
	WHEN '40' THEN 
		CASE EH.DOCTYPE 
			WHEN '812' THEN	'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			WHEN '820' THEN	'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			WHEN '824' THEN	'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Lisa Baker<lisa_baker@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			WHEN '864' THEN	'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Lisa Baker<lisa_baker@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '895' THEN	'Bill Davenport<bill_davenport@greenleafnursery.com>;' + 
							'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '850' THEN	'Angela Harrison<angela_harrison@greenleafnursery.com>;' + 
							'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Lisa Baker<lisa_baker@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			ELSE 'Don Taylor<donny_taylor@greenleafnursery.com>;'
		END --WAREHOUSE 40
	ELSE	--UNKNOWN WAREHOUSE (SEND TO EVERYBODY) 
		CASE EH.DOCTYPE 
			WHEN '812' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'Shelly Cerny<shelly_cerny@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			WHEN '820' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'Shelly Cerny<shelly_cerny@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' 
			WHEN '824' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Erica Washington<erica_washington@greenleafnursery.com>;' + 
							'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Lisa Baker<lisa_baker@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' + 
							'Stephanie Knight<stephanie_knight@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			WHEN '864' THEN	'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Erica Washington<erica_washington@greenleafnursery.com>;' + 
							'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Lisa Baker<lisa_baker@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' + 
							'Stephanie Knight<stephanie_knight@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '895' THEN	'Bill Davenport<bill_davenport@greenleafnursery.com>;' + 
							'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			--PROBABLY NEVER USED:
			WHEN '850' THEN	'Angela Harrison<angela_harrison@greenleafnursery.com>;' + 
							'Carin Hodson<carin_hodson@greenleafnursery.com>;' + 
							'Cindy Hendrix<cindy_hendrix@greenleafnursery.com>;' + 
							'David Brandt<david_brandt@greenleafnursery.com>;' + 
							'Erica Washington<erica_washington@greenleafnursery.com>;' + 
							'Jeremy Clark<jeremy_clark@greenleafnursery.com>;' + 
							'Katherine Kessler<katherine_kessler@greenleafnursery.com>;' + 
							'Lisa Baker<lisa_baker@greenleafnursery.com>;' + 
							'Sandra Epperley<sandra_epperley@greenleafnursery.com>;' + 
							'Starla Kimble<starla_kimble@greenleafnursery.com>;' + 
							'Stephanie Knight<stephanie_knight@greenleafnursery.com>;' + 
							'Valerie Woodruff<valerie_woodruff@greenleafnursery.com>;' 
			ELSE 'Don Taylor<donny_taylor@greenleafnursery.com>;'
		END --UNKNOWN WAREHOUSE (SEND TO EVERYBODY) 
END AS EMAILRECIPIENTS

FROM GNC_EDI_EMAILHEADER EH (NOLOCK) 
LEFT JOIN GNC_EDI_EMAILDETAIL ED (NOLOCK) ON ED.R_EMAILHEADER = EH.ROWID 
LEFT JOIN OMTRANSACTIONHEADER OH (NOLOCK) ON OH.TRANSACTIONNUMBER = EH.TRANSACTIONNUMBER AND OH.STAGE !='L' AND /*OH.RECORDTYPE IN ('R', 'Z') AND OH.TRANSACTIONTYPE = 'I' AND*/ OH.PURCHASEORDERNUMBER = EH.PONUMBER
LEFT JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
LEFT JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID

/*
--------------------------------------------------------------------------------------------------------------------------------------------------
--Need a TA script to run [EDI Email Docs] report for the next available [WareHouseID/DocType] dataset that still shows [EMAILSENTFLAG = 'N']	--
--Then an update script to set these records to [EMAILSENTFLAG = 'Y']																			--
--The email needs to use the [EMAILRECIPIENTS] field for the distributionlist.																	--
--------------------------------------------------------------------------------------------------------------------------------------------------
--TA Trigger:
on Record Inserted into GNC_EDI_EMAILHEADER
.....


--EXAMPLE UPDATE SCRIPT BELOW:
DECLARE 
@WAREHOUSEID VARCHAR(12),
@DOCTYPE VARCHAR(4)--, 

SELECT TOP 1 @WAREHOUSEID = WAREHOUSEID, @DOCTYPE = DOCTYPE
FROM VW_RPT_EDI_EMAIL_DOCS RPT (NOLOCK) 
WHERE EMAILSENTFLAG = 'N' 
ORDER BY CREATIONDATETIME

SELECT @WAREHOUSEID, @DOCTYPE

--BEFORE UPDATE:
SELECT	WAREHOUSEID, DOCTYPE, TRANSACTIONNUMBER, PONUMBER, EMAILSENTFLAG 
FROM	VW_RPT_EDI_EMAIL_DOCS RPT (NOLOCK) 
WHERE	EMAILSENTFLAG = 'N' 
AND		WAREHOUSEID = @WAREHOUSEID 
AND		DOCTYPE = @DOCTYPE 
ORDER BY CREATIONDATETIME

BEGIN TRAN
	UPDATE	VW_RPT_EDI_EMAIL_DOCS 
	SET		EMAILSENTFLAG = 'Y'
	FROM	VW_RPT_EDI_EMAIL_DOCS 
	WHERE	EMAILSENTFLAG = 'N' 
	AND		WAREHOUSEID = @WAREHOUSEID 
	AND		DOCTYPE = @DOCTYPE 

	--AFTER UPDATE:
	SELECT	WAREHOUSEID, DOCTYPE, TRANSACTIONNUMBER, PONUMBER, EMAILSENTFLAG 
	FROM	VW_RPT_EDI_EMAIL_DOCS RPT (NOLOCK) 
	WHERE	EMAILSENTFLAG = 'Y' 
	AND		WAREHOUSEID = @WAREHOUSEID 
	AND		DOCTYPE = @DOCTYPE 
	ORDER BY CREATIONDATETIME
ROLLBACK TRAN
--commit
*/
