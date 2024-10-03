--USE [ABECAS_GNC_TEST]
--GO

--/****** Object:  StoredProcedure [dbo].[SPOM_USERVALIDATIONOFTRANSACTIONS]    Script Date: 6/23/2021 7:55:50 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

---HEADER
CREATE OR ALTER PROCEDURE [dbo].[SPOM_USERVALIDATIONOFTRANSACTIONS]
---PARAMS
(
@InHeaderRowID VarChar(38),
@InCompanyID Char(2),
@InRecordType Char
)
---BEFORE SYSTEM
AS

BEGIN

-- Declare system variables
DECLARE
  @SYS_DATETIME DATETIME,
  @SYS_USER VARCHAR(50)
-- SET SYSTEM VARIABLES
SET @SYS_DATETIME = GETDATE()
SET @SYS_DATETIME = DATEADD(MS,(-1) * (DATEPART(MS, @SYS_DATETIME) % 10), @SYS_DATETIME)
SET @SYS_USER = SUBSTRING(RTRIM(SYSTEM_USER), PATINDEX('%\%', RTRIM(SYSTEM_USER))+1, 50)


---SYSTEM
/******************************************************************************************
*                                                                                         *
*  Procedure Name : spOM_UserValidationOfTransactions                                     *
*  Module         : OM                                                                    *
*  Function       : This procedure allows user to write their own data validatioins       *
*                   related to om transaction records.                                    *
*                   The OM Transaction Profile has a new field for use of this            *
*                   stored procedure. This procedure will be called from OMD0001 program  *
*                   on the before post event (when user click save button). This stored   *
*                   procedure will return an exception error specified by the user for    *
*                   each validation logic they write. We have included some sample logic  *
*                   for possible validation handling.                                     *
*                                                                                         *
*  Date           : 08/05/2010                                                            *
*                                                                                         *
*******************************************************************************************
*  Note           : PLEASE READ THE ABOVE MESSAGE                                         *
*  Mod Date       : 04/10/2020         : JoAnne Brown - Greenleaf Nursery                 *
*                   Added validation to check customer delayed billing due dates which    *
*                   are stored as strings in udr6 and udr7 of the IDCUSTOMER. Parse the   *
*                   strings to load substrings into variables to see if transactiondate   *
*                   falls between from and to date ranges to set a new override due date  *
*                                                                                         *
*******************************************************************************************/

-- ---------------------------------------------------------------------------------------
-- Greenleaf custom code added
-- ---------------------------------------------------------------------------------------
DECLARE
---shared------------------
@ErrorMessage varchar(5000),
@TransactionDate Datetime,
@R_Cust UniqueIdentifier,
@R_Cons UniqueIdentifier,
@R_FMShipper UniqueIdentifier,
-------------1--------------                           
@year int,
@mmdd char(5),
@mm int,
@mm2 int,
@dueDate date,
@Update Char,
@DateString varchar(100),
@pos int,
@len int,
@loopcount int,
@fromdate char(5),
@todate char(5),
@newduedate char(5),
@sets int,
-------------2--------------
@priceschedule UniqueIdentifier,
@altsku varchar(30),
@countscheduleprice int,
@KeySequence int,
@isEDIRollup varchar(50),
----------3-----------------
--@unspecifiedflag char(12),
--@countitemcodes int,
----------4---------------
@retailrequired char(1),
@skurequired char(1),
@customerunitretail money,
@custitemsku varchar(20),
@missingretail int ,
@missingsku int,
@EDIRollup varchar(10),
----------5------------
@PORequired  char(1),
@POValue varchar(20)



Set @ErrorMessage = ''
Set @altsku = ''
Set @POValue = ''
Set @PORequired = 'N'

