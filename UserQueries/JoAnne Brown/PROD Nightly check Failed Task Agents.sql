--PROD Nightly check Failed Task Agents
--	by JoAnne

select PROCESSINGSTARTDATETIME, processingenddatetime,j.description jobdescritpion, reference, js.DESCRIPTION scheduledescription, js.COMMENT from abjobtask jt (nolock) 
--join abtasktype tt (nolock) on tt.tasktype = jt.tasktype
join abjob j (nolock) on j.rowid = jt.r_abjob
join abjobprocessing jp (nolock) on jp.r_abjob = j.rowid
--left outer join abjobprocessinglog jpl (nolock) on jpl.R_ABJOBPROCESSING = jp.rowid
join abjobschedule js (nolock) on js.rowid = jp.R_ABJOBSCHEDULE and js.r_abjob = j.rowid
--join abtaskqueuehistory tqh (nolock) on tqh.R_ABTASKPROCESSOR = jpl.rowid
--join ABAGENTQUEUE aq (nolock) on aq.rowid = jpl.R_QUEUETASK
where PROCESSINGRESULTFLAG = 'F' and processingstartdatetime > getdate() -1
