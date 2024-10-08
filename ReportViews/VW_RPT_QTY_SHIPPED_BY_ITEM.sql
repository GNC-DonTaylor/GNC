/* 
--QUANTITY SHIPPED BY ITEM 
SELECT * 
FROM VW_RPT_QTY_SHIPPED_BY_ITEM (NOLOCK) 
WHERE COMPANYID = 'SB' 
*/ 
CREATE OR ALTER VIEW [dbo].[VW_RPT_QTY_SHIPPED_BY_ITEM] 
AS 
SELECT 
	COMPANYID, 
	COMPANYNAME, 
	RECORDTYPE, 
	WAREHOUSEID, 
	REPORTYEAR, 
	REPORTPERIOD, 
	REPORTWEEK, 
	CAST(TRANSACTIONDATE AS DATE) AS TRANSACTIONDATE, 
	ITEMCODE, 
	COMMONNAME, 
	SIZE, 
	SORTNAME, 
	SUM(CURRSHIPPEDQTY) AS CURRSHIPPEDQTY, 
	SUM(CURREXTMERCH) AS CURREXTMERCH, 
	SUM(HIST1SHIPPEDQTY) AS HIST1SHIPPEDQTY, 
	SUM(HIST1EXTMERCH) AS HIST1EXTMERCH, 
	SUM(CURRSHIPPEDQTY - HIST1SHIPPEDQTY) AS DIFFSHIPPEDQTY, 
	SUM(CURREXTMERCH - HIST1EXTMERCH) AS DIFFEXTMERCH 
