--LOTDATEAVAILABLEVALUES
select distinct * from (
select distinct 
--(	select wh.IDENTITYID from imitem itm (nolock)
--	join idmaster wh (nolock) on wh.rowid = itm.R_WAREHOUSE
--	where itm.rowid = lot.R_ITEM
--	) as WHID,
lot.LOTCODE,
lot.DATEAVAILABLE 
from IMLOT lot (nolock) 
where lot.LOTCODE like '25%'
) x
group by LOTCODE, DATEAVAILABLE
order by LOTCODE, DATEAVAILABLE
--group by whid, LOTCODE, DATEAVAILABLE
--order by LOTCODE, whid, DATEAVAILABLE
