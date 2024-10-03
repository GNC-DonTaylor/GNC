USE [ABECAS_GNC_TEST]
GO

/****** Object:  StoredProcedure [dbo].[SPOM_USERVALIDATIONOFTRANSDETAILS]    Script Date: 5/4/2021 4:46:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO











---HEADER
CREATE OR ALTER   PROCEDURE [dbo].[SPOM_USERVALIDATIONOFTRANSDETAILS]
---PARAMS
(
@InCompanyID Char(2),
@InHeaderRowID VarChar(38),
@InDetailRowID VarChar(38),
@InTransLocRowID VarChar(38)

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
*  Procedure Name : SPOM_USERVALIDATIONOFTRANSDETAILS                                     *
*  Module         : OM                                                                    *
*  Function       : This procedure allows user to write their own data validatioins       *
*                   related to om transaction and transaction details records.            *
*                   The OM Transaction Profile has a new field for use of this            *
*                   stored procedure. This procedure will be called from OMD0001 program  *
*                   on the before post event (when user click save button). This stored   *
*                   procedure will return an exception error specified by the user for    *
*                   each validation logic they write. We have included some sample logic  *
*                   for possible validation handling.                                     *
*                                                                                         *
*  Date           : 07/22/2020                                                            *
*                                                                                         *
*******************************************************************************************
*  Note           : PLEASE READ THE ABOVE MESSAGE                                         *
*  08/08/2020 Radu Dontu                                                                  *
*             Added Inflated Left to Sell verification                                    *
*                                                                                         *
*******************************************************************************************/
Declare 
@ErrorMessage varchar(5000),
@missinglot int,
@missingprice int,
@holdstopcode char(1),
@itemstatus char(1),
@itemcode char(20),
@count int,
@MaxQty int = 0
  
  
set @ErrorMessage = ''

