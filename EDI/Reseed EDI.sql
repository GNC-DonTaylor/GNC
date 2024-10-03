--Reseed EDI
dbcc checkident ('dbo.XMEdiMessage', RESEED, 500000000)
dbcc checkident ('dbo.XMExportDoc', RESEED, 1000)
dbcc checkident ('dbo.XMExportFuncGroup', RESEED, 1000)
dbcc checkident ('dbo.XMExportMessage', RESEED, 1000)
dbcc checkident ('dbo.XMAscExpEnvelope', RESEED, 1)

select max(CONTROLNUMBER)
from XMEDIMESSAGE
select max(CONTROLNUMBER)
from XMEXPORTDOC
select max(CONTROLNUMBER)
from XMEXPORTFUNCGROUP
select max(MessageID)
from XMEXPORTMESSAGE
select max(CONTROLNUMBER)
from XMASCEXPENVELOPE

