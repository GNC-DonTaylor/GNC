/*
--44 DELIVERYRECEIPT (MULTIPLE VERSIONS)
SELECT VW_RPT_DELIVERYRECEIPT.* 
FROM VW_RPT_DELIVERYRECEIPT (NOLOCK) 
--Needed by Insight to run report from the OMScreens:
JOIN OMTRANSACTIONHEADER (NOLOCK) ON OMTRANSACTIONHEADER.ROWID = VW_RPT_DELIVERYRECEIPT.OHROWID
WHERE VW_RPT_DELIVERYRECEIPT.RECORDTYPE<>'P'
and VW_RPT_DELIVERYRECEIPT.transactionnumber = '10-13616'

SELECT C.CODE,C.DESCRIPTION_1,C.DESCRIPTION_2,COMMENT FROM IDCODES C WHERE C.CODETYPE='3D' ORDER BY CAST(C.CODE AS INT)
#	Description							Sort			ePlant
----------------------------------------------------------------
1	NoList Merch ExtMerch				PGP/SORT/SZ/Q	DELM7
2	List Merch ExtMerch					PGP/SORT/SZ/Q	DELM7
3	NoList Lowes NoPrc NoTot			SKU				DELM7LS
4	NoList NoPrc NoTot					PGP/SORT/SZ/Q	DELM7N
5	NoList Merch ExtMerch				SORT/SZ/Q		DELM8
6	NoList Menard NoPrc NoTot			SKU				DELM9
7	NoList Landed Ext NoTot				PGP/SORT/SZ/Q	DELU3
8	List Landed Ext NoTot				PGP/SORT/SZ/Q	DELU3
9	NoList AllPrices					PGP/SORT/SZ/Q	DELU3
10	NoList Orscheln Landed Ext GTotOnly	SKU				DELU3O
11	NoList Landed Ext GTotOnly			PGP/SORT/SZ/Q	DELU3T
*/
--------OLD VERSION OF VIEW WITHOUT SUBREPORT---------
--CREATE OR ALTER VIEW [DBO].[VW_RPT_DELIVERYRECEIPT]
--AS
--		SELECT *
--		FROM VW_RPT_OM_VERSION_MASTER (NOLOCK) 
--		WHERE RECORDTYPE<>'P'
--		AND STEP = 'COMPLETE'	--PER STEVE COPPEDGE
--------OLD VERSION OF VIEW WITHOUT SUBREPORT---------

CREATE OR ALTER VIEW [DBO].[VW_RPT_DELIVERYRECEIPT]
AS
SELECT 	U.*, 
--'DELIVERY RECEIPT' AS DELIVERYRECEIPTTEXT
IIF(ISINVOICE IS NULL,'* * * * DRAFT * * * *' + CHAR(10) + CHAR(13) + 'DELIVERY RECEIPT', 'DELIVERY RECEIPT') AS DELIVERYRECEIPTTEXT
FROM	(

		---------------------------------
		-- THIS IS THE PRIMARY DATASET --
		---------------------------------
		SELECT
			NULL AS ISCONTAINERSUBREPORT,
			NULL AS SUBREPORTCONTAINERSORT, *
		FROM VW_RPT_OM_VERSION_MASTER (NOLOCK) 
		WHERE RECORDTYPE<>'P'
		--AND STEP = 'COMPLETE'	--STEVE COPPEDGE WILL DECIDE ON THIS LATER
		AND (QUANTITYATSTAGE <> 0 OR QUANTITYBACKORDER <> 0) --SUPPRESS ZERO LINES UNLESS THERE'S A BACKORDER QTY -PER TEAM

UNION ALL

		---------------------------------------------
		-- THIS IS THE CONTAINER SUBREPORT DATASET --
		---------------------------------------------
		SELECT 
			'Y' AS ISCONTAINERSUBREPORT,
			CONTAINERSORT AS SUBREPORTCONTAINERSORT, *
		FROM VW_RPT_OM_VERSION_MASTER (NOLOCK) 
		WHERE RECORDTYPE<>'P'
		--AND STEP = 'COMPLETE'	--STEVE COPPEDGE WILL DECIDE ON THIS LATER
		) U
