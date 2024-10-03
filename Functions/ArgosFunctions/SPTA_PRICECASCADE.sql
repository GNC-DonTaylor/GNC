--USE [ABECAS_GNC_TEST]
--GO

--/****** Object:  StoredProcedure [dbo].[SPTA_PRICECASCADE]    Script Date: 6/23/2021 7:56:16 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

CREATE OR ALTER   PROC [dbo].[SPTA_PRICECASCADE]
(	@SOURCE char(10)
) 
AS
/*This procedure is used by the Task Agent
There are Data Event Triggers set up for each of these sources that will stage the updates in the ABAGENTQUEUE
Each Source will also have a Task Agent Time Event that will be scheduled to call this procedure and process these updates
Rules #6 and #14 have been removed from the origninal rule list and are not necessary here
JoAnne Brown 2021/04/26 - Need to recalculate OMFREIGHT.AMOUNT and OMFREIGHT.WEIGHT when both or weight only changes
 [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row) returns the greater of minimum freight or actual extended line item freight on the order,
 [dbo].[FN_OMGETWEIGHT](@HDR_Row) returns total extended weight for line items on the order
Per Donny Johnson, only Zone Line item freight is considered for freight minimums
*/
BEGIN
	DECLARE @AgentRow uniqueidentifier 
	DECLARE @HDR_Row as uniqueidentifier
--********************************************************************************************************************************************************************
--Price Cascade Rules #2, #4 & #5 Position in Case statement N or S only -PRICESCHEDULEDETAIL DISCOUNTPRICE, HANDLING, OTHER  
--********************************************************************************************************************************************************************
IF (@SOURCE = 'PSD') 
			
	BEGIN 
		--CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
		BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate()
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Price Schedule Detail Cascade' and q.TASKSTATUS = 'PENDING'
        END
      --UPDATE ALL AFFECTED TRANSACTIONS IN THIS SET 
     UPDATE td
		SET td.UNITPRICE = case when td.unitpricechange in ('N', 'S') then isnull(round(psd.DISCOUNTPRICE,2),0) else isnull(round(td.UNITPRICE,2),0) end,                                   --#2  Position 1   Y = override in place
		    td.HANDLINGCHARGEPERITEM = case when handlingchargeperitemchange in ('N', 'S') then  isnull(round(psd.HANDLINGCHARGE,2),0) else isnull(round(td.handlingchargeperitem,2),0) end ,        --#4  Position 3   Y = override in place
		    td.TAGGINGCHARGEPERITEM = case when TAGGINGCHARGEPERITEMCHANGE in ('N', 'S') then isnull(round(psd.OTHERCHARGE,2),0) else isnull(round(td.TAGGINGCHARGEPERITEM,2),0) end,              --#5  Position 4   Y = override in place
		    td.AMOUNT = round(((case when td.UNITPRICECHANGE in ('N', 'S') then isnull(round(psd.DISCOUNTPRICE,2),0) else isnull(round(td.UNITPRICE,2),0) end  + 
		                        case when td.HANDLINGCHARGEPERITEMCHANGE in ('N', 'S') then isnull(round(psd.HANDLINGCHARGE,2),0) else isnull(round(td.handlingchargeperitem,2),0) end  + 
					            isnull(td.FEESADDED,0) + 
		                        case when td.TAGGINGCHARGEPERITEMCHANGE in ('N', 'S') then isnull(round(psd.OTHERCHARGE,2),0) else isnull(round(td.TAGGINGCHARGEPERITEM,2),0) end) 
		                        *
					           (case when th.stage in ('A','S','C') then isnull(round(td.QUANTITYSHIPPED,2),0) else isnull(round(td.QUANTITYORDERED,2),0) end )) ,2),
			td.USERDEFINEDREFERENCE_10 = 'PSD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	   FROM ABAGENTQUEUE Q (nolock) join 
	        IMPRICESCHEDULEDETAIL psd (nolock) on psd.ROWID = q.SOURCEID join
			IMPRICESCHEDULEHEADER psh (nolock) on psh.rowid = psd.R_PRICESCHEDULEHEADER join
			OMTRANSACTIONDETAIL td on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE PS (nolock) on ps.R_CONSIGNEE = con.ROWID and ps.R_SHIPPER = th.R_FMSHIPPER	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Detail Cascade'
			 and cast(th.SHIPPINGDATE as date) >= cast(psh.EFFECTIVESTARTDATE as date) -- formatted to date without time
			 and ps.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 --and getdate() < psd.EXPIRATIONDATE                                                                                ---may need to discuss this, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'

/*
   select  td.UNITPRICE, 
           case when td.unitpricechange in ('N', 'S') then isnull(psd.DISCOUNTPRICE,0) else isnull(td.UNITPRICE,0) end,                                   --#2  Position 1   Y = override in place
		    td.HANDLINGCHARGEPERITEM, 
			case when handlingchargeperitemchange in ('N', 'S') then  isnull(psd.HANDLINGCHARGE,0) else isnull(td.handlingchargeperitem,0) end ,        --#4  Position 3   Y = override in place
		    td.TAGGINGCHARGEPERITEM , 
			case when TAGGINGCHARGEPERITEMCHANGE in ('N', 'S') then isnull(psd.OTHERCHARGE,0) else isnull(td.TAGGINGCHARGEPERITEM,0) end,              --#5  Position 4   Y = override in place
		    td.AMOUNT,round(((case when td.UNITPRICECHANGE in ('N', 'S') then isnull(psd.DISCOUNTPRICE,0) else isnull(td.UNITPRICE,0) end  + 
		                        case when td.HANDLINGCHARGEPERITEMCHANGE in ('N', 'S') then isnull(psd.HANDLINGCHARGE,0) else isnull(td.handlingchargeperitem,0) end  + 
					            isnull(td.FEESADDED,0) + 
		                        case when td.TAGGINGCHARGEPERITEMCHANGE in ('N', 'S') then isnull(psd.OTHERCHARGE,0) else isnull(td.TAGGINGCHARGEPERITEM,0) end) 
		                        *
					           (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )) ,2),
			td.USERDEFINEDREFERENCE_10
	   FROM ABAGENTQUEUE Q (nolock) join 
	        IMPRICESCHEDULEDETAIL psd (nolock) on psd.ROWID = q.SOURCEID join
			IMPRICESCHEDULEHEADER psh (nolock) on psh.rowid = psd.R_PRICESCHEDULEHEADER join
			OMTRANSACTIONDETAIL td on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE PS (nolock) on ps.R_CONSIGNEE = con.ROWID and ps.R_SHIPPER = th.R_FMSHIPPER	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Detail Cascade'
			 and cast(th.SHIPPINGDATE as date) >= cast(psh.EFFECTIVESTARTDATE as date) -- formatted to date without time
			 and ps.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 --and getdate() < psd.EXPIRATIONDATE                                                                                ---may need to discuss this, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'
*/


  ----------------update OMFREIGHT--------------------------------------- 

	DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	   FROM ABAGENTQUEUE Q (nolock) join 
	        IMPRICESCHEDULEDETAIL psd (nolock) on psd.ROWID = q.SOURCEID join
			IMPRICESCHEDULEHEADER psh (nolock) on psh.rowid = psd.R_PRICESCHEDULEHEADER join
			OMTRANSACTIONDETAIL td (nolock) on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE PS (nolock) on ps.R_CONSIGNEE = con.ROWID and ps.R_SHIPPER = th.R_FMSHIPPER	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Detail Cascade'
			 and cast(th.SHIPPINGDATE as date) >= cast(psh.EFFECTIVESTARTDATE as date) -- formatted to date without time
			 and ps.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 --and getdate() < psd.EXPIRATIONDATE                                                                                ---may need to discuss this, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN 
	
	 update omfreight 
	 SET --omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row) ,
		 omfreight.comment = 'PSD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor
     
	 --UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Price Schedule Detail Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	   END