--load variables for all checks in one trip, add more here as needed for new checks
Select	@transactiondate = TransactionDate, --'2020-03-31 13:05:25.980'
		@R_Cust = R_CUSTOMER, --@R_Cust = '04075362-7130-489F-82EB-CE9E06A13184'
		@R_Cons = R_SHIPPER,
		@R_FMShipper = R_FMSHIPPER,
		@POValue = isnull(PURCHASEORDERNUMBER,'')
		from OMTRANSACTIONHEADER (nolock) 
		where ROWID = @InHeaderRowID and COMPANYID = @InCompanyID and @InRecordType = 'R'
		


Select @priceschedule = c.R_PRICESCHEDULE
from IDCONSIGNEESHIPPERZONE c (nolock)
where R_CONSIGNEE = @R_Cons
 and R_SHIPPER = @R_FMShipper

Select @PORequired = omrequirepo
from IDCUSTOMER (nolock)
where r_identity = @R_Cust

if  @priceschedule is not null
 begin
	select @retailrequired = isnull(p.retailrequired,'N') ,
		   @skurequired = isnull(p.skurequired,'N') --,
		--   @unspecifiedflag = isnull(ALLOWUNSPECIFIED,'Y')  --this should be in native Insight for Greenleaf, not working yet
	from IMPRICESCHEDULEHEADER p (nolock) where @priceschedule = p.ROWID
  end
  else
	begin
		set @retailrequired = 'N'
		set @skurequired = 'N'
		--set @unspecifiedflag = 'Y'
	end

			
set @year = DATEPART(yyyy,@transactiondate)
set @mmdd = convert(varchar(5),@transactiondate,110)

/***************************************************************************************************
* 1 BEGIN CHECK FOR OVERRIDE BILLING DUE DATES FOR CUSTOMER                                        *
****************************************************************************************************/
Set @update = 'F'
--jb datestring example '01-0103-1506-15;03-1605-1509-15;05-1606-1508-15' up to three sets per udr, 6 sets max separated by ;
--Userdefinedreference_6= = '01-0104-1507-31;04-1606-2012-31'--Userdefinedreference_7 = null
Select @DateString = isnull(Userdefinedreference_6,'')+';'+isnull(Userdefinedreference_7,'') from IDCUSTOMER (nolock) where R_IDENTITY = @R_Cust

If len(@DateString)=95--six full ranges if udr7 is 3 sets, add a ; to keep count of sets correct below, end of udr6 sets uses ; from concat above
begin
   set @DateString = @DateString+';' 
end
--@DateString = '01-0104-1507-31;04-1606-2012-31;'

If len(@DateString) > 1 --not all customers will have delayed bill dates, should be only ';' if no delayed dates are set

begin
	--starts at 0 so count the ; to set the loop count
	set @sets = (SELECT LEN(@DateString) - LEN(REPLACE(@DateString, ';', '')))--@DateString = '01-0104-1507-31;04-1606-2012-31;' @sets = 1
	set @loopcount = 0  
	set @pos = 1
	set @len = 5
	--read string 5 char at a time to load each variable, skip semicolon
	while @loopcount < @sets and @update = 'F'
      begin
		set @fromdate = (SELECT convert(varchar(5),substring((@DateString),@pos,@len),110)) --@fromdate '01-01'
		set @pos = @pos +@len 
		set @todate = (SELECT convert(varchar(5),substring((@DateString),@pos,@len),110))  -- @todate = '04-15'
		set @pos = @pos +@len 
		set @newduedate = (SELECT convert(varchar(5),substring((@DateString),@pos,@len),110)) --@newduedate = '12-31'
		set @pos = @pos+@len +1 -- skip ; in  @DateString from concat in select above

	    if @mmdd between @fromdate and @todate
			   begin
				 set @update = 'T'
			   end
		set @loopcount = @loopcount +1
		
	  end
--requires data to be entered with hard 12-31 end dates if date crosses calendar year
	set @mm = cast(left(@newduedate,2)as int)
	set @mm2 = cast(left(@todate,2 )as int)
--see if new due data crosses a calendar year end
	if @mm2 > @mm
	  begin
		set @year = @year+1
	  end
	  --remove dash
	set @mmdd = replace(@newduedate,'-','')
	set @dueDate = cast(cast(@year*10000 + @mmdd as varchar(255)) as date)
