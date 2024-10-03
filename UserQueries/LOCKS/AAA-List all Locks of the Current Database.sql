-- AAA-List all Locks of the Current Database 
SELECT TL.resource_type AS ResType 
     -- ,TL.resource_description AS ResDescr 
      ,TL.request_mode AS ReqMode 
  --    ,TL.request_type AS ReqType 
   --   ,TL.request_status AS ReqStatus 
  --    ,TL.request_owner_type AS ReqOwnerType 
      ,TAT.[name] AS TransName 
      ,TAT.transaction_begin_time AS TransBegin 
      ,DATEDIFF(ss, TAT.transaction_begin_time, GETDATE()) AS TransDura 
      ,ES.session_id AS S_Id 
      ,ES.login_name AS LoginName 
      ,COALESCE(OBJ.name, PAROBJ.name) AS ObjectName 
      ,PARIDX.name AS IndexName 
      ,ES.host_name AS HostName 
      ,ES.program_name AS ProgramName 
FROM sys.dm_tran_locks AS TL 
     INNER JOIN sys.dm_exec_sessions AS ES 
         ON TL.request_session_id = ES.session_id 
     LEFT JOIN sys.dm_tran_active_transactions AS TAT 
         ON TL.request_owner_id = TAT.transaction_id 
            AND TL.request_owner_type = 'TRANSACTION' 
     LEFT JOIN sys.objects AS OBJ 
         ON TL.resource_associated_entity_id = OBJ.object_id 
            AND TL.resource_type = 'OBJECT' 
     LEFT JOIN sys.partitions AS PAR 
         ON TL.resource_associated_entity_id = PAR.hobt_id 
            AND TL.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') 
     LEFT JOIN sys.objects AS PAROBJ 
         ON PAR.object_id = PAROBJ.object_id 
     LEFT JOIN sys.indexes AS PARIDX 
         ON PAR.object_id = PARIDX.object_id 
            AND PAR.index_id = PARIDX.index_id 
WHERE TL.resource_database_id  = DB_ID() 
      AND ES.session_id <> @@Spid -- Exclude "my" session 
      -- optional filter  
	  and es.host_name <> 'gncta'
      AND TL.request_mode not in ('IS','Sch-S' ,'S') -- Exclude simple shared locks 
	--  AND ES.login_name in ('krystal_tiger','janelle_carroll')
ORDER BY TL.resource_type 
        ,TL.request_mode 
        ,TL.request_type 
        ,TL.request_status 
        ,ObjectName 
        ,ES.login_name;


/*
--TSQL commands
SELECT 
       db_name(rsc_dbid) AS 'DATABASE_NAME',
       case rsc_type when 1 then 'null'
                             when 2 then 'DATABASE' 
                             WHEN 3 THEN 'FILE'
                             WHEN 4 THEN 'INDEX'
                             WHEN 5 THEN 'TABLE'
                             WHEN 6 THEN 'PAGE'
                             WHEN 7 THEN 'KEY'
                             WHEN 8 THEN 'EXTEND'
                             WHEN 9 THEN 'RID ( ROW ID)'
                             WHEN 10 THEN 'APPLICATION' end  AS 'REQUEST_TYPE',

       CASE req_ownertype WHEN 1 THEN 'TRANSACTION'
                                     WHEN 2 THEN 'CURSOR'
                                     WHEN 3 THEN 'SESSION'
                                     WHEN 4 THEN 'ExSESSION' END AS 'REQUEST_OWNERTYPE',

       OBJECT_NAME(rsc_objid ,rsc_dbid) AS 'OBJECT_NAME', 
       PROCESS.HOSTNAME , 
       PROCESS.program_name , 
       PROCESS.nt_domain , 
       PROCESS.nt_username , 
       PROCESS.program_name ,
       SQLTEXT.text 
FROM sys.syslockinfo LOCK JOIN 
     sys.sysprocesses PROCESS
  ON LOCK.req_spid = PROCESS.spid
CROSS APPLY sys.dm_exec_sql_text(PROCESS.SQL_HANDLE) SQLTEXT
where 1=1
and db_name(rsc_dbid) = db_name()



--Lock on a specific object
SELECT * 
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID()
AND resource_associated_entity_id = object_id('IMITEM');

*/