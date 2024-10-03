--useful XM tables to be aware of:
select * from XMASCEXPENVELOPE (nolock)
select * from XMASCEXPMAPDEF (nolock)
select * from XMDOCUMENT (nolock)
select * from XMEDIDOCUMENT (nolock)
select * from XMEDIMESSAGE (nolock)	--might be useful
select * from XMINSIGHTOBJ (nolock)	--tables you can update/insert into
select * from XMINSIGHTOBJCOL (nolock)	--columns you can update/insert into
select * from XMLOG (nolock)	--XM Error log
select * from XMMAPDEF (nolock)	--XM Lookups in use
select * from XMTRADEPARTNER (nolock)	--useful

--possible in the future for reporting purposes:
select * from XMEDITRANSET (nolock)	--
select * from XMEXPORTDEST (nolock)	--
select * from XMEXPORTDOC (nolock)	--
select * from XMEXPORTEVENT (nolock)	--
select * from XMEXPORTFUNCGROUP (nolock)	--
select * from XMEXPORTIDREL (nolock)	--
select * from XMEXPORTMAPDEF (nolock)	--
select * from XMEXPORTMESSAGE (nolock)	--
select * from XMEXPORTTRIGGER (nolock)	--
--possibly others...





