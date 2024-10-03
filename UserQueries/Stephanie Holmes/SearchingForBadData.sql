/*
	(	SELECT COMMENT FROM IDSYNONYMS SYN (NOLOCK) 
		WHERE SYN.R_IDENTITY=CONS.ROWID AND SYN.USERDEFINEDCODE_1='ACK'
		) AS SYNEMAILACK,
*/

SELECT * FROM (
	SELECT CONS.IDENTITYID, CONS.NAME AS CONSIGNEENAME, SYN.NAME AS SYNONYMNAME, 
	--SYN.IDTYPE, 
	SYN.USERDEFINEDCODE_1, COUNT(*) AS CNT
	FROM IDMASTER CONS (NOLOCK)
	JOIN IDSYNONYMS SYN (NOLOCK) ON SYN.R_IDENTITY = CONS.ROWID
	WHERE --SYN.NAME = '822813'--
	SYN.USERDEFINEDCODE_1 = 'ACK'
	GROUP BY CONS.IDENTITYID, CONS.NAME, SYN.NAME, 
	--SYN.IDTYPE, 
	SYN.USERDEFINEDCODE_1
) X WHERE X.CNT > 1


