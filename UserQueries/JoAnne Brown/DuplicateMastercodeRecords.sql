--DuplicateMastercodeRecords
--=====================================================
--Find master codes where values in these fields:  
--item/lot/location/source/desig cust/desig item/desig loc.  are identical to each other   
--That constitutes a duplicate mastercode. 

--=====================================================
--JN: JOIN ORIGINAL ROWID FROM OMREVIEWMASTERCODES TABLE TO THE FINAL RESULTS:
SELECT MC.ROWID, 
--++ Plus these fields requested by Ellen--++--
'{Need Source}' AS PTR_AVAIL, 
'{Need Source}' AS Avail_Qty, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'Priority') AS Priority, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'PriSetBy') AS PriSetBy, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'PriUpdate') AS PriUpdate, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'Location Note') AS Location_Note, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'LocNoteDate') AS LocNoteDate, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'LocationPTN1') AS LocationPTN1, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'LocationPTN2') AS LocationPTN2, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'LastProdSchLine#') AS LastProdSchLine#, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'LastTransText') AS LastTransText, 
'{Need Source}' AS Last_Updated, 
DBO.FN_MCATTRIBUTES(MC.ROWID,'LastPltgDate') AS LastPltgDate, 
--++---------------------------------------++--
JN.* 
FROM OMREVIEWMASTERCODES MC (NOLOCK) 
JOIN (	
		--=====================================================
		--DP: ONLY SHOW DUPLICATES: CNT > 1
		SELECT DP.* FROM (
				--=====================================================
				--CT: COUNT EACH OCCURANCE OF THE GROUPED DATASET:
				SELECT CT.*, COUNT(*) AS CNT
				FROM (	
						--=====================================================
						--LIST ALL MASTERCODES RELATED TO ITEM/LOT/LOCATIONS:
						SELECT 
						MC.R_ITEM, MC.R_LOT, MC.R_LOCATION,  
						ITM.ITEMCODE, LOT.LOTCODE, LOC.LOCATIONCODE, 
						DBO.FN_MCATTRIBUTES(MC.ROWID,'SOURCE') AS SOURCE, 
						DBO.FN_MCATTRIBUTES(MC.ROWID, 'DesigItem') AS DESIGITEM, 
						DBO.FN_MCATTRIBUTES(MC.ROWID, 'DesigCust') AS DESIGCUST, 
						DBO.FN_MCATTRIBUTES(MC.ROWID, 'DesigLoc') AS DESIGLOC 
						FROM OMREVIEWMASTERCODES MC (NOLOCK)
							JOIN IMITEM ITM (NOLOCK) ON ITM.ROWID = MC.R_ITEM
							JOIN IMLOT LOT (NOLOCK) ON LOT.ROWID = MC.R_LOT 
							JOIN IMLOCATION LOC (NOLOCK) ON LOC.ROWID = MC.R_LOCATION
						--ORDER BY	ITM.ITEMCODE, LOT.LOTCODE, LOC.LOCATIONCODE--, SOURCE, DESIGITEM, DESIGCUST, DESIGLOC
						--=====================================================
				) CT
				GROUP BY	R_ITEM, R_LOT, R_LOCATION, ITEMCODE, LOTCODE, LOCATIONCODE, SOURCE, DESIGITEM, DESIGCUST, DESIGLOC
				--ORDER BY	ITEMCODE, LOTCODE, LOCATIONCODE, SOURCE, DESIGITEM, DESIGCUST, DESIGLOC
		--=====================================================
		) DP 
		WHERE DP.CNT > 1
--=====================================================
) JN ON	MC.R_ITEM		= JN.R_ITEM 
	AND MC.R_LOT		= JN.R_LOT 
	AND MC.R_LOCATION	= JN.R_LOCATION
ORDER BY JN.R_ITEM, JN.R_LOT, JN.R_LOCATION 

--=====================================================
