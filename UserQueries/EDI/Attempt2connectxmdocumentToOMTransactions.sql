--Attempt2connectxmdocumentToOMTransactions

--2B482FF9-E2DF-4751-BCF4-AAACAAC3DBAD		<<<<<<<<<<<<<<<<<<<
--select 
--oh.rowid, oh.TRANSACTIONNUMBER 
--from OMTRANSACTIONHEADER oh (nolock)
--where oh.TRANSACTIONNUMBER = '20-72949-29'

--select rowid, identityid, name from idmaster (nolock) where rowid = '5CD9264D-8CFE-4BBE-B343-30A7ECC506C6'	<<<<<<<<<<<

select * from 
--XMDOCUMENT	--rowid:83352E67-4A64-414C-94B1-07546449B863	<<<<<<<<<<<<
--XMEDIDOCUMENT	--rowid:84EAC4AC-45E3-430F-B65C-662A35C7FD1D	<<<<<<<
--XMEDIFUNCTIONALGROUP	--r_edimessage:E7CE6022-CC33-4FC1-9AA5-3B30BD66FBA6		<<<<<<
--!XMEDIMESSAGE	--rowid:E7CE6022-CC33-4FC1-9AA5-3B30BD66FBA6 !!!!!! r_edidocument:84EAC4AC-45E3-430F-B65C-662A35C7FD1D
--XMEXPORTDoc	--rowid:2B7E3EED-A7C4-4566-99E2-D269980A4230 r_exportmessage:023F9672-B80B-4BB3-942F-96B718B7B3F6   !!!!!!! r_edimessage:E7CE6022-CC33-4FC1-9AA5-3B30BD66FBA6
--XMEXPORTEVENT	--rowid:78823840-0EA4-4E72-85C8-78F01B249685 !!!!!! eventsourcerowid:2B482FF9-E2DF-4751-BCF4-AAACAAC3DBAD (omtransactionheader)
--XMEXPORTIDREL	--rowid:21D89D6E-9D35-4EFD-B127-D9BE84EC5CDF !!!!! identityrowid:5CD9264D-8CFE-4BBE-B343-30A7ECC506C6 (vendor id)
--XMEXPORTMESSAGE	--rowid:5CFD56BB-9E8E-4DA3-AC29-247679898A54 !!!!!! r_xmdocument:83352E67-4A64-414C-94B1-07546449B863 (xmdocument)

order by CREATIONDATETIME desc

--xmexportdoc:xmedimessage:xmedifunctionalgroup:xmedidocument

select 
* 

from xmexportdoc expdoc (nolock) 
join xmedimessage msg (nolock) on msg.rowid = expdoc.R_EDIMESSAGE 
join XMEDIDOCUMENT doc (nolock) on doc.rowid = msg.R_EDIDOCUMENT 
--join XMEXPORTMESSAGE expmsg (nolock) on expmsg.rowid = expdoc.R_EXPORTMESSAGE 
--join XMDOCUMENT xmdoc (nolock) on xmdoc.rowid = expmsg.R_XMDOCUMENT

order by expdoc.CREATIONDATETIME desc
