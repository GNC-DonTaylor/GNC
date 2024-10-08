--PIECING HISTORICAL TRANSACTION CODES BACK TOGETHER FROM ePLANT DAYS.
SELECT 
DBO.FN_DATE2YEAR(HIST.TRANSACTIONDATE) AS SALEYEAR, HIST.DIVISIONNUMBER, 
SUM(ISNULL(HIST.ADJUSTMENTQUANTITY,0)) AS ADJQTY, 
HIST.TRANSACTIONREASONCODE, TR.TRANSACTIONREASONDESCRIPTION, TR.TRANSACTIONEFFECT 

FROM GNC_ITEM_TRANSACTION_ARCHIVE HIST (NOLOCK) 
JOIN ORACLE..ROL.TRANSACTION_REASON TR (NOLOCK) ON TR.TRANSACTIONREASONCODE = HIST.TRANSACTIONREASONCODE 
WHERE HIST.DIVISIONNUMBER = '10' 
AND HIST.TRANSACTIONDATE > '07/30/2017' 
GROUP BY
DBO.FN_DATE2YEAR(HIST.TRANSACTIONDATE), HIST.DIVISIONNUMBER, 
HIST.TRANSACTIONREASONCODE, TR.TRANSACTIONREASONDESCRIPTION, TR.TRANSACTIONEFFECT 
ORDER BY
DBO.FN_DATE2YEAR(HIST.TRANSACTIONDATE), HIST.DIVISIONNUMBER, HIST.TRANSACTIONREASONCODE 
