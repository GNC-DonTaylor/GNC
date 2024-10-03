--EquivUnitsShippedbyYear for Kim Johnson
SELECT 
	WAREHOUSEID, REPORTYEAR, --
	REPORTPERIOD, 
	DATASOURCE, 
	SUM(EQUIVUNITS) AS EQUIVUNITS 
FROM	( 
			SELECT 
				'INSIGHT' AS DATASOURCE, 
				WH.IDENTITYID AS WAREHOUSEID, 
				DBO.FN_DATE2YEAR(OH.TRANSACTIONDATE) AS REPORTYEAR, 
				DBO.FN_DATE2PERIOD(OH.TRANSACTIONDATE) AS REPORTPERIOD, 
				(ISNULL(OD.QUANTITYSHIPPED,0)*(ISNULL(CNT.VOLUME,.01)/615.99)) AS EQUIVUNITS

			FROM OMTRANSACTIONHEADER OH (NOLOCK) 
			JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID 
			JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
			JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM 
			JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE 
			WHERE OH.RECORDTYPE='Z' AND OH.TRANSACTIONTYPE='I' 
			AND SUBSTRING(OH.TRANSACTIONNUMBER,1,2)<>'IC' --EXCLUDING INTERCOMPANY ORDERS 
			
			UNION ALL 

			SELECT 
				'ePLANT' AS DATASOURCE, 
				WH.IDENTITYID AS WAREHOUSEID, 
				DBO.FN_DATE2YEAR(HIST.TRANSACTIONDATE) AS REPORTYEAR, 
				DBO.FN_DATE2PERIOD(HIST.TRANSACTIONDATE) AS REPORTPERIOD, 
				(ISNULL(HIST.SHIPPEDQTY,0)*(ISNULL(CNT.VOLUME,.01)/615.99)) AS EQUIVUNITS

			FROM GNC_SHIPPED_HISTORY_ARCHIVE HIST (NOLOCK) 
			JOIN IDMASTER WH (NOLOCK) ON WH.IDENTITYID = HIST.WAREHOUSEID
			JOIN IMITEM ITM (NOLOCK) ON ITM.ITEMCODE = HIST.ITEMCODE AND ITM.R_WAREHOUSE = WH.ROWID 
			JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE
		) X 
WHERE WAREHOUSEID = '40' AND REPORTPERIOD BETWEEN 7 AND 13 

GROUP BY 	WAREHOUSEID, REPORTYEAR--
, REPORTPERIOD
, DATASOURCE 
ORDER BY 	WAREHOUSEID, REPORTYEAR--
, REPORTPERIOD
, DATASOURCE 
