--SITEONEORDERSREADY2SHIP

/* Because of timing issues, I had to manually generate 810's for these at go-live.
20-75381            
20-75405            
20-72949-29         
40-72941-34         
10-75595            
10-75339            
10-75297            
10-75531            
10-75597            
10-75299            
10-75300            
10-75312            
10-75418            
10-75412  

8 orders had missing UnitOfMeasure values so I had to re-transmit these after fixing the map to default to EA:
10-75300            
10-75312            
10-75412            
10-75418            
10-75595            
10-75597            
20-72949-29         
40-72941-34         

*/

SELECT X.* 
FROM (	--THIS IS THE DATASET FOR THE MAIN REPORT.
		SELECT 
		CUST.IDENTITYID AS CUSTOMERID, 
		ICUST.USERDEFINEDCODE_9 AS EDI_CUST_FLAG, 
		VEND.IDENTITYID AS VENDORID, VEND.IDSUBGROUP AS ISLEGACY, 
		OH.EDITRANSMITFLAG, 
		OH.USERDEFINEDREFERENCE_10 AS OMVENDORREFERENCE, 
		OH.RECORDTYPE AS OHRECTYPE, 
		OH.PURCHASEORDERNUMBER, 
		OH.TRANSACTIONDATE, OH.COMMITDATE, 
		1 AS DATASET, NULL AS DATASORT,
		CO.COMPANYID,
		CO.NAME AS COMPANYNAME,
		HDR.RECORDTYPE,
		HDR.TRIPNO,
		HDR.PLANSTART, CAST (HDR.PLANSTART AS DATE) AS DATESORT, 
		HDR.ACTUALSTART,
		HDR.PLANFINISH,
		HDR.ACTUALFINISH,
		DO.TRACKINGNUMBER,
		OH.R_SYNONYMSALTSHIPTO, 
		HDR.STATUS,
		AB.FLAGDESCRIPTION AS STATUSDESCRIPTION,
		HDR.USERDEFINEDCODE_2 AS DOCKNUMBER,
		DTL.DELSTOPNO,
		VCONS.CONSIGNEEIDENTITYID,
		VCONS.CONSIGNEENAME,
		ISNULL(DO.WEIGHTORDERED,0) AS WEIGHTORDERED,
		ISNULL(DO.CUBESORDERED,0) AS VOLUME,
		VCONS.CONSIGNEECITY,
		VCONS.CONSIGNEESTATE,
		HDR.EQUIPMENT,
		CARR.IDENTITYID AS CARRIERCODE,
		CARR.NAME AS CARRIERNAME,
		PART.NAME SALESPERSONNAME,
		PART.IDENTITYID SALESPERSONCODE,
		OH.COMMENT AS ORDERSHIPPINGINSTR,
		HDR.COMMENT AS TRIPNOTE,
--		VCONS.CONSIGNEECOMMENT,
--		VCONS.CONSIGNEEMASTERCOMMENT,
--		WH.IDENTITYID AS SHIPPERCODE,
--		ICONS.USERDEFINEDCODE_11 AS QACODE,
--		CASE WH.IDENTITYID
--			WHEN 10 THEN ICONS.USERDEFINEDREFERENCE_8
--			WHEN 20 THEN ICONS.USERDEFINEDREFERENCE_9
--			WHEN 40 THEN ICONS.USERDEFINEDREFERENCE_10
--			WHEN 60 THEN ICONS.USERDEFINEDREFERENCE_11
--			ELSE NULL
--		END AS LOADINSTRUCTIONS, 
--		VCONS.CONSIGNEEUSERDEFINEDREF_7 AS CONSIGNEESHIPNOTE,
--		VCONS.CONSIGNEEDIRECTIONS AS DRIVERDIRECTIONS, 
----		STOPNOTE CHANGE:
----		DTL.COMMENT AS STOPNOTES,
--		ISNULL(TRIM(SUBSTRING(DTL.COMMENT,1,50)),'') + ISNULL(DTL.USERDEFINEDREFERENCE_4,'') AS STOPNOTES, 
--		FORMAT((SELECT ISNULL(SUM(ISNULL(OD2.AMOUNT,0)),0) 
--				FROM OMTRANSACTIONDETAIL OD2 (NOLOCK)
--				WHERE OD2.R_TRANSACTIONHEADER=OH.ROWID),'0.00') AS ESTIMATEDLOADVALUES,
--		FORMAT((SELECT ISNULL(SUM(ISNULL(FRT.AMOUNT,0)),0) 
--				FROM OMFREIGHT FRT (NOLOCK)
--				WHERE FRT.R_TRANSACTIONHEADER=OH.ROWID),'0.00') AS ESTIMATEDFREIGHTREVENUE,
'EOL' AS EOL
		FROM FMTRIPHEADER HDR (NOLOCK)
		LEFT JOIN FMTRIPDETAIL DTL (NOLOCK) ON DTL.R_TRIPHEADER = HDR.ROWID
		LEFT JOIN FMDISPATCHOBJECT DO (NOLOCK) ON DO.ROWID= DTL.R_FMDISPATCHOBJECT 
		LEFT JOIN OMTRANSACTIONHEADER OH (NOLOCK) ON OH.ROWID=DO.R_SOURCEID
		LEFT JOIN IDMASTER CUST (NOLOCK) ON CUST.ROWID = OH.R_CUSTOMER
		LEFT JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY=CUST.ROWID
		LEFT JOIN IDMASTER VEND (NOLOCK) ON VEND.IDENTITYID = 'EDI'+TRIM(CUST.IDGROUP)
		LEFT JOIN IDCONSIGNEE ICONS (NOLOCK) ON ICONS.R_IDENTITY=DO.R_CONSIGNEE
		LEFT JOIN VW_IDCONSIGNEEVIEW VCONS (NOLOCK) ON VCONS.CONSIGNEEMASTERROWID = DO.R_CONSIGNEE
		LEFT JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID
		LEFT JOIN IDMASTER CARR (NOLOCK) ON CARR.ROWID = HDR.R_CARRIER
		LEFT JOIN IDMASTER PART (NOLOCK) ON PART.ROWID = OH.R_SALESPERSON_1
		LEFT JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = DO.R_SHIPPER
		LEFT JOIN ABFLAGFIELD AB (NOLOCK) ON AB.FLAGVALUE = HDR.STATUS AND AB.TABLENAME = 'FMTRIPHEADER' AND AB.FIELDNAME = 'STATUS'
) X
WHERE X.RECORDTYPE <> 'P'
AND X.CUSTOMERID = '10043' --AND X.OHRECTYPE = 'R'
AND X.COMMITDATE > GETDATE()-2
--AND X.EDITRANSMITFLAG = 'Y'
ORDER BY TRIPNO, DELSTOPNO