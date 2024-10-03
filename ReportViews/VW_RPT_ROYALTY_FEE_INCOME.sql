/*
--ROYALTY FEE INCOME
SELECT
*
--warehouseid, INVOICEDATE, itemcode, qtyinvoiced, qtymemoed, miscfeecode, licenserate, interdivrate, sublicenserate, qtytotal, licenseratetotal, interdivratetotal, sublicenseratetotal
FROM VW_RPT_ROYALTY_FEE_INCOME (NOLOCK)
WHERE COMPANYID = 'SB'
--AND VARIETY ='000193'--''003150'--in ('003150','003152')--= '002917'--'005252'
and itemcode = '001501.007.1'--'000193.031.1'
--and holderid in ('GRE087','LIC003')
and warehouseid = '10'
ORDER BY variety,itemcode, 
--miscfeecode, 
INVOICEDATE
*/
CREATE OR ALTER VIEW [DBO].[VW_RPT_ROYALTY_FEE_INCOME]
AS

--COMBINE DATASETS WITHOUT DOUBLING THE QTYINVOICED, QTYMEMOED, QTYNETWORK AMOUNTS
SELECT 
	C.COMPANYID, C.COMPANYNAME, 
	C.WAREHOUSEID, C.WAREHOUSENAME, 
	C.STAGE, C.RECORDTYPE, 
	C.INVOICEDATE, c.transactionnumber, 
	C.TRANSACTIONTYPE, c.linenumber, 
	C.CREDITREASONCODE, 
	C.NETWORKTEXT, 
	ISNULL(C.QTYINVOICED,0) AS QTYINVOICED, 
	ISNULL(C.QTYMEMOED,0) AS QTYMEMOED, 
	ISNULL(C.QTYNETWORK,0) AS QTYNETWORK, 
	C.LICPRIMARYHOLDER, 
	C.LICPRIMARYHOLDERDESC, 
	C.ITEMCODE, C.COMMONNAME, --C.PATENT, 
	C.BRAND, 
--	C.R_FEES, 
	C.VARIETY, C.VARIETYDESCRIPTION, 
	C.PRINTEDCONTAINERCODE, C.CONTAINERCODE, C.FREIGHTCLASSCODE, 
	LEFT(C.MISCFEECODE,6) AS MISCFEECODE,  
	--C.MISCFEECODE, 
	sum(C.LICENSERATE) AS LICENSERATE, 
	sum(C.INTERDIVRATE) AS INTERDIVRATE, 
	sum(C.SUBLICENSERATE) AS SUBLICENSERATE, 
--	C.EFFECTIVESTARTDATE, 
	C.HOLDERID, C.HOLDERNAME, 
	max(C.QTYTOTAL) AS QTYTOTAL, 
	sum(C.LICENSERATETOTAL) AS LICENSERATETOTAL, 
	sum(C.INTERDIVRATETOTAL) AS INTERDIVRATETOTAL, 
	sum(C.SUBLICENSERATETOTAL) AS SUBLICENSERATETOTAL 