FROM ( 
		--INSIGHT DATASET: CURRENT 
		SELECT 
			CO.COMPANYID, 
			CO.NAME AS COMPANYNAME, 
			OH.RECORDTYPE, 
			WH.IDENTITYID AS WAREHOUSEID, 
			DBO.FN_DATE2YEAR(OH.INVOICEDATE) AS REPORTYEAR, 
			DBO.FN_DATE2PERIOD(OH.INVOICEDATE) AS REPORTPERIOD, 
			DBO.FN_DATE2WEEK(OH.INVOICEDATE) AS REPORTWEEK, 
			OH.INVOICEDATE AS TRANSACTIONDATE, 
			ITM.ITEMCODE, 
			ITM.REFERENCE_1 AS COMMONNAME, 
			ITM.CLASSCODE AS SIZE, 
			ITM.REFERENCE_5 AS SORTNAME, 
			OD.QUANTITYSHIPPED AS CURRSHIPPEDQTY, 
			ISNULL(OD.QUANTITYSHIPPED ,0) * (ISNULL(OD.UNITPRICE ,0)) AS CURREXTMERCH, 
			0 AS HIST1SHIPPEDQTY, 
			0 AS HIST1EXTMERCH 
		FROM IMITEM ITM (NOLOCK) 
			LEFT JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_ITEM = ITM.ROWID 
			LEFT JOIN OMTRANSACTIONHEADER OH (NOLOCK) ON OH.ROWID = OD.R_TRANSACTIONHEADER 
			LEFT JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
			JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID 
		WHERE OH.RECORDTYPE = 'Z' --COMMITTED RECORDS ONLY 
		AND OH.TRANSACTIONTYPE = 'I' --ORDERS/INVOICES ONLY 
		AND SUBSTRING(OH.TRANSACTIONNUMBER,1,2) <> 'IC' --EXCLUDING INTERCOMPANY ORDERS 

		UNION ALL 

		--INSIGHT DATASET: HIST1 
		SELECT 
			CO.COMPANYID, 
			CO.NAME AS COMPANYNAME, 
			OH.RECORDTYPE, 
			WH.IDENTITYID AS WAREHOUSEID, 
			DBO.FN_DATE2YEAR(OH.INVOICEDATE) + 1 AS REPORTYEAR,			--ADD ONE EQUIVALENT YEAR 
			DBO.FN_DATE2PERIOD(OH.INVOICEDATE) AS REPORTPERIOD,			--SHOULD BE THE EQUIVALENT PERIOD 
			DBO.FN_DATE2WEEK(OH.INVOICEDATE) AS REPORTWEEK,				--SHOULD BE THE EQUIVALENT WEEK 
			DBO.FN_DATE4NEXTYEAR(OH.INVOICEDATE) AS TRANSACTIONDATE,	--ADD ONE EQUIVALENT YEAR 
			ITM.ITEMCODE, 
			ITM.REFERENCE_1 AS COMMONNAME, 
			ITM.CLASSCODE AS SIZE, 
			ITM.REFERENCE_5 AS SORTNAME, 
			0 AS CURRSHIPPEDQTY, 
			0 AS CURREXTMERCH, 
			OD.QUANTITYSHIPPED AS HIST1SHIPPEDQTY, 
			ISNULL(OD.QUANTITYSHIPPED ,0) * (ISNULL(OD.UNITPRICE ,0)) AS HIST1EXTMERCH 
		FROM IMITEM ITM (NOLOCK) 
			LEFT JOIN OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_ITEM = ITM.ROWID 
			LEFT JOIN OMTRANSACTIONHEADER OH (NOLOCK) ON OH.ROWID = OD.R_TRANSACTIONHEADER 
			LEFT JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
			JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID 
		WHERE OH.RECORDTYPE = 'Z' --COMMITTED RECORDS ONLY 
		AND OH.TRANSACTIONTYPE = 'I' --ORDERS/INVOICES ONLY 
		AND SUBSTRING(OH.TRANSACTIONNUMBER,1,2) <> 'IC' --EXCLUDING INTERCOMPANY ORDERS 

		UNION ALL 

		--ePLANT DATASET: CURRENT 
		SELECT 
			CO.COMPANYID, 
			CO.NAME AS COMPANYNAME, 
			'Z' AS RECORDTYPE, 
			WH.IDENTITYID AS WAREHOUSEID, 
			ePLANT.REPORTYEAR, 
			ePLANT.REPORTPERIOD, 
			ePLANT.REPORTWEEK, 
			ePLANT.TRANSACTIONDATE, 
			ISNULL(ITM.ITEMCODE, ePLANT.ITEMCODE) AS ITEMCODE, 
			ISNULL(ITM.REFERENCE_1, 'NOT FOUND IN INSIGHT') AS COMMONNAME, 
			ISNULL(ITM.CLASSCODE, 'NOT FOUND') AS SIZE, 
			ISNULL(ITM.REFERENCE_5, 'NOT FOUND IN INSIGHT') AS SORTNAME, 
			ePLANT.SHIPPEDQTY AS CURRSHIPPEDQTY, 
			ePLANT.EXTMERCH AS CURREXTMERCH, 
			0 AS HIST1SHIPPEDQTY, 
			0 AS HIST1EXTMERCH 
		FROM GNC_SHIPPED_HISTORY ePLANT (NOLOCK)	--ePLANT HISTORY GOES BACK TO THE BEGINNING OF REPORTYEAR 2020 (07/28/2019) 
			LEFT JOIN IDMASTER WH (NOLOCK) ON WH.IDENTITYID = ePLANT.WAREHOUSEID 
			LEFT JOIN IMITEM ITM (NOLOCK) ON ITM.R_WAREHOUSE = WH.ROWID AND ITM.ITEMCODE = ePLANT.ITEMCODE 
			JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID 

		UNION ALL 

		--ePLANT DATASET: HIST1 
		SELECT 
			CO.COMPANYID, 
			CO.NAME AS COMPANYNAME, 
			'Z' AS RECORDTYPE, 
			WH.IDENTITYID AS WAREHOUSEID, 
			ePLANT.REPORTYEAR + 1 AS REPORTYEAR,								--ADD ONE EQUIVALENT YEAR 
			ePLANT.REPORTPERIOD,												--SHOULD BE THE EQUIVALENT PERIOD 
			ePLANT.REPORTWEEK,													--SHOULD BE THE EQUIVALENT WEEK 
			DBO.FN_DATE4NEXTYEAR(ePLANT.TRANSACTIONDATE) AS TRANSACTIONDATE,	--ADD ONE EQUIVALENT YEAR 
			ISNULL(ITM.ITEMCODE, ePLANT.ITEMCODE) AS ITEMCODE, 
			ISNULL(ITM.REFERENCE_1, 'NOT FOUND IN INSIGHT') AS COMMONNAME, 
			ISNULL(ITM.CLASSCODE, 'NOT FOUND') AS SIZE, 
			ISNULL(ITM.REFERENCE_5, 'NOT FOUND IN INSIGHT') AS SORTNAME, 
			0 AS CURRSHIPPEDQTY, 
			0 AS CURREXTMERCH, 
			ePLANT.SHIPPEDQTY AS HIST1SHIPPEDQTY, 
			ePLANT.EXTMERCH AS HIST1EXTMERCH 
		FROM GNC_SHIPPED_HISTORY ePLANT (NOLOCK)	--ePLANT HISTORY GOES BACK TO THE BEGINNING OF REPORTYEAR 2020 (07/28/2019) 
			LEFT JOIN IDMASTER WH (NOLOCK) ON WH.IDENTITYID = ePLANT.WAREHOUSEID 
			LEFT JOIN IMITEM ITM (NOLOCK) ON ITM.R_WAREHOUSE = WH.ROWID AND ITM.ITEMCODE = ePLANT.ITEMCODE 
			JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = WH.COMPANYID 
) X 
WHERE TRANSACTIONDATE <= GETDATE() 
GROUP BY 
	COMPANYID, 
	COMPANYNAME, 
	RECORDTYPE, 
	WAREHOUSEID, 
	REPORTYEAR, 
	REPORTPERIOD, 
	REPORTWEEK, 
	CAST(TRANSACTIONDATE AS DATE), 
	ITEMCODE, 
	COMMONNAME, 
	SIZE, 
	SORTNAME 