--********************************************************************************************************************************************************************
--Price Cascade Rule #1 TD.FREIGHTRATEPERITEMCHANGE S or N - PRICESCHEDULEHeader.R_ZONE change calls SP for details and other freight updates  
--********************************************************************************************************************************************************************
ELSE IF (@SOURCE = 'PSHFZ') 

	BEGIN
	--CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
          BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate(),
				  @AgentRow = q.SOURCEID               --for freight update later
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Price Schedule Header FZ Cascade' and q.TASKSTATUS = 'PENDING'
		  END
	--IMFREIGHTRATETABECLASSRATE.RATE --> OMTRANSACTIONDETAIL.FREIGHTRATEPERITEM and check for minimum freight change
	
	--UPDATE ALL AFFECTED TRANSACTIONS IN THIS SET 
	--TBD
	  UPDATE td
		SET                                                                                              
			td.FREIGHTRATEPERITEM = isnull(psd.FREIGHTCHARGE,0),
			td.EFFECTIVEFREIGHT =  round(isnull(psd.freightcharge,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 = 'PSHFZ Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 FROM ABAGENTQUEUE Q (nolock)join 
			IMPRICESCHEDULEHEADER psh (nolock) on psh.ROWID = q.SOURCEID join
			IMPRICESCHEDULEDETAIL psd (nolock) on psh.rowid = psd.R_PRICESCHEDULEHEADER join
			OMTRANSACTIONDETAIL td   on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = con.ROWID and psh.R_SHIPPER = th.R_FMSHIPPER	join
            IMFREIGHTRATETABLEZONE fz (nolock) on fz.rowid = csz.r_zone join
			IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid join
			IMFREIGHTRATETABLE ft ON fd.R_FREIGHTRATETABLE = ft.ROWID  
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Header FZ Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and td.FREIGHTRATEPERITEMCHANGE in  ('N', 'S')                                                                  
			 and ft.r_shipper = csz.r_shipper
			 and csz.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >= cast(psh.EFFECTIVESTARTDATE as date)  
			-- and getdate() < psd.EXPIRATIONDATE                                                                              ----may need to discuss, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'

	/*
	select                                                                                              
			td.FREIGHTRATEPERITEM , isnull(psd.FREIGHTCHARGE,0),
			td.EFFECTIVEFREIGHT, round(isnull(psd.freightcharge,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 , 'Price Schedule Header FZ Cascade'
	 FROM ABAGENTQUEUE Q (nolock)join 
			IMPRICESCHEDULEHEADER psh (nolock) on psh.ROWID = q.SOURCEID join
			IMPRICESCHEDULEDETAIL psd (nolock) on psh.rowid = psd.R_PRICESCHEDULEHEADER join
			OMTRANSACTIONDETAIL td   on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = con.ROWID and psh.R_SHIPPER = th.R_FMSHIPPER	join
            IMFREIGHTRATETABLEZONE fz (nolock) on fz.rowid = csz.r_zone join
			IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid join
			IMFREIGHTRATETABLE ft ON fd.R_FREIGHTRATETABLE = ft.ROWID  
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Header FZ Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and td.FREIGHTRATEPERITEMCHANGE in  ('N', 'S')                                                                  
			 and ft.r_shipper = csz.r_shipper
			 and csz.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >= cast(psh.EFFECTIVESTARTDATE as date)  
			-- and getdate() < psd.EXPIRATIONDATE                                                                              ----may need to discuss, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'
	*/

	-----Update OMFREIGHT

	DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	   from ABAGENTQUEUE Q (nolock)join 
			IMPRICESCHEDULEHEADER psh (nolock) on psh.ROWID = q.SOURCEID join
			IMPRICESCHEDULEDETAIL psd (nolock) on psh.rowid = psd.R_PRICESCHEDULEHEADER join
			OMTRANSACTIONDETAIL td (nolock)   on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = con.ROWID and psh.R_SHIPPER = th.R_FMSHIPPER	join
            IMFREIGHTRATETABLEZONE fz (nolock) on fz.rowid = csz.r_zone join
			IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid join
			IMFREIGHTRATETABLE ft ON fd.R_FREIGHTRATETABLE = ft.ROWID  
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Header FZ Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and td.FREIGHTRATEPERITEMCHANGE in  ('N', 'S')                                                                  
			 and ft.r_shipper = csz.r_shipper
			 and csz.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >= cast(psh.EFFECTIVESTARTDATE as date)  
			-- and getdate() < psd.EXPIRATIONDATE                                                                              ----may need to discuss, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
      
	 update omfreight 
	 SET omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'PSHFZ Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor


	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Price Schedule Header FZ Cascade' 
	    and TASKSTATUS = 'PROCESSING' 
	END
--********************************************************************************************************************************************************************
--Price Cascade Rule #13 TD.FREIGHTRATEPERITEMCHANGE N only- PRICESCHEDULEHeader.R_ZONE - TA updates header?? then calls SP for details and other freight updates  
--********************************************************************************************************************************************************************
ELSE IF (@SOURCE = 'FCLR') --FREIGHTCLASSRATE  from freight zone table  - limited use only due to long processing                                                                                                                              

	BEGIN
	--CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING]
	     BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate(),
				  @AgentRow = q.SOURCEID               --for freight update later
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Feight Class Rate Cascade' and q.TASKSTATUS = 'PENDING'
	    END
	--IMFREIGHTRATETABECLASSRATE.RATE --> OMTRANSACTIONDETAIL.FREIGHTRATEPERITEM

	 UPDATE td
		SET                                                                                              
			td.FREIGHTRATEPERITEM = isnull(ftcr.RATE,0),
			td.EFFECTIVEFREIGHT =  round(isnull(ftcr.RATE,0) *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 = 'FCLR Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 FROM ABAGENTQUEUE Q (nolock) join 
			IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on ftcr.rowid = q.SOURCEID join  -- table detail  row is changed
			IMFREIGHTRATETABLEZONE fz (nolock) on fz.rowid = ftcr.R_FREIGHTRATETABLEZONE join --find the header row
			IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid  join  -- find the date row
			IMFREIGHTRATETABLE ft (nolock) ON fd.R_FREIGHTRATETABLE = ft.ROWID  JOIN
			RTZONETABLECODES ztc (nolock) on fz.R_ZONE = ztc.ROWID join                      -- connect to shipper and zone table
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_ZONE = ztc.ROWID join                 --find shipper for zone
			OMTRANSACTIONHEADER th (nolock) on th.R_FMSHIPPER = csz.R_SHIPPER join             --connect order hdr to consignee shipper zone 
			OMTRANSACTIONDETAIL td  on td.R_TRANSACTIONHEADER = th.ROWID join          -- conect to td
			IDMASTER cons (nolock) on cons.ROWID = th.R_SHIPPER join                          -- only th shipper records
			IMITEM i (nolock) on i.ROWID = td.R_ITEM join                                   -- connect to item to get container class
			IMCONTAINER cont (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE       --only matched item containers for class	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Feight Class Rate Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and ft.r_shipper = csz.r_shipper
		     and cont.freightclasscode = ftcr.freightclasscode
			 and td.FREIGHTRATEPERITEMCHANGE = 'N'                                                                                        
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE)as date) = cast(fd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >= cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'

/*
select                                                                                              
			td.FREIGHTRATEPERITEM , isnull(ftcr.RATE,0),
			td.EFFECTIVEFREIGHT , round(isnull(ftcr.RATE,0) *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 , 'Feight Class Rate Cascade'
	 FROM ABAGENTQUEUE Q (nolock) join 
			IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on ftcr.rowid = q.SOURCEID join  -- table detail  row is changed
			IMFREIGHTRATETABLEZONE fz (nolock) on fz.rowid = ftcr.R_FREIGHTRATETABLEZONE join --find the header row
			IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid  join  -- find the date row
			IMFREIGHTRATETABLE ft (nolock) ON fd.R_FREIGHTRATETABLE = ft.ROWID  JOIN
			RTZONETABLECODES ztc (nolock) on fz.R_ZONE = ztc.ROWID join                      -- connect to shipper and zone table
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_ZONE = ztc.ROWID join                 --find shipper for zone
			OMTRANSACTIONHEADER th (nolock) on th.R_FMSHIPPER = csz.R_SHIPPER join             --connect order hdr to consignee shipper zone 
			OMTRANSACTIONDETAIL td  on td.R_TRANSACTIONHEADER = th.ROWID join          -- conect to td
			IDMASTER cons (nolock) on cons.ROWID = th.R_SHIPPER join                          -- only th shipper records
			IMITEM i (nolock) on i.ROWID = td.R_ITEM join                                   -- connect to item to get container class
			IMCONTAINER cont (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE       --only matched item containers for class	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Feight Class Rate Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and ft.r_shipper = csz.r_shipper
		     and cont.freightclasscode = ftcr.freightclasscode
			 and td.FREIGHTRATEPERITEMCHANGE = 'N'                                                                                        
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE)as date) = cast(fd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >= cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
*/
----------------------------------------------UPDATE OMFREIGHT--------------------------------
DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	    FROM ABAGENTQUEUE Q (nolock) join 
			IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on ftcr.rowid = q.SOURCEID join  -- table detail  row is changed
			IMFREIGHTRATETABLEZONE fz (nolock) on fz.rowid = ftcr.R_FREIGHTRATETABLEZONE join --find the header row
			IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid  join  -- find the date row
			IMFREIGHTRATETABLE ft (nolock) ON fd.R_FREIGHTRATETABLE = ft.ROWID  JOIN
			RTZONETABLECODES ztc (nolock) on fz.R_ZONE = ztc.ROWID join                      -- connect to shipper and zone table
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_ZONE = ztc.ROWID join                 --find shipper for zone
			OMTRANSACTIONHEADER th (nolock) on th.R_FMSHIPPER = csz.R_SHIPPER join             --connect order hdr to consignee shipper zone 
			OMTRANSACTIONDETAIL td (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join          -- conect to td
			IDMASTER cons (nolock) on cons.ROWID = th.R_SHIPPER join                          -- only th shipper records
			IMITEM i (nolock) on i.ROWID = td.R_ITEM join                                   -- connect to item to get container class
			IMCONTAINER cont (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE       --only matched item containers for class	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Feight Class Rate Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and ft.r_shipper = csz.r_shipper
		     and cont.freightclasscode = ftcr.freightclasscode
			 and td.FREIGHTRATEPERITEMCHANGE = 'N'                                                                                        
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE)as date) = cast(fd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >= cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
  
	 update omfreight 
	 SET omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'FCLR Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor

	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Feight Class Rate Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	END
--********************************************************************************************************************************************************************
--Price Cascade Rule #10 TD.UNITPRICECHANGE 1 N and S only-IMPRICECODESSUBDETAIL.PRICELEVEL_A --> OMTRANSACTIONDETAIL.UNITPRICE then calls SP for details and other freight updates 
--********************************************************************************************************************************************************************	
ELSE IF (@SOURCE = 'PCSD')                                                      --#10 

	BEGIN

	--CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	    BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate()
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Price Code Sub Detail Cascade' and q.TASKSTATUS = 'PENDING'
        END
	--xxxx
	--TBD - need new field and validate discount percent should be from the  line, not the header
	UPDATE td
		SET 
		/*td.UNITPRICE = round(isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0),2),                                                                                                  
		    td.AMOUNT = round(((isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			*/
			
		   td.UNITPRICE = round(isnull(pcsd.PRICELEVEL_A,0) - isnull((pcsd.PRICELEVEL_A * (td.DISCOUNTPERCENT / 100)),0),2),  
		   td.amount =  (( round(isnull(pcsd.pricelevel_a,0) -isnull((pcsd.PRICELEVEL_A * (td.DISCOUNTPERCENT / 100)),0),2)
		   + isnull(td.TAGGINGCHARGEPERITEM,0) 
		   + isnull(td.FEESADDED,0) 
		   + isnull(td.HANDLINGCHARGEPERITEM,0)) 
		   *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )) ,	
			td.USERDEFINEDREFERENCE_10 = 'PCSD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	   FROM ABAGENTQUEUE Q (nolock) join 
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcsd.ROWID = q.SOURCEID join   
			IMPRICECODESDETAIL pcd (nolock) on pcsd.R_PRICECODEDETAIL = pcd.rowid join 
			IMPRICECODESHEADER pch (nolock) on pch.rowid = pcd.R_PRICECODEHEADER join  
			IMITEM i (nolock) on i.R_PRICETABLE = pch.rowid join                      
			OMTRANSACTIONDETAIL td   on td.R_ITEM = i.rowid join               
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Code Sub Detail Cascade'                    
			 and td.UNITPRICECHANGE in  ('N', 'S')                                                                                         
			 and csz.R_PRICESCHEDULE is null                                    
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and th.SHIPPINGDATE >= pcd.EFFECTIVEDATE         

	/*
	select                                                                                              
			td.UNITPRICE , round(isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0),2),                                                                                                  
		    td.AMOUNT, round(((isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			td.USERDEFINEDREFERENCE_10 , 'Price Code Sub Detail Cascade'
	   FROM ABAGENTQUEUE Q (nolock) join 
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcsd.ROWID = q.SOURCEID join   
			IMPRICECODESDETAIL pcd (nolock) on pcsd.R_PRICECODEDETAIL = pcd.rowid join 
			IMPRICECODESHEADER pch (nolock) on pch.rowid = pcd.R_PRICECODEHEADER join  
			IMITEM i (nolock) on i.R_PRICETABLE = pch.rowid join                      
			OMTRANSACTIONDETAIL td   on td.R_ITEM = i.rowid join               
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Code Sub Detail Cascade'                    
			 and td.UNITPRICECHANGE in  ('N', 'S')                                                                                         
			 and csz.R_PRICESCHEDULE is null                                    
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and th.SHIPPINGDATE >= pcd.EFFECTIVEDATE  
	*/

  DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	     FROM ABAGENTQUEUE Q (nolock) join 
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcsd.ROWID = q.SOURCEID join   
			IMPRICECODESDETAIL pcd (nolock) on pcsd.R_PRICECODEDETAIL = pcd.rowid join 
			IMPRICECODESHEADER pch (nolock) on pch.rowid = pcd.R_PRICECODEHEADER join  
			IMITEM i (nolock) on i.R_PRICETABLE = pch.rowid join                      
			OMTRANSACTIONDETAIL td (nolock)  on td.R_ITEM = i.rowid join               
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Code Sub Detail Cascade'                    
			 and td.UNITPRICECHANGE in  ('N', 'S')                                                                                         
			 and csz.R_PRICESCHEDULE is null                                    
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and th.SHIPPINGDATE >= pcd.EFFECTIVEDATE         
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
 
	 update omfreight 
	 SET --omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'PCSD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor

	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Price Code Sub Detail Cascade' 
	    and TASKSTATUS = 'PROCESSING' 


	END
--********************************************************************************************************************************************************************
--Price Cascade Rule 11 and 12 -CONSIGNEE PRICE SCHEDULE Changed (Add, Update or Removed)  Most likely this will be manually done.
--Discussed with Steve. This will not work for Removing. Too many decisions need made to be automatic. Considering issues with Adding. May be manual as well.
--********************************************************************************************************************************************************************
ELSE IF (@SOURCE = 'CONSPS') --                         --#11 add and #12 remove                                                                  --#11    & #12

	BEGIN

	--CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	   BEGIN
		  UPDATE q
		  SET q.TASKSTATUS = 'PROCESSING',
			  q.STARTTIME = getdate()
		 FROM ABAGENTQUEUE q
		WHERE q.AGENTNAME = 'Consignee Price Schedule Update Cascade' and q.TASKSTATUS = 'PENDING'
	  END
	--if no schedule or override freight zone on order IDCONSIGNEE.R_ZONE

	--TBD

	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Consignee Price Schedule Update Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	END
--********************************************************************************************************************************************************************
--Price Cascade Rule #9 TD.UNTIPRICECHANGE N Only -CUSTOMER PURCHASE DISCOUNT Changed (Add, Update or Removed) then calls SP for details and other freight updates
--********************************************************************************************************************************************************************
ELSE IF (@SOURCE = 'CUSTPD')  --                                                                                                      #9

	BEGIN
	    BEGIN
	         --CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	       UPDATE q
	       SET q.TASKSTATUS = 'PROCESSING',
	           q.STARTTIME = getdate()
          FROM ABAGENTQUEUE q
          WHERE q.AGENTNAME = 'Customer Purchase Discount Cascade' and q.TASKSTATUS = 'PENDING'
    	END
	--Header Discount Percent (if no price schedule and IDCUSTOMER.CUSTOMERPURCHASEDISCOUNT does not match OMTRANSACTIONHEADER.DEFAULTDETAILDISCOUNT)        

	
	 ----xxxx---------------------------------------------------------------------------------------- update detail then header 
	UPDATE td
	       set --th.DEFAULTDETAILDISCOUNT = c.CUSTOMERPURCHASEDISCOUNT,
            td.UNITPRICE = round(isnull(pcsd.PRICELEVEL_A,0) - isnull((pcsd.PRICELEVEL_A * (c.CUSTOMERPURCHASEDISCOUNT / 100)),0),2),  
		  --  td.AMOUNT = round(((isnull((isnull(pcsd.PRICELEVEL_A,0) - isnull(pcsd.PRICELEVEL_A,0) - (c.CUSTOMERPURCHASEDISCOUNT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			--td.amount =   round((( isnull(pcsd.pricelevel_a,0) - isnull((pcsd.PRICELEVEL_A * (c.CUSTOMERPURCHASEDISCOUNT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			td.amount =  (( round(isnull(pcsd.pricelevel_a,0) -isnull((pcsd.PRICELEVEL_A * (c.CUSTOMERPURCHASEDISCOUNT / 100)),0),2)
		   + isnull(td.TAGGINGCHARGEPERITEM,0) 
		   + isnull(td.FEESADDED,0) 
		   + isnull(td.HANDLINGCHARGEPERITEM,0)) 
		   *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )) ,
			td.USERDEFINEDREFERENCE_10 = 'CUSTPD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	   FROM ABAGENTQUEUE Q (nolock)join 
	        IDCUSTOMER c (nolock) on c.rowid = q.sourceid join
			IDMASTER cust (nolock) on c.R_IDENTITY = cust.rowid join
	        OMTRANSACTIONHEADER th  (nolock) on th.r_customer =  cust.rowid join 
			OMTRANSACTIONDETAIL td   on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Customer Purchase Discount Cascade'
			 and td.UNITPRICECHANGE  = 'N'                                                                                           
			 and csz.R_PRICESCHEDULE is null  
			 and c.CUSTOMERPURCHASEDISCOUNT <> th.DEFAULTDETAILDISCOUNT 
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >=cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 

	UPDATE th 
	  set th.DEFAULTDETAILDISCOUNT = c.CUSTOMERPURCHASEDISCOUNT,
	      th.USERDEFINEDREFERENCE_20 = 'CUSTPD: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss') ---------------------------20 not 10 on header
		 FROM ABAGENTQUEUE Q (nolock)join 
	        IDCUSTOMER c (nolock) on c.rowid = q.sourceid join
			IDMASTER cust (nolock) on c.R_IDENTITY = cust.rowid join
	        OMTRANSACTIONHEADER th (nolock) on th.r_customer =  cust.rowid join 
			OMTRANSACTIONDETAIL td  (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Customer Purchase Discount Cascade'
			 and td.UNITPRICECHANGE  = 'N'                                                                                          
			 and csz.R_PRICESCHEDULE is null  
			 and c.CUSTOMERPURCHASEDISCOUNT <> th.DEFAULTDETAILDISCOUNT 
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >=cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 

	/*
		select
		    td.UNITPRICE , round(isnull((pcsd.PRICELEVEL_A - (c.CUSTOMERPURCHASEDISCOUNT / 100)),0),2),                                                                                                 
		    td.AMOUNT , round(((isnull((pcsd.PRICELEVEL_A - (c.CUSTOMERPURCHASEDISCOUNT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			td.USERDEFINEDREFERENCE_10 , 'Customer Purchase Discount Cascade'
	   FROM ABAGENTQUEUE Q (nolock)join 
	        IDCUSTOMER c (nolock) on c.rowid = q.sourceid join
			IDMASTER cust (nolock) on c.R_IDENTITY = cust.rowid join
	        OMTRANSACTIONHEADER th  (nolock) on th.r_customer =  cust.rowid join 
			OMTRANSACTIONDETAIL td   on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Customer Purchase Discount Cascade'
			 and td.UNITPRICECHANGE  = 'N'                                                                                           
			 and csz.R_PRICESCHEDULE is null  
			 and c.CUSTOMERPURCHASEDISCOUNT <> th.DEFAULTDETAILDISCOUNT 
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >=cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 

	select th.DEFAULTDETAILDISCOUNT , c.CUSTOMERPURCHASEDISCOUNT,
	      th.USERDEFINEDREFERENCE_10 , 'Customer Purchase Discount Cascade'
		 FROM ABAGENTQUEUE Q (nolock)join 
	        IDCUSTOMER c (nolock) on c.rowid = q.sourceid join
			IDMASTER cust (nolock) on c.R_IDENTITY = cust.rowid join
	        OMTRANSACTIONHEADER th (nolock) on th.r_customer =  cust.rowid join 
			OMTRANSACTIONDETAIL td  (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Customer Purchase Discount Cascade'
			 and td.UNITPRICECHANGE  = 'N'                                                                                          
			 and csz.R_PRICESCHEDULE is null  
			 and c.CUSTOMERPURCHASEDISCOUNT <> th.DEFAULTDETAILDISCOUNT 
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >=cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 
	*/

---------------------------------------Update OMFREIGHT-----------------------------------------------
 DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	    FROM ABAGENTQUEUE Q (nolock)join 
	        IDCUSTOMER c (nolock) on c.rowid = q.sourceid join
			IDMASTER cust (nolock) on c.R_IDENTITY = cust.rowid join
	        OMTRANSACTIONHEADER th  (nolock) on th.r_customer =  cust.rowid join 
			OMTRANSACTIONDETAIL td (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Customer Purchase Discount Cascade'
			 and td.UNITPRICECHANGE  = 'N'                                                                                           
			 and csz.R_PRICESCHEDULE is null  
			 and c.CUSTOMERPURCHASEDISCOUNT <> th.DEFAULTDETAILDISCOUNT 
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and cast(th.SHIPPINGDATE as date) >=cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'    
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN   
	
	 update omfreight 
	 SET --omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row) ,
		 omfreight.comment = 'CUSTPD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor

	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Customer Purchase Discount Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	END
--********************************************************************************************************************************************************************
--Price Cascade Rule #16 TD.UNITPRICECHANGE N Only -OMTRANSACTIONHEADER DISCOUNT PERCENT Changed (Add, Update or Removed) then calls SP for details and other freight updates
--********************************************************************************************************************************************************************
ELSE IF (@SOURCE = 'OMTHDP') 

	BEGIN
	 
	 --CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	     BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate()
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Transaction Header Discount Cascade' and q.TASKSTATUS = 'PENDING'
        END
	 --OMTRANSACTIONHEADER.DEFAULTDETAILDISCOUNT --> recalculate OMTRANSACTIONDETAIL

	UPDATE td
		SET /*td.UNITPRICE = round(isnull((pcsd.PRICELEVEL_A - (th.DEFAULTDETAILDISCOUNT / 100)),0),2),                                                                                                 
		    td.AMOUNT = round(((isnull((pcsd.PRICELEVEL_A - (th.DEFAULTDETAILDISCOUNT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			*/
			
		   td.UNITPRICE = round(isnull(pcsd.PRICELEVEL_A,0) - isnull((pcsd.PRICELEVEL_A * (th.DEFAULTDETAILDISCOUNT / 100)),0),2),  
		   td.amount =  (( round(isnull(pcsd.pricelevel_a,0) -isnull((pcsd.PRICELEVEL_A * (th.DEFAULTDETAILDISCOUNT / 100)),0),2)
		   + isnull(td.TAGGINGCHARGEPERITEM,0) 
		   + isnull(td.FEESADDED,0) 
		   + isnull(td.HANDLINGCHARGEPERITEM,0)) 
		   *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )) ,
			td.USERDEFINEDREFERENCE_10 = 'OMTHDP Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	   FROM ABAGENTQUEUE Q (nolock) join 
	        OMTRANSACTIONHEADER th  (nolock) on th.ROWID = q.SOURCEID join 
			OMTRANSACTIONDETAIL td   on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER  
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Discount Cascade'
			 and td.UNITPRICECHANGE ='N'                                                                                    
			 and csz.R_PRICESCHEDULE is null  
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast( pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 


	/*
		select
		   td.UNITPRICE, round(isnull((pcsd.PRICELEVEL_A - (th.DEFAULTDETAILDISCOUNT / 100)),0),2),                                                                                                 
		    td.AMOUNT , round(((isnull((pcsd.PRICELEVEL_A - (th.DEFAULTDETAILDISCOUNT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			td.USERDEFINEDREFERENCE_10 , 'Transaction Header Discount Cascade'
	   FROM ABAGENTQUEUE Q (nolock) join 
	        OMTRANSACTIONHEADER th  (nolock) on th.ROWID = q.SOURCEID join 
			OMTRANSACTIONDETAIL td   on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER  
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Discount Cascade'
			 and td.UNITPRICECHANGE ='N'                                                                                    
			 and csz.R_PRICESCHEDULE is null  
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast( pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 
	*/
---------------------------------------Update OMFREIGHT-----------------------------------------------
	 DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	   FROM ABAGENTQUEUE Q (nolock) join 
	        OMTRANSACTIONHEADER th  (nolock) on th.ROWID = q.SOURCEID join 
			OMTRANSACTIONDETAIL td  (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER  
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Discount Cascade'
			 and td.UNITPRICECHANGE ='N'                                                                                    
			 and csz.R_PRICESCHEDULE is null  
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast( pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING' 
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
      
	
	 update omfreight 
	 SET --omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'OMTHDP Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor

	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Transaction Header Discount Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	

	   END
--********************************************************************************************************************************************************************
--Price Cascade Rule #15 TD.UNITPRICECHANGE = N Only -OMTRANSACTIONHEADER.REQUESTDATE Changed (Add, Update or Removed) then calls SP for details and other freight updates
--Talked with Steve. Differences for major accounts in question. Independents if moved into new date on price table and crossing 8/1 only? 
--If using dates, compare old and new values of dates on TA side first to see if it needs to run at all.  
--********************************************************************************************************************************************************************
ELSE IF (@SOURCE = 'OMTHRD')      

	BEGIN
	 
	 --CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	     BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate(),
				  @AgentRow = q.SOURCEID               --for freight minimum update later
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Transaction Header Request Date Cascade' and q.TASKSTATUS = 'PENDING'
        END
	 --OMTRANSACTIONHEADER.SHIPPINGDATE --> recalculate OMTRANSACTIONDETAIL   
	  -----------------------------------------------------------------------------------------------------------------Need to add freight update on td here!!! Ask Dave
	--TBD   xxxx
	UPDATE td
		SET /*td.UNITPRICE = round(isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0),2),                                                                                                
		    td.AMOUNT = round(((isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
	       */
		   td.UNITPRICE = round(isnull(pcsd.PRICELEVEL_A,0) - isnull((pcsd.PRICELEVEL_A * (td.DISCOUNTPERCENT / 100)),0),2),  
		   td.amount =  (( round(isnull(pcsd.pricelevel_a,0) -isnull((pcsd.PRICELEVEL_A * (td.DISCOUNTPERCENT / 100)),0),2)
		   + isnull(td.TAGGINGCHARGEPERITEM,0) 
		   + isnull(td.FEESADDED,0) 
		   + isnull(td.HANDLINGCHARGEPERITEM,0)) 
		   *(case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )) ,	
           td.USERDEFINEDREFERENCE_10 = 'OMTHRD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	   FROM ABAGENTQUEUE Q (nolock) join 
	        OMTRANSACTIONHEADER th  (nolock) on th.ROWID = q.SOURCEID join 
			OMTRANSACTIONDETAIL td   on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Request Date Cascade'
			 and td.UNITPRICECHANGE = 'N'                                                                                         
			 and csz.R_PRICESCHEDULE is null   
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
/*
	select
		    td.UNITPRICE , round(isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0),2),                                                                                                
		    td.AMOUNT , round(((isnull((pcsd.PRICELEVEL_A - (td.DISCOUNTPERCENT / 100)),0) + isnull(td.TAGGINGCHARGEPERITEM,0) + isnull(td.FEESADDED,0) + isnull(td.HANDLINGCHARGEPERITEM,0)) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end )),2),
			td.USERDEFINEDREFERENCE_10 , 'Transaction Header Request Date Cascade'
	   FROM ABAGENTQUEUE Q (nolock) join 
	        OMTRANSACTIONHEADER th  (nolock) on th.ROWID = q.SOURCEID join 
			OMTRANSACTIONDETAIL td   on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Request Date Cascade'
			 and td.UNITPRICECHANGE = 'N'                                                                                         
			 and csz.R_PRICESCHEDULE is null   
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
*/

	-- UPDATE OMFREIGHT 
	 DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	   FROM ABAGENTQUEUE Q (nolock) join 
	        OMTRANSACTIONHEADER th  (nolock) on th.ROWID = q.SOURCEID join 
			OMTRANSACTIONDETAIL td  (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join
			IMITEM i (nolock) on i.rowid = td.R_ITEM join
	        IMPRICECODESHEADER pch (nolock) on pch.ROWID = i.R_PRICETABLE join
			IMPRICECODESDETAIL pcd (nolock) on pch.ROWID = pcd.R_PRICECODEHEADER join
			IMPRICECODESSUBDETAIL pcsd (nolock) on pcd.ROWID = pcsd.R_PRICECODEDETAIL 	join  
		    IDMASTER cons (nolock) on cons.rowid = th.R_SHIPPER left join             
			IDCONSIGNEESHIPPERZONE csz (nolock) on csz.R_CONSIGNEE = cons.ROWID and csz.R_SHIPPER = th.R_FMSHIPPER 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Request Date Cascade'
			 and td.UNITPRICECHANGE = 'N'                                                                                         
			 and csz.R_PRICESCHEDULE is null   
			 and cast([dbo].[FN_GETEFFECTIVEDATEPCD](th.SHIPPINGDATE) as date) = cast(pcd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
	
	 update omfreight 
	 SET omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'OMTHRD Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor
-------------------------------------------------------------------------------------------------------------------------------------------MIN FREIGHT NEEDED HERE
	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Transaction Header Request Date Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	   END
--********************************************************************************************************************************************************************
--Price Cascade Rule #3 FREIGHTRATEPERITEMCHANGE S or N  -PRICESCHEDULEDETAIL FREIGHT RATE Changed (Add, Update or Removed) then calls SP for details and other freight updates
--********************************************************************************************************************************************************************	
ELSE IF (@SOURCE = 'PSDFR')                                                                            

	BEGIN

	 --CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	     BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate(),
				  @AgentRow = q.SOURCEID               --for freight update later
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Price Schedule Detail Freight Cascade' and q.TASKSTATUS = 'PENDING'
		END

	  UPDATE td
		SET td.freightrateperitem = isnull(psd.freightcharge,  0) ,                                                                 -- #3 
		    td.EFFECTIVEFREIGHT =  round(isnull(psd.freightcharge,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 = 'PSDFR Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	   FROM ABAGENTQUEUE Q (nolock) join 
			IMPRICESCHEDULEDETAIL psd (nolock) on psd.ROWID = q.SOURCEID join
			OMTRANSACTIONDETAIL td   on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE PS (nolock) on ps.R_CONSIGNEE = con.ROWID and ps.R_SHIPPER = th.R_FMSHIPPER	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Detail Freight Cascade'
			 and td.FREIGHTRATEPERITEMCHANGE in  ('N', 'S')                                                                                          --new field 
			 and ps.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 ---and getdate() < psd.EXPIRATIONDATE                                                                                    ---need to discuss, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'

	/*
		select
		    td.freightrateperitem , isnull(psd.freightcharge,  0) ,                                                                 -- #3 
		    td.EFFECTIVEFREIGHT,  round(isnull(psd.freightcharge,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10, 'Price Schedule Detail Freight Cascade'
	   FROM ABAGENTQUEUE Q (nolock) join 
			IMPRICESCHEDULEDETAIL psd (nolock) on psd.ROWID = q.SOURCEID join
			OMTRANSACTIONDETAIL td   on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE PS (nolock) on ps.R_CONSIGNEE = con.ROWID and ps.R_SHIPPER = th.R_FMSHIPPER	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Detail Freight Cascade'
			 and td.FREIGHTRATEPERITEMCHANGE in  ('N', 'S')                                                                                          --new field 
			 and ps.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 ---and getdate() < psd.EXPIRATIONDATE                                                                                    ---need to discuss, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'
	*/

	-- UPDATE OMFREIGHT 
	 DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	    FROM ABAGENTQUEUE Q (nolock) join 
			IMPRICESCHEDULEDETAIL psd (nolock) on psd.ROWID = q.SOURCEID join
			OMTRANSACTIONDETAIL td (nolock)  on td.R_ITEM = psd.R_ITEM join
	        OMTRANSACTIONHEADER th (nolock) on th.ROWID = td.R_TRANSACTIONHEADER  join
			IDMASTER con (nolock) on con.ROWID = th.R_SHIPPER join
			IDCONSIGNEESHIPPERZONE PS (nolock) on ps.R_CONSIGNEE = con.ROWID and ps.R_SHIPPER = th.R_FMSHIPPER	
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Price Schedule Detail Freight Cascade'
			 and td.FREIGHTRATEPERITEMCHANGE in  ('N', 'S')                                                                                          --new field 
			 and ps.R_PRICESCHEDULE = psd.R_PRICESCHEDULEHEADER
			 ---and getdate() < psd.EXPIRATIONDATE                                                                                    ---need to discuss, not needed per meeting
			 and q.TASKSTATUS = 'PROCESSING'
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
      
	
	 update omfreight 
	 SET omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'PSDFR Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor


	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Price Schedule Detail Freight Cascade' 
	    and TASKSTATUS = 'PROCESSING' 
	END
--********************************************************************************************************************************************************************
--Price Cascade Rule #7 TD.FREIGHTRATEPERITEMCHANGE = N Only -IDCONSIGNEE  FREIGHT ZONE Changed (Add, Update or Removed) then calls SP for details and other freight updates
--********************************************************************************************************************************************************************	
ELSE IF (@SOURCE = 'CONFZ')                                                                                

	BEGIN

	 --CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	   BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate(),
				  @AgentRow = q.SOURCEID               --for freight update later
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Consignee Freight Zone Cascade' and q.TASKSTATUS = 'PENDING'
		END
	UPDATE td
	SET                                                                                              
			td.FREIGHTRATEPERITEM = isnull(ftcr.RATE,0),
			td.EFFECTIVEFREIGHT =  round(isnull(ftcr.RATE,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 = 'CONFZ Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 FROM ABAGENTQUEUE Q (nolock) join 
	        IDCONSIGNEESHIPPERZONE csz (nolock) on  csz.rowid = q.sourceid join 
			OMTRANSACTIONHEADER th (nolock) on th.R_FMSHIPPER = csz.R_SHIPPER and th.r_shipper = csz.r_consignee join         
			OMTRANSACTIONDETAIL td  on td.R_TRANSACTIONHEADER = th.ROWID join          
			IDMASTER cons (nolock) on cons.ROWID = th.R_SHIPPER join                          
			IMITEM i (nolock) on i.ROWID = td.R_ITEM join                          
            IMFREIGHTRATETABLEZONE fz (nolock) on fz.r_zone = csz.r_zone  join
			IMCONTAINER cont (nolock) on cont.rowid = i.R_CONTAINERCODE   join
            IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE and ftcr.R_FREIGHTRATETABLEZONE = fz.rowid and cont.freightclasscode = ftcr.freightclasscode join
	        IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid  join
			RTZONETABLECODES ztc (nolock) on csz.R_ZONE = ztc.ROWID and fz.r_zone = ztc.rowid join                      
			IMFREIGHTRATETABLE ft ON fd.R_FREIGHTRATETABLE = ft.ROWID and ft.R_Shipper = csz.r_shipper 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Consignee Freight Zone Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and ft.r_shipper = csz.r_shipper
		     and cont.freightclasscode = ftcr.freightclasscode
			 and csz.R_ZONE = ztc.ROWID
			 and td.FREIGHTRATEPERITEMCHANGE = 'N'                                                                                          --new field 
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'

		/*
			select
		    td.FREIGHTRATEPERITEM , isnull(ftcr.RATE,0),
			td.EFFECTIVEFREIGHT ,  round(isnull(ftcr.RATE,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
			td.USERDEFINEDREFERENCE_10 , 'Consignee Freight Zone Cascade'
	 FROM ABAGENTQUEUE Q (nolock) join 
	        IDCONSIGNEESHIPPERZONE csz (nolock) on  csz.rowid = q.sourceid join 
			OMTRANSACTIONHEADER th (nolock) on th.R_FMSHIPPER = csz.R_SHIPPER and th.r_shipper = csz.r_consignee join         
			OMTRANSACTIONDETAIL td  on td.R_TRANSACTIONHEADER = th.ROWID join          
			IDMASTER cons (nolock) on cons.ROWID = th.R_SHIPPER join                          
			IMITEM i (nolock) on i.ROWID = td.R_ITEM join                          
            IMFREIGHTRATETABLEZONE fz (nolock) on fz.r_zone = csz.r_zone  join
			IMCONTAINER cont (nolock) on cont.rowid = i.R_CONTAINERCODE   join
            IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE and ftcr.R_FREIGHTRATETABLEZONE = fz.rowid and cont.freightclasscode = ftcr.freightclasscode join
	        IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid  join
			RTZONETABLECODES ztc (nolock) on csz.R_ZONE = ztc.ROWID and fz.r_zone = ztc.rowid join                      
			IMFREIGHTRATETABLE ft ON fd.R_FREIGHTRATETABLE = ft.ROWID and ft.R_Shipper = csz.r_shipper 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Consignee Freight Zone Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and ft.r_shipper = csz.r_shipper
		     and cont.freightclasscode = ftcr.freightclasscode
			 and csz.R_ZONE = ztc.ROWID
			 and td.FREIGHTRATEPERITEMCHANGE = 'N'                                                                                          --new field 
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
		*/

-- UPDATE OMFREIGHT 
	 DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	     FROM ABAGENTQUEUE Q (nolock) join 
	        IDCONSIGNEESHIPPERZONE csz (nolock) on  csz.rowid = q.sourceid join 
			OMTRANSACTIONHEADER th (nolock) on th.R_FMSHIPPER = csz.R_SHIPPER and th.r_shipper = csz.r_consignee join         
			OMTRANSACTIONDETAIL td (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join          
			IDMASTER cons (nolock) on cons.ROWID = th.R_SHIPPER join                          
			IMITEM i (nolock) on i.ROWID = td.R_ITEM join                          
            IMFREIGHTRATETABLEZONE fz (nolock) on fz.r_zone = csz.r_zone  join
			IMCONTAINER cont (nolock) on cont.rowid = i.R_CONTAINERCODE   join
            IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE and ftcr.R_FREIGHTRATETABLEZONE = fz.rowid and cont.freightclasscode = ftcr.freightclasscode join
	        IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid  join
			RTZONETABLECODES ztc (nolock) on csz.R_ZONE = ztc.ROWID and fz.r_zone = ztc.rowid join                      
			IMFREIGHTRATETABLE ft ON fd.R_FREIGHTRATETABLE = ft.ROWID and ft.R_Shipper = csz.r_shipper 
	  WHERE th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Consignee Freight Zone Cascade'
			 and th.R_ZONEFREIGHTRATEOVERRIDE is null 
			 and ft.r_shipper = csz.r_shipper
		     and cont.freightclasscode = ftcr.freightclasscode
			 and csz.R_ZONE = ztc.ROWID
			 and td.FREIGHTRATEPERITEMCHANGE = 'N'                                                                                          --new field 
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
     
	 update omfreight 
	 SET omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'CONFZ Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor

	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Consignee Freight Zone Cascade' 
	    and TASKSTATUS = 'PROCESSING' 
	
	END
--********************************************************************************************************************************************************************                                          
--Price Cascade Rule #8   All VALUES (Y N S) No need to check new field -OM Transaction Header  FREIGHT ZONE OVERRIDE Changed (Add, Update or Removed) then calls SP for details and other freight updates
--********************************************************************************************************************************************************************	
ELSE IF (@SOURCE = 'OMTHFZ') --                                                                               #8

	BEGIN

	 --CREATE BATCH TO PROCESS BY TAGGING ALL PENDING RECORDS IN AGENT QUEUE WITH PROCESSING
	     BEGIN
			  UPDATE q
			  SET q.TASKSTATUS = 'PROCESSING',
				  q.STARTTIME = getdate(),
				  @AgentRow = q.SOURCEID               --for freight update later
			 FROM ABAGENTQUEUE q
			WHERE q.AGENTNAME = 'Transaction Header Freight Zone Cascade' and q.TASKSTATUS = 'PENDING'
         END
	--OMTRANSACTIONHEADER.R_ZONEFREIGHTRATEOVERRIDE --> recalculate OMTRANSACTIONDETAIL ??                                            
	update td
	   set td.FREIGHTRATEPERITEM = isnull(ftcr.RATE,0),
		   td.EFFECTIVEFREIGHT =  round(isnull(ftcr.RATE,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
		   td.USERDEFINEDREFERENCE_10 = 'OMTHFZ Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
      FROM ABAGENTQUEUE Q (nolock) join 
	       OMTRANSACTIONHEADER th (nolock) on th.rowid = q.sourceid join         
		   OMTRANSACTIONDETAIL td  on td.R_TRANSACTIONHEADER = th.ROWID join 
		   IMITEM i (nolock) on i.ROWID = td.R_ITEM join 
		   IMCONTAINER cont (nolock) on cont.rowid = i.R_CONTAINERCODE   join
		   RTZONETABLECODES zt (nolock) on zt.rowid = th.R_ZONEFREIGHTRATEOVERRIDE join 
		   IMFREIGHTRATETABLEZONE fz (nolock) on fz.r_zone = th.R_ZONEFREIGHTRATEOVERRIDE  join
		   IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid join 
		   IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE and ftcr.R_FREIGHTRATETABLEZONE = fz.rowid and cont.freightclasscode = ftcr.freightclasscode 
	WHERE  th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Freight Zone Cascade'
		  -- and th.R_ZONEFREIGHTRATEOVERRIDE is not null   -- not necessary per Steve
			 and cont.freightclasscode = ftcr.freightclasscode 
			-- and td.FREIGHTRATEPERITEMCHANGE IN ('Y','S', 'N')   -- DO NOT NEED THIS LINE SINCE ALL                             --new field not needed here
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'        
/*
	select td.FREIGHTRATEPERITEM , isnull(ftcr.RATE,0),
		   td.EFFECTIVEFREIGHT ,  round(isnull(ftcr.RATE,0) * (case when th.stage in ('A','S','C') then isnull(td.QUANTITYSHIPPED,0) else isnull(td.QUANTITYORDERED,0) end ),2),
		   td.USERDEFINEDREFERENCE_10 , 'Transaction Header Freight Zone Cascade'
      FROM ABAGENTQUEUE Q (nolock) join 
	       OMTRANSACTIONHEADER th (nolock) on th.rowid = q.sourceid join         
		   OMTRANSACTIONDETAIL td  on td.R_TRANSACTIONHEADER = th.ROWID join 
		   IMITEM i (nolock) on i.ROWID = td.R_ITEM join 
		   IMCONTAINER cont (nolock) on cont.rowid = i.R_CONTAINERCODE   join
		   RTZONETABLECODES zt (nolock) on zt.rowid = th.R_ZONEFREIGHTRATEOVERRIDE join 
		   IMFREIGHTRATETABLEZONE fz (nolock) on fz.r_zone = th.R_ZONEFREIGHTRATEOVERRIDE  join
		   IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid join 
		   IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE and ftcr.R_FREIGHTRATETABLEZONE = fz.rowid and cont.freightclasscode = ftcr.freightclasscode 
	WHERE  th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Freight Zone Cascade'
		  -- and th.R_ZONEFREIGHTRATEOVERRIDE is not null   -- not necessary per Steve
			 and cont.freightclasscode = ftcr.freightclasscode 
			-- and td.FREIGHTRATEPERITEMCHANGE IN ('Y','S', 'N')   -- DO NOT NEED THIS LINE SINCE ALL                             --new field not needed here
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'        

*/
-- UPDATE OMFREIGHT 
	 DECLARE c_HDRCursor CURSOR LOCAL FAST_FORWARD FOR select distinct th.rowid 
	    FROM ABAGENTQUEUE Q (nolock) join 
	       OMTRANSACTIONHEADER th (nolock) on th.rowid = q.sourceid join         
		   OMTRANSACTIONDETAIL td (nolock) on td.R_TRANSACTIONHEADER = th.ROWID join 
		   IMITEM i (nolock) on i.ROWID = td.R_ITEM join 
		   IMCONTAINER cont (nolock) on cont.rowid = i.R_CONTAINERCODE   join
		   RTZONETABLECODES zt (nolock) on zt.rowid = th.R_ZONEFREIGHTRATEOVERRIDE join 
		   IMFREIGHTRATETABLEZONE fz (nolock) on fz.r_zone = th.R_ZONEFREIGHTRATEOVERRIDE  join
		   IMFREIGHTRATETABLEDATE fd (nolock) on fz.R_FREIGHTRATETABLEDATE = fd.rowid join 
		   IMFREIGHTRATETABLECLASSRATE ftcr (nolock) on cont.FREIGHTCLASSCODE = ftcr.FREIGHTCLASSCODE and ftcr.R_FREIGHTRATETABLEZONE = fz.rowid and cont.freightclasscode = ftcr.freightclasscode 
	WHERE  th.RECORDTYPE = 'R'
			 and q.AGENTNAME = 'Transaction Header Freight Zone Cascade'
		  -- and th.R_ZONEFREIGHTRATEOVERRIDE is not null   -- not necessary per Steve
			 and cont.freightclasscode = ftcr.freightclasscode 
			-- and td.FREIGHTRATEPERITEMCHANGE IN ('Y','S', 'N')   -- DO NOT NEED THIS LINE SINCE ALL                             --new field not needed here
			 and cast([dbo].[FN_GETEFFECTIVEDATEFRT](th.SHIPPINGDATE) as date) = cast(fd.EFFECTIVEDATE as date)
			 and q.TASKSTATUS = 'PROCESSING'        
  
  OPEN c_HDRCursor

  FETCH NEXT FROM c_HDRCursor INTO @HDR_Row

  WHILE @@FETCH_STATUS = 0

  BEGIN
      
	 update omfreight 
	 SET omfreight.amount = [dbo].[FN_OMCHECKMINZONEFREIGHT](@HDR_Row),
		 omfreight.weight = [dbo].[FN_OMGETWEIGHT](@HDR_Row),
		 omfreight.comment = 'OMTHFZ Cascade: ' + format (getdate(), 'yyyy-mm-dd hh:mm:ss')
	 where OMFREIGHT.R_TRANSACTIONHEADER = @HDR_Row 
	   and R_CHARGECODE = '61D90862-5551-4057-B753-53D297DB7450'

	 FETCH NEXT from c_HDRCursor into @HDR_Row
  END

  CLOSE c_HDRCursor
  DEALLOCATE c_HDRCursor
	--UPDATE BATCH RECORDS STATUS TO DONE
	 UPDATE ABAGENTQUEUE  
	    SET TASKSTATUS = 'DONE' , 
	        ENDTIME = getdate() 
	  WHERE AGENTNAME = 'Transaction Header Freight Zone Cascade' 
	    and TASKSTATUS = 'PROCESSING' 

	END
/**/
END


GO