/**************************************************************************************************
*   BEGIN INVENTORY REVEIW CHECKS                                                                   *
*****************************************************************************************************/
--/*
  if exists (select 1
  from OMTRANSACTIONDETAIL (nolock)
  join OMTRANSACTIONHEADER (nolock) on OMTRANSACTIONHEADER.ROWID = OMTRANSACTIONDETAIL.R_TRANSACTIONHEADER
  join OMTRANSACTIONDP (nolock) on OMTRANSACTIONDP.ROWID = OMTRANSACTIONHEADER.R_PROFILE
  JOIN IMITEM (nolock) on IMITEM.ROWID = OMTRANSACTIONDETAIL.R_ITEM
  where OMTRANSACTIONDP.INVENTORYREVIEW = 'C'
    and isnull(IMITEM.SALEMAXQUANTITY, 0) > 0
    and case when OMTRANSACTIONHEADER.STAGE in ('A','S','C') then isnull(OMTRANSACTIONDETAIL.QUANTITYSHIPPED, 0) else isnull(OMTRANSACTIONDETAIL.QUANTITYORDERED, 0) end > isnull(IMITEM.SALEMAXQUANTITY, 0)
    and OMTRANSACTIONDETAIL.COMPANYID = @InCompanyID 
    and OMTRANSACTIONDETAIL.R_TRANSACTIONHEADER = @InHeaderRowID 
    and OMTRANSACTIONDETAIL.ROWID = @InDetailRowID
    and OMTRANSACTIONDETAIL.RECORDTYPE = 'R'
    and OMTRANSACTIONHEADER.STAGE in ('N', 'A')) and @InTransLocRowID is null
		  begin
			update OMTRANSACTIONDETAIL set INVENTORYREVIEW = 'Y' from OMTRANSACTIONDETAIL where ROWID = @InDetailRowID
			update OMTRANSACTIONHEADER set INVENTORYREVIEW = 'Y' from OMTRANSACTIONHEADER where ROWID = @InHeaderRowID
		--   RAISERROR('Inventory Review. Quantity is greater than Sale Max Qty.', 16,1)	
		 set  @MaxQty = 1
		   end
   else 
		   begin 
			 update OMTRANSACTIONDETAIL set INVENTORYREVIEW = 'N' from OMTRANSACTIONDETAIL where ROWID = @InDetailRowID

			 set @MaxQty = 0

			set  @count =  ( select  top 1 count(inventoryreview)
			  from omtransactiondetail (nolock) 
			  where omtransactiondetail.R_TRANSACTIONHEADER = @InHeaderRowID
			  and INVENTORYREVIEW = 'Y') 
	  
						  if @count = 0 
						  begin
						  update OMTRANSACTIONHEADER set INVENTORYREVIEW = 'N' from OMTRANSACTIONHEADER where ROWID = @InHeaderRowID
						  end
		   end

  
if exists (select 1 
  from OMTRANSACTIONDETAIL (nolock)
  join OMTRANSACTIONHEADER (nolock) on OMTRANSACTIONHEADER.ROWID = OMTRANSACTIONDETAIL.R_TRANSACTIONHEADER
  join OMTRANSACTIONDP (nolock) on OMTRANSACTIONDP.ROWID = OMTRANSACTIONHEADER.R_PROFILE
  where OMTRANSACTIONDP.INVENTORYREVIEW = 'C'
    and OMTRANSACTIONDETAIL.COMPANYID = @InCompanyID 
    and OMTRANSACTIONDETAIL.R_TRANSACTIONHEADER = @InHeaderRowID 
    and OMTRANSACTIONDETAIL.ROWID = @InDetailRowID
    and OMTRANSACTIONDETAIL.RECORDTYPE = 'R'
    and OMTRANSACTIONHEADER.STAGE in ('N', 'A')
                -- this should look at the quantity on the order detail line and check to see if it is greater than what is available...applying the oversellpercent to available if it exists for the item
                -- the error would be "Item Available Quantity is less than Total Sales Quantity for Item." ...triggering the Inventory Review flag = Y at header and detail row
                -- We want to review if someone ordered more than we have in Left to Sell (LTS) or Inflated Left to Sell (iLTS) so I am changing the > to < below - JoAnne
    and dbo.FNIM_GETUSERCALCULATEDFIELD('UserCalculated_1', OMTRANSACTIONDETAIL.R_LOT, OMTRANSACTIONDETAIL.R_ITEM) <
    case when OMTRANSACTIONHEADER.STAGE in ('A','S','C') 
	     then isnull(OMTRANSACTIONDETAIL.QUANTITYSHIPPED, 0) 
		 else isnull(OMTRANSACTIONDETAIL.QUANTITYORDERED, 0) end) 
	and @InTransLocRowID is null
	  begin
		update OMTRANSACTIONDETAIL set INVENTORYREVIEW = 'Y' from OMTRANSACTIONDETAIL where ROWID = @InDetailRowID
		update OMTRANSACTIONHEADER set INVENTORYREVIEW = 'Y' from OMTRANSACTIONHEADER where ROWID = @InHeaderRowID
	  -- RAISERROR('Inventory Review. Item Available Quantity is greater than Total Sales Quantity for Item.', 16,1)	
	  end
   else 
		   begin 
		     if @MaxQty = 0
				update OMTRANSACTIONDETAIL set INVENTORYREVIEW = 'N' from OMTRANSACTIONDETAIL where ROWID = @InDetailRowID

			set  @count =  ( select  top 1 count(inventoryreview)
			  from omtransactiondetail (nolock) 
			  where omtransactiondetail.R_TRANSACTIONHEADER = @InHeaderRowID
			  and INVENTORYREVIEW = 'Y') 
	  
						  if @count = 0 
						  begin
						  update OMTRANSACTIONHEADER set INVENTORYREVIEW = 'N' from OMTRANSACTIONHEADER where ROWID = @InHeaderRowID
						  end
		   end
 --*/
 
