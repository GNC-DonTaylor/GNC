--latetripcommits
select 
datediff(d, oh.INVOICEDATE, oh.LASTUPDATEDATETIME) as headertouch, 
cast(oh.LASTUPDATEDATETIME as date) as touchdatesort, 
oh.INVOICEDATE, oh.LASTUPDATEDATETIME, oh.LASTUPDATEUSERID, 
cust.IDENTITYID as customerid, cust.name as customername, cust.IDGROUP, 
oh.TRANSACTIONNUMBER, oh.TRANSACTIONTYPE, oh.PURCHASEORDERNUMBER, 
datediff(d, oh.INVOICEDATE, od.LASTUPDATEDATETIME) as detailtouch, 
od.LASTUPDATEDATETIME, od.LINENUMBER, itm.ITEMCODE 
from OMTRANSACTIONHEADER oh (nolock) 
join idmaster cust (nolock) on cust.rowid = oh.R_CUSTOMER
left join OMTRANSACTIONDETAIL od (nolock) on od.R_TRANSACTIONHEADER = oh.rowid and od.LASTUPDATEDATETIME > oh.INVOICEDATE 
left join imitem itm (nolock) on itm.rowid = od.R_ITEM

where oh.LASTUPDATEDATETIME > oh.INVOICEDATE
--and oh.TRANSACTIONNUMBER in ('20-55631','20-55568')

order by cast(oh.LASTUPDATEDATETIME as date) desc, oh.INVOICEDATE desc, oh.TRANSACTIONNUMBER