FROM (
		SELECT * FROM VW_RPT_ROYALTY_EXPENSE (NOLOCK)
		--WHERE ISNULL(LICENSERATE,0) != 0
		UNION ALL
		SELECT

			X.*, 
			X.QTYINVOICED + X.QTYMEMOED AS QTYTOTAL,
			X.LICENSERATE * (X.QTYINVOICED + X.QTYMEMOED) AS LICENSERATETOTAL, 
			X.INTERDIVRATE * (X.QTYINVOICED + X.QTYMEMOED) AS INTERDIVRATETOTAL, 
			X.SUBLICENSERATE * (X.QTYINVOICED + X.QTYMEMOED) AS SUBLICENSERATETOTAL	
		FROM (
				SELECT 
					CO.COMPANYID, CO.NAME AS COMPANYNAME, 
					WH.IDENTITYID AS WAREHOUSEID, WH.NAME AS WAREHOUSENAME, 
					OH.STAGE, OH.RECORDTYPE, 
					OH.INVOICEDATE, oh.TRANSACTIONNUMBER,	--added Transactionnumber to unhide qty found on Cube. (2 Invoices, same date, same item was fuzzing Max(QTYTOTAL) above^)
					OH.TRANSACTIONTYPE, od.LINENUMBER,		--added Linenumber to unhide qty found on Cube. (2 detailines, same Invoice, same item was fuzzing Max(QTYTOTAL) above^)
					OD.USERDEFINEDCODE_1 AS CREDITREASONCODE, 
					OD.USERDEFINEDREFERENCE_2 AS NETWORKTEXT, 
					IIF(OH.TRANSACTIONTYPE = 'I', OD.QUANTITYSHIPPED, 0) AS QTYINVOICED, 
					IIF(OH.TRANSACTIONTYPE IN ('C','J') AND LEFT(OD.USERDEFINEDCODE_1,2) = 'FC', OD.QUANTITYSHIPPED * -1, 0) AS QTYMEMOED, 
					IIF(OD.USERDEFINEDREFERENCE_2 LIKE '%NETWORK%', OD.QUANTITYSHIPPED, 0) AS QTYNETWORK, 
					ITM.USERDEFINEDCODE_16 AS LICPRIMARYHOLDER, 
					(SELECT C4.DESCRIPTION_1 FROM IMCODES C4 (NOLOCK) WHERE C4.CODE = ITM.USERDEFINEDCODE_16 AND C4.CODETYPE = 'C4') AS LICPRIMARYHOLDERDESC, 
					ITM.ITEMCODE, ITM.REFERENCE_1 AS COMMONNAME, --NULLIF(ITM.USERDEFINEDREFERENCE_1,'') AS PATENT, 
					ITM.USERDEFINEDCODE_2 AS BRAND, 
					OD.R_FEES, 
					ITMP.PROFILECODE AS VARIETY, ITMP.DESCRIPTION VARIETYDESCRIPTION, 
					CNT.PRINTEDCONTAINERCODE, CNT.CONTAINERCODE, CNT.FREIGHTCLASSCODE, 
					J.MISCFEECODE, 
					J.LICENSERATE, 
					J.INTERDIVRATE, 
					J.SUBLICENSERATE, 
					J.EFFECTIVESTARTDATE, 
					J.HOLDERID, J.HOLDERNAME
				FROM OMTRANSACTIONHEADER OH (NOLOCK) 
					JOIN  OMTRANSACTIONDETAIL OD (NOLOCK) ON OD.R_TRANSACTIONHEADER = OH.ROWID 
					JOIN ABCOMPANY CO (NOLOCK) ON CO.COMPANYID = OH.COMPANYID 
					JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = OH.R_FMSHIPPER 
					JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = OD.R_ITEM 
					JOIN IMITEMDP ITMP (NOLOCK) ON ITMP.ROWID = ITM.R_PROFILE 
					JOIN IMCONTAINER CNT (NOLOCK) ON CNT.ROWID = ITM.R_CONTAINERCODE 
					/*LEFT*/ JOIN (
							SELECT 
								U.MISCFEECODE, 
								U.VARIETY, U.FREIGHTCLASSCODE, 
								SUM(U.LICENSERATE) AS LICENSERATE,
								SUM(U.INTERDIVRATE) AS INTERDIVRATE,
								SUM(U.SUBLICENSERATE) AS SUBLICENSERATE,
								U.EFFECTIVESTARTDATE, U.HOLDERID, U.HOLDERNAME
							FROM ( 

									--VARIETY LEVEL INTERDIV
									SELECT 
									FH.MISCFEECODE, 
									LEFT(FH.MISCFEECODE,6) AS VARIETY, 
									'%' AS FREIGHTCLASSCODE, 
									0 AS LICENSERATE, 
									FD.RATE AS INTERDIVRATE, 
									0 AS SUBLICENSERATE, 
									FD.EFFECTIVESTARTDATE, 
									VEND.IDENTITYID AS HOLDERID, VEND.NAME AS HOLDERNAME 
									FROM IMFEESHEADER FH (NOLOCK)
									JOIN IMFEESDETAIL FD (NOLOCK) ON FD.R_FEESHEADER = FH.ROWID AND FD.DESCRIPTION = 'Interdivision Fee1'
									LEFT JOIN /*IMFEESDP*/IDDISCOUNTDP FP (NOLOCK) ON FP.ROWID = FH.R_PROFILE --R_PROFILE IN THE WRONG TABLE FOR NOW!!!
									JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = FD.R_VENDOR 
									WHERE FD.RECORDTYPE = 'R' 
									AND FD.RATE IS NOT NULL 
									AND ISNULL(FP.PROFILECODE, 'SUBFEES') = 'SUBFEES'
									AND VEND.IDENTITYID IN ('GRE087','LIC003')
									AND SUBSTRING(FH.MISCFEECODE,NULLIF(CHARINDEX('.', FH.MISCFEECODE),0),3) = '.89'

									UNION ALL

									--VARIETY LEVEL SUBLICENSE
									SELECT 
									FH.MISCFEECODE, 
									LEFT(FH.MISCFEECODE,6) AS VARIETY, 
									'%' AS FREIGHTCLASSCODE, 
									0 AS LICENSERATE, 
									0 AS INTERDIVRATE, 
									FD.RATE AS SUBLICENSERATE, 
									FD.EFFECTIVESTARTDATE, 
									VEND.IDENTITYID AS HOLDERID, VEND.NAME AS HOLDERNAME 
									FROM IMFEESHEADER FH (NOLOCK)
									JOIN IMFEESDETAIL FD (NOLOCK) ON FD.R_FEESHEADER = FH.ROWID AND FD.DESCRIPTION = 'Sublicense Fee1'
									LEFT JOIN /*IMFEESDP*/IDDISCOUNTDP FP (NOLOCK) ON FP.ROWID = FH.R_PROFILE --R_PROFILE IN THE WRONG TABLE FOR NOW!!!
									JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = FD.R_VENDOR 
									WHERE FD.RECORDTYPE = 'R' 
									AND FD.RATE IS NOT NULL 
									AND ISNULL(FP.PROFILECODE, 'SUBFEES') = 'SUBFEES'
									AND VEND.IDENTITYID IN ('GRE087','LIC003')
									AND SUBSTRING(FH.MISCFEECODE,NULLIF(CHARINDEX('.', FH.MISCFEECODE),0),3) = '.89'

									UNION ALL

									--CLASS LEVEL INTERDIV
									SELECT 
									FH.MISCFEECODE, 
									LEFT(FH.MISCFEECODE,6) AS VARIETY, 
									CASE SUBSTRING(FH.MISCFEECODE,NULLIF(CHARINDEX('.', FH.MISCFEECODE),0),3)
										--WHEN '.1' THEN 'C008'
										WHEN '.1' THEN 'C010'
										WHEN '.2' THEN 'C020'
										WHEN '.3' THEN 'C030'
										WHEN '.4' THEN 'C040'
										WHEN '.5' THEN 'C050'
										WHEN '.7' THEN 'C070'
										WHEN '.10' THEN 'C100'
									ELSE NULL END AS FREIGHTCLASSCODE, 
									0 AS LICENSERATE, 
									FD.RATE AS INTERDIVRATE, 
									0 AS SUBLICENSERATE, 
									FD.EFFECTIVESTARTDATE, 
									VEND.IDENTITYID AS HOLDERID, VEND.NAME AS HOLDERNAME 
									FROM IMFEESHEADER FH (NOLOCK)
									JOIN IMFEESDETAIL FD (NOLOCK) ON FD.R_FEESHEADER = FH.ROWID AND FD.DESCRIPTION = 'Interdivision Fee1'
									LEFT JOIN /*IMFEESDP*/IDDISCOUNTDP FP (NOLOCK) ON FP.ROWID = FH.R_PROFILE --R_PROFILE IN THE WRONG TABLE FOR NOW!!!
									JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = FD.R_VENDOR 
									WHERE FD.RECORDTYPE = 'R' 
									AND FD.RATE IS NOT NULL 
									AND ISNULL(FP.PROFILECODE, 'SUBFEES') = 'SUBFEES'
									AND VEND.IDENTITYID IN ('GRE087','LIC003')
									AND SUBSTRING(FH.MISCFEECODE,NULLIF(CHARINDEX('.', FH.MISCFEECODE),0),3) != '.89'

									UNION ALL

									--CLASS LEVEL SUBLICENSE
									SELECT 
									FH.MISCFEECODE, 
									LEFT(FH.MISCFEECODE,6) AS VARIETY, 
									CASE SUBSTRING(FH.MISCFEECODE,NULLIF(CHARINDEX('.', FH.MISCFEECODE),0),3)
										--WHEN '.1' THEN 'C008'
										WHEN '.1' THEN 'C010'
										WHEN '.2' THEN 'C020'
										WHEN '.3' THEN 'C030'
										WHEN '.4' THEN 'C040'
										WHEN '.5' THEN 'C050'
										WHEN '.7' THEN 'C070'
										WHEN '.10' THEN 'C100'
									ELSE NULL END AS FREIGHTCLASSCODE, 
									0 AS LICENSERATE, 
									0 AS INTERDIVRATE, 
									FD.RATE AS SUBLICENSERATE, 
									FD.EFFECTIVESTARTDATE, 
									VEND.IDENTITYID AS HOLDERID, VEND.NAME AS HOLDERNAME 
									FROM IMFEESHEADER FH (NOLOCK)
									JOIN IMFEESDETAIL FD (NOLOCK) ON FD.R_FEESHEADER = FH.ROWID AND FD.DESCRIPTION = 'Sublicense Fee1'
									LEFT JOIN /*IMFEESDP*/IDDISCOUNTDP FP (NOLOCK) ON FP.ROWID = FH.R_PROFILE --R_PROFILE IN THE WRONG TABLE FOR NOW!!!
									JOIN IDMASTER VEND (NOLOCK) ON VEND.ROWID = FD.R_VENDOR 
									WHERE FD.RECORDTYPE = 'R' 
									AND FD.RATE IS NOT NULL 
									AND ISNULL(FP.PROFILECODE, 'SUBFEES') = 'SUBFEES'
									AND VEND.IDENTITYID IN ('GRE087','LIC003')
									AND SUBSTRING(FH.MISCFEECODE,NULLIF(CHARINDEX('.', FH.MISCFEECODE),0),3) != '.89'

							) U
							GROUP BY 	U.MISCFEECODE, U.VARIETY, U.FREIGHTCLASSCODE, U.EFFECTIVESTARTDATE, U.HOLDERID, U.HOLDERNAME
					) J ON	J.VARIETY = ITMP.PROFILECODE 
							AND (J.FREIGHTCLASSCODE IN ('%', CNT.FREIGHTCLASSCODE) OR (J.FREIGHTCLASSCODE='C010' AND CNT.FREIGHTCLASSCODE='C008')) 
							AND J.EFFECTIVESTARTDATE <= OH.INVOICEDATE
				WHERE OH.RECORDTYPE <> 'P' 
				AND LEFT(OH.TRANSACTIONNUMBER,2) != 'IC' --EXCLUDE INTERCOMPANY ORDERS 
				AND WH.IDENTITYID < '999' 
		) X 
) C
GROUP BY 
	C.COMPANYID, C.COMPANYNAME, 
	C.WAREHOUSEID, C.WAREHOUSENAME, 
	C.STAGE, C.RECORDTYPE, 
	C.INVOICEDATE, c.transactionnumber, 
	C.TRANSACTIONTYPE, c.linenumber, 
	C.CREDITREASONCODE, 
	C.NETWORKTEXT, 
	C.QTYINVOICED, 
	C.QTYMEMOED, 
	C.QTYNETWORK, 
	C.LICPRIMARYHOLDER, 
	C.LICPRIMARYHOLDERDESC, 
	C.ITEMCODE, C.COMMONNAME, --C.PATENT, 
	C.BRAND, 
--	C.R_FEES, 
	C.VARIETY, C.VARIETYDESCRIPTION, 
	C.PRINTEDCONTAINERCODE, C.CONTAINERCODE, C.FREIGHTCLASSCODE, 
	LEFT(C.MISCFEECODE,6), 
	--C.MISCFEECODE, 
	--SUM(C.LICENSERATE) AS LICENSERATE, 
	--SUM(C.INTERDIVRATE) AS INTERDIVRATE, 
	--SUM(C.SUBLICENSERATE) AS SUBLICENSERATE 
--	C.EFFECTIVESTARTDATE, 
	C.HOLDERID, C.HOLDERNAME
