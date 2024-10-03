--EDI Customer Validator

select cust.IDENTITYID, cust.name, cust.IDGROUP, ICUST.USERDEFINEDCODE_9 as isedicust, idterms.TERMSCODE
FROM IDMASTER CUST (NOLOCK)
JOIN IDCUSTOMER ICUST (NOLOCK) ON ICUST.R_IDENTITY = CUST.ROWID
LEFT JOIN IDTERMS (NOLOCK) ON IDTERMS.ROWID = ICUST.R_TERMS
where cust.name like '%pike%'--cust.IDGROUP = '467'--'35'

select x.whid, x.SALEYEAR, custname, sum(ordertotal) as exttotal 
from (
	select wh.IDENTITYID as whid, DBO.FN_DATE2YEAR(OH.INVOICEDATE) AS SALEYEAR, cust.NAME as custname,  oh.TRANSACTIONNUMBER, DBO.FN_ORDERVALUE(OH.ROWID,NULL) AS ORDERTOTAL,
	ISNULL(ICUST.USERDEFINEDCODE_8, 'N') AS NATLACCT	--ADD PER ERICA 4/7/22 - DT
	from OMTRANSACTIONHEADER oh (nolock) 
	join idmaster wh (nolock) on wh.rowid = oh.R_FMSHIPPER 
	join idmaster cust (nolock) on cust.rowid = oh.R_CUSTOMER 
	join idcustomer icust (nolock) on icust.R_IDENTITY = oh.R_CUSTOMER 
	where cust.IDGROUP = '406'
	--order by wh.IDENTITYID, OH.INVOICEDATE, cust.NAME,  oh.TRANSACTIONNUMBER, ISNULL(ICUST.USERDEFINEDCODE_8, 'N')
) x
group by x.whid, x.SALEYEAR, custname

--pikes is group 406 (high volume business Million$+)
--buchheit is group 544 (not doing much business 30-40k/year)
--fleetfarm is group 540 (not doing much business 30k/year)
--tractorsupply is group 543 (70-170k/year)



