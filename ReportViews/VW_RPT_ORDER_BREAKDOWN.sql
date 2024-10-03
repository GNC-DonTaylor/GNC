/*
--105 Order Breakdown (19,106,107)
SELECT
VW_RPT_ORDER_BREAKDOWN.*
FROM VW_RPT_ORDER_BREAKDOWN (NOLOCK)
WHERE VW_RPT_ORDER_BREAKDOWN.RECORDTYPE <> 'P'
and VW_RPT_ORDER_BREAKDOWN.transactionnumber = '10-11359'

--107 Order with Hold Ship
SELECT
VW_RPT_ORDER_BREAKDOWN.*
FROM VW_RPT_ORDER_BREAKDOWN (NOLOCK)
WHERE VW_RPT_ORDER_BREAKDOWN.RECORDTYPE = 'R' 
AND VW_RPT_ORDER_BREAKDOWN.HOLDSTOPCODE = 'H'

--TA Order with Hold Ship
SELECT
VW_RPT_ORDER_BREAKDOWN.*
FROM VW_RPT_ORDER_BREAKDOWN (NOLOCK)
WHERE VW_RPT_ORDER_BREAKDOWN.RECORDTYPE = 'R' 
AND VW_RPT_ORDER_BREAKDOWN.HOLDSTOPCODE = 'H'
AND VW_RPT_ORDER_BREAKDOWN.STEP IN ('WAITING', 'SHIPPABLE')
AND VW_RPT_ORDER_BREAKDOWN.REQUESTDATE BETWEEN GETDATE()-(4*7) AND GETDATE()+(2*7)

-------------------------------------------------
--and VW_RPT_ORDER_BREAKDOWN.salesrepid in 
--('S03','S12','S15','S18','S19','S20','S22')
--('S21','S23')
order by VW_RPT_ORDER_BREAKDOWN.salesrepid
*/

CREATE OR ALTER VIEW [DBO].[VW_RPT_ORDER_BREAKDOWN]
AS
SELECT
VW_RPT_OM_VERSION_MASTER.*,
ISNULL(TRIM(VW_RPT_OM_VERSION_MASTER.COMMONNAME),'') + ' ' + ISNULL(TRIM(VW_RPT_OM_VERSION_MASTER.PATENTNUMBER),'') AS COMMONNAMEPATENT,
VW_RPT_OM_VERSION_MASTER.REQUESTDATETYPE + ' '
	+ CONVERT(VARCHAR(10),VW_RPT_OM_VERSION_MASTER.REQUESTDATE,101) AS REQUESTEDTEXT
FROM VW_RPT_OM_VERSION_MASTER (NOLOCK) 
WHERE VW_RPT_OM_VERSION_MASTER.RECORDTYPE <> 'P'