/***************************************************************************************************
*  END INVENTORY REVIEW CHECKS                                                                     *
****************************************************************************************************/
--populate variable for error messages
--/*
set @itemcode = (select trim(i.itemcode)
                 from OMTRANSACTIONHEADER h (NOLOCK) inner join 
					       OMTRANSACTIONDETAIL d (NOLOCK) on  d.R_TRANSACTIONHEADER = h.rowid  inner join
						   IMITEM i (nolock) on d.r_item = i.rowid
                     where d.ROWID = @InDetailRowID)
--*/
  /***************************************************************************************************
*   BEGIN HARD ERROR REQUIRE LOT ON ALL ITEMS     6                                                  *
****************************************************************************************************/

--/*
set @missinglot = 0

set @missinglot = (select top 1 count(r_item)
                      from OMTRANSACTIONHEADER h (NOLOCK) inner join 
					       OMTRANSACTIONDETAIL d (NOLOCK) on  d.R_TRANSACTIONHEADER = h.rowid 
                     where  d.ROWID = @InDetailRowID
					       and d.R_LOT is null)
If @missinglot > 0
	begin
		set @ErrorMessage = 'USP ERROR: Item '+@itemcode + 'must have a lot.'
				--RAISERROR(@ErrorMessage, 16,1)
	end 

--*/
/***************************************************************************************************
*  END HARD ERROR REQUIRE LOT ON ALL ITEMS    6                                                     *
****************************************************************************************************/

/***************************************************************************************************
*   BEGIN HARD ERROR REQUIRE PRICE ON ALL ITEMS       3                                              *
****************************************************************************************************/
-- may need to check for valid price for date instead of just a price? then warning, not hard stop? true override ok? Validations should have already been done from Insight
--/*
set @missingprice = 0

set @missingprice = (select top 1 count(r_item)
                      from OMTRANSACTIONHEADER h (NOLOCK) inner join 
					       OMTRANSACTIONDETAIL d (NOLOCK) on  d.R_TRANSACTIONHEADER = h.rowid 
                     where d.ROWID = @InDetailRowID
					       and isnull(d.UNITPRICE,0) = 0 )

--select * from omtransactiondetail where rowid = 'B6842286-BC27-48C0-B98E-0AFB4925EE7B'
-- select * from omtransactionheader where rowid = ''
If @missingprice > 0
	begin
					--RAISERROR(@ErrorMessage, 16,1)
			if @ErrorMessage = '' 
				  begin
					 set @ErrorMessage = 'USP ERROR: Item '+@itemcode +'No List price!'
				  end
				  else
				  begin
					 set @ErrorMessage = @ErrorMessage +  ' and price.'
				  end
			
	end 
--	*/

/***************************************************************************************************
*   END HARD ERROR REQUIRE PRICE ON ALL ITEMS      3                                                 *
****************************************************************************************************/

/***************************************************************************************************
*   BEGIN STOP SHIP NOT ALLOWED ON ORDER       4                                                    *
****************************************************************************************************/
--/*
set @holdstopcode = '' ---IMLOT.UDC_3

set @holdstopcode = (select isnull(trim(l.userdefinedcode_3),'') 
                      from OMTRANSACTIONDETAIL d (NOLOCK) inner join
						   IMLOT l (NOLOCK) on d.r_lot = l.rowid
                     where d.ROWID = @InDetailRowID)
						   -- use wh 10 lot 21.F1 items 1929.031.1, 4657.051.1, 1604.031.1, 507.081.1  for testing

If isnull(@holdstopcode,'') = 'S'
		begin 		
				if @ErrorMessage = '' 
						  begin
							set @ErrorMessage = 'USP ERROR: Item '+@itemcode + ' is on Stop Ship cannot be ordered.'
						  end
						  else
						  begin
							 set @ErrorMessage = @ErrorMessage + CHAR(10) + CHAR(13)  + ' Although it is on Stop Ship and cannot be ordered.'
						  end
				
		end 

--*/
/***************************************************************************************************
*   END STOP SHIP NOT ALLOWED ON ORDER             4                                              *
****************************************************************************************************/
	if (@ErrorMessage <> '')
		begin
		RAISERROR( @ErrorMessage, 16,1)
		end
 /**/
-- End of stored procedure
END


---FOOTER


GO