-- update the duedate to the new override duedate
	if @update = 'T'
	begin
	   update OMTransactionHeader
			  set TransactionDueDate = @dueDate
	   where ROWID = @InHeaderRowID and COMPANYID = @InCompanyID and @InRecordType = 'R'  
	end
end
/***************************************************************************************************
* 1 END CHECK FOR OVERRIDE BILLING DUE DATES FOR CUSTOMER                                          *
****************************************************************************************************/

/***************************************************************************************************
* 2 BEGIN WARNING PRICES WITHIN SKU SET NOT MATCHING    rule 7                                     *
****************************************************************************************************/
--may only be needed for EDI customers
--/*
set @KeySequence = 0

select @EDIRollup = isnull(USERDEFINEDCODE_3,'N')
from IDCUSTOMER (nolock) where rowid = @R_Cust
-----------------------------------------------can this only look if items on the order have this situation????????????????????????????????
if @priceschedule is not null
begin
select  @KeySequence = count(dtl.KEYSEQUENCE)
       from OMTRANSACTIONDETAIL dtl (nolock) join
	   IMPRICESCHEDULEDETAIL psd (nolock) on psd.r_item = dtl.r_item    
	  where dtl.R_TRANSACTIONHEADER = @InHeaderRowID
	  and R_PRICESCHEDULEHEADER = @priceschedule
	  having sum(isnull(dtl.unitprice,0)+isnull(dtl.freightrateperitem,0)+isnull(dtl.handlingchargeperitem,0)+isnull(dtl.taggingchargeperitem,0)) <>  
	      sum(isnull(psd.discountprice,0)+isnull(psd.freightcharge,0) + isnull(psd.othercharge,0) + isnull(psd.handlingcharge,0))
   --group by ALTERNATESKU
   --  having count(dtl.KEYSEQUENCE) >1

	 if @KeySequence > 0
	 begin
	 if @EDIRollup = 'Y' 
			begin
			   set @ErrorMessage = 'STOP! ***** EDI WILL FAIL ***** STOP!' + CHAR(10) + CHAR(13) + 'SKU has multiple prices.'
	        end
			else
		    begin
			   set  @ErrorMessage = 'USP WARNING: ' + CHAR(10) + CHAR(13) + 'Multiple prices for SKU' 
		    end
	end
end
--*/
/***************************************************************************************************
*  2 END WARNING PRICES WITHIN SKU SET NOT MATCHING  rule 7                                             *
****************************************************************************************************/

/***************************************************************************************************
* 3 BEGIN WARNING UNSPECIFIED ITEMS ON ORDER NOT ALLOWED   rule  5  should be in native Insight for Greenleaf *
****************************************************************************************************/

/*
if @unspecifiedflag = 'N'
  set @countitemcodes = 0
begin
  set @countitemcodes = (   select  count(t1.R_ITEM )
	 FROM OMTRANSACTIONDETAIL t1 (nolock)
	 left join IMPRICESCHEDULEDETAIL t2 (nolock) on t1.R_ITEM = t2.R_ITEM
	 where  t2.R_PRICESCHEDULEHEADER = @priceschedule
	 and t2.r_item is null)

 if @countitemcodes > 0
	 if @ErrorMessage <> ''  
	   begin
	      set @ErrorMessage = 'USP ERROR: '+ convert(char(3),@countitemcodes ) +' unspecified items ordered.'
	   end
	   else
	   begin 
	     set @ErrorMessage = @ErrorMessage + CHAR(10) + CHAR(13) + convert(char(3),@countitemcodes ) +' unspecified items ordered.'
	   end

end
*/

/***************************************************************************************************
*  3 END WARNING UNSPECIFIED ITEMS ON ORDER NOT ALLOWED   rule   5                                 *
****************************************************************************************************/

