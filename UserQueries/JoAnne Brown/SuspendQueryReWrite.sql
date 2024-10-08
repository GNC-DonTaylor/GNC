--SuspendQueryReWrite


--MY REWRITE:
SELECT *
FROM (
		SELECT  
		CUST.IDENTITYID AS CUSTOMERID,  
		CUST.NAME AS CUSTOMERNAME, 
		MCA.VALUE AS MCATTRIBUREVALUE, 
		ISNULL(LOT.USERDEFINEDCODE_5,'') AS LOTSUSPENDVALUEUDC5, 
		WH.IDENTITYID AS WAREHOUSEID, 
		ITM.ITEMCODE, 
		LOT.LOTCODE, 
		LOC.LOCATIONCODE, 
		LOT.DESCRIPTION_1 
		FROM OMREVIEWMASTERCODES MC (NOLOCK) 
			JOIN OMREVIEWMASTERCODEATTRIBUTES MCA (NOLOCK) ON MCA.R_MASTERCODE = MC.ROWID 
			JOIN OMREVIEWATTRIBUTES A (NOLOCK ) ON A.ROWID = MCA.R_ATTRIBUTE AND A.NAME = 'SUSPEND' 
			JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = MC.R_ITEM 
			JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = MC.R_LOT 
			JOIN IMLOCATION LOC (NOLOCK) ON LOC.ROWID = MC.R_LOCATION 
			JOIN IDMASTER WH (NOLOCK) ON WH.ROWID = ITM.R_WAREHOUSE 
			LEFT JOIN IDMASTER CUST(NOLOCK) ON CUST.ROWID = MC.R_CUSTOMER 
			LEFT JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.ROWID = CUST.ROWID 
		WHERE MC.STATUS = 'A' AND LOT.STATUS = 'A'
) X
WHERE MCATTRIBUREVALUE != LOTSUSPENDVALUEUDC5

--JOANNE SOURCE:
/*
SELECT  MAST.NAME CUSTOMERNAME, MAST.IDENTITYID CUSTID,  MCA.VALUE MCATTRIBUREVALUE ,ISNULL(L.USERDEFINEDCODE_5,'') AS LOTSUSPENDVALUEUDC5
, DBO.FN_GETIDENTITYID(I.R_WAREHOUSE) WAREHOUSE,I.ITEMCODE, L.LOTCODE, 
LOC.LOCATIONCODE, L.DESCRIPTION_1,L.*
FROM IMLOT L (NOLOCK) 
JOIN  OMREVIEWMASTERCODES MC (NOLOCK) ON MC.R_LOT = L.ROWID 
JOIN OMREVIEWMASTERCODEATTRIBUTES MCA (NOLOCK) ON MCA.R_MASTERCODE = MC.ROWID 
JOIN OMREVIEWATTRIBUTES A (NOLOCK ) ON A.ROWID = MCA.R_ATTRIBUTE AND A.NAME = 'SUSPEND'
JOIN IMITEM I (NOLOCK) ON I.ROWID = L.R_ITEM
JOIN IMLOCATION LOC (NOLOCK) ON LOC.ROWID = MC.R_LOCATION
LEFT JOIN IDCUSTOMER CUST (NOLOCK) ON CUST.ROWID = MC.R_CUSTOMER
LEFT JOIN IDMASTER MAST(NOLOCK) ON MAST.ROWID = CUST.R_IDENTITY
WHERE MC.STATUS = 'A' AND L.STATUS = 'A'
*/