/***************************************************************************************************
* 4 BEGIN WARNING REQUIRED RETAIL AND/OR SKU MISSING  rules 1 & 2                                  *
****************************************************************************************************/
--/*
set @missingretail = 0
set @missingsku = 0
--------------retail check------------------
if (@retailrequired = 'Y'  and  @priceschedule is not null)
begin
set @missingretail = (select  count(R_ITEM)
                      from IMPRICESCHEDULEHEADER h (nolock) inner join 
					       IMPRICESCHEDULEDETAIL d (nolock) on  d.R_PRICESCHEDULEHEADER = h.ROWID 
                      where @priceschedule = h.ROWID
							and isnull(d.RETAILPRICE,0) = 0
							and d.R_ITEM in (select R_ITEM from OMTRANSACTIONDETAIL (nolock) where R_TRANSACTIONHEADER = @InHeaderRowID))
   if @missingretail > 0
	 if @ErrorMessage = ''  
	   begin
	      set @ErrorMessage = 'USP WARNING: '+ CHAR(10) + CHAR(13) + convert(char(3),@missingretail ) +' item(s) missing retails ordered.'
	   end
	   else
	   begin 
	     set @ErrorMessage = @ErrorMessage + CHAR(10) + CHAR(13) + convert(char(3),@missingretail ) +' item(s) missing retails ordered.'
	   end
	
end


-------------sku check--------------------------
if (@skurequired= 'Y'   and  @priceschedule is not null)
begin
set @missingsku = (select  count(R_ITEM)
                      from IMPRICESCHEDULEHEADER h (nolock) inner join 
					       IMPRICESCHEDULEDETAIL d (nolock) on  d.R_PRICESCHEDULEHEADER = h.ROWID 
                      where @priceschedule = h.ROWID
							and isnull(d.ALTERNATESKU ,'') = ''
							and d.R_ITEM in (select R_ITEM from OMTRANSACTIONDETAIL (nolock) where R_TRANSACTIONHEADER = @InHeaderRowID))
	if @missingsku > 0
	 if @ErrorMessage = ''  
	   begin
	      set @ErrorMessage = 'USP WARNING: ' + CHAR(10) + CHAR(13) + convert(char(3),@missingsku ) +'item(s) missing skus ordered.'
	   end
	   else
	   begin 
	     set @ErrorMessage = @ErrorMessage + CHAR(10) + CHAR(13) + convert(char(3),@missingsku ) +' item(s) missing skus ordered.'
	   end
end

/***************************************************************************************************
*  4 END WARNING REQUIRED RETAIL AND/OR SKU MISSING   rules 1 & 2                                  *
****************************************************************************************************/
/***************************************************************************************************
* 5 BEGIN WARNING PO REQUIRED  
****************************************************************************************************/
--Lukas is looking into this. After adding, the PO still shows needed
--/*
if (@PORequired = 'Y' and isnull(@POValue,'')  = '')

begin
	 if @ErrorMessage = ''  
	   begin
	      set @ErrorMessage = 'USP ERROR: ' + CHAR(10) + CHAR(13) + 'PO Number is Required.'
	   end
	   else
	   begin 
	     set @ErrorMessage = @ErrorMessage + CHAR(10) + CHAR(13) + 'PO Number is Required.'
	   end

end
--*/
/***************************************************************************************************
*  5 END WARNING PO REQUIRED                                   *
****************************************************************************************************/

/************************************************************************************************************
*   BEGIN ERROR MESSAGE TO USER IF ONE WAS TRIGGERED ABOVE - INSIGHT CAN ONLY RETURN ONE MESSAGE FOR THIS SP*
*************************************************************************************************************/
if @ErrorMessage <> ''
begin
    RAISERROR( @ErrorMessage, 16,1)
end
/*********************************************************************************************************
*  END ERROR MESSAGE TO USER IF ONE WAS TRIGGERED ABOVE - INSIGHT CAN ONLY RETURN ONE MESSAGE FOR THIS SP*
**********************************************************************************************************/

--/*
-- End of stored procedure
END
---FOOTER





GO


