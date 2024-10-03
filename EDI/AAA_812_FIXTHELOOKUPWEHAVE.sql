--AAA_812_FIXTHELOOKUPWEHAVE

Declare 
	@BCD01 Varchar(20) = '19680127',	--CD ADJ DATE
	@BCD02 Varchar(30) = '123456789',	--CD ADJ NUMBER
	@BCD05 Varchar(2) = 'C',			--CD CODE (C=CREDIT,D=DEBIT)
	@BCD07 Varchar(500) = '10-45775',	--INVOICE#
	@BCD10 Varchar(50) = 'POB1X80156',	--PO#
	@N902 Varchar(50) = '999990001',	--VENDORID
	@SAC01 Varchar(1) = 'A',			--TAXCODE (A=ALLOWANCE,C=CHARGE)	
	@SAC02 Varchar(4) = 'H850',			--TAXTYPE
	@SAC05 Varchar(15) = '450',			--TAXAMOUNT
	@N102 Varchar(35) = 'RURALKING #99',	--SHIP-TO NAME
	@N104 Varchar(18) = '99',			--STORENUMBER
	@CDD01 Varchar(2) = '01',			--ADJREASON (01=PRICE ERROR)
	@CDD02 Varchar(1) = 'C',			--ADJCODE
	@CDD07 Varchar(10) = '2',			--ADJQUANTITY
	@CDD08 Varchar(02) = 'EA',			--EACH
	@CDD11 Varchar(12) = '1.25',		--UNITPRICE
	@LIN03 Varchar(30) = '801560001',	--SKU
	@N902ZZ Varchar(30) = 'BECAUSE',	--DESCRIPTION
	--@N903LI Varchar(30) = 'REASONS',	--COMMENTS
	@N902L1 Varchar(30) = 'REASONS',	--COMMENTS
	@SAC01Info Varchar(1) = 'A',		--SACCODE (A=ALLOWANCE, C=CHARGE)
	@SAC02Info Varchar(4) = 'F050',		--SACTYPE
	@SAC05Info Varchar(15) = '1.11',	--SACAMOUNT
	@SAC15Info Varchar(100) = 'BLAH'	--SACDESCRIPTION

Declare 
@bcd03 varchar(2) = 'missing',--TRCODE (T=SEND810, H=DONTSEND810)
@bcd04 varchar(15) = 'missing',--CD AMOUNT
@bcd12 varchar(2) = 'missing',--TRTYPE (CR=CREDIT,DR=DEBIT,RA=CRNOTEREQUEST)
@bcd13 varchar(3) = 'missing',--TRQUAL (PD=DEAL#,1X=CRADJ#)
@bcd14 varchar(50) = 'missing',--TRID (EITHER CRADJ# OR DEAL#)
@n301 varchar(35) = 'missing',--SHIP-TO ADDRESS
@n401 varchar(20) = 'missing',--SHIP-TO CITY
@n402 varchar(2) = 'missing',--SHIP-TO STATE
@n403 varchar(10) = 'missing',--SHIP-TO ZIP
@cdd14 varchar(264) = 'missing',--COMMENT
@lin01 varchar(10) = 'missing',--LINENUMBER
@lin05 varchar(48) = 'missing',--UPCCODE
@lin07 varchar(48) = 'missing',--ITEMCODE
@sac08info varchar(9) = 'missing'--RATE

------------------------------------------
Declare 
	@CREDITDEBIT	VARCHAR(7),	
	@SENDONTSEND	VARCHAR(20), 
	@CREDITNOTE		VARCHAR(20), 
	@TRANSTYPE		VARCHAR(20), 
	@CDDREASON		VARCHAR(60), 
	@SACINFOTYPE	VARCHAR(10), 
	@SACINFOCODES	VARCHAR(60),	
	@ROWID			UNIQUEIDENTIFIER --VARCHAR(38), 
	@EMAILSUBJECT	VARCHAR(1000), 
	@EMAILBODY		VARCHAR(MAX) 

SET @CREDITDEBIT =	(
	CASE	WHEN @BCD05 = 'C' THEN 'CREDIT' 
			WHEN @BCD05 = 'D' THEN 'DEBIT' 
	ELSE 'err' END	)
SET @SENDONTSEND =	(
	CASE	WHEN @BCD03 = 'T' THEN 'CREATE/SEND' 
			WHEN @BCD03 = 'H' THEN 'INFORMATIONAL ONLY' 
	ELSE 'err' END	)
SET @CREDITNOTE =	(
	CASE	WHEN @BCD12 = 'CR' THEN 'CREDIT MEMO' 
			WHEN @BCD12 = 'DR' THEN 'DEBIT MEMO' 
			WHEN @BCD12 = 'RA' THEN 'CREDIT NOTE REQUEST' 
	ELSE 'err' END	)
SET @TRANSTYPE =	(
	CASE	WHEN @BCD13 = 'PD' THEN 'PROMO/DEAL#: ' 
			WHEN @BCD13 = '1X' THEN 'CDADJUSTMENT#: ' 
	ELSE 'err' END	)
SET @CDDREASON =	(
	CASE	WHEN @CDD01 = '01' THEN 'PRICING ERROR'
			WHEN @CDD01 = '06' THEN 'QUANTIY CONTESTED'
			WHEN @CDD01 = '10' THEN 'PALLET/CONTAINER CHARGE ERROR'
			WHEN @CDD01 = '11' THEN 'RETURNS - DAMAGE'
			WHEN @CDD01 = '54' THEN 'FREIGHT DEDUCTED'
			WHEN @CDD01 = '55' THEN 'TAX DEDUCTED'
			WHEN @CDD01 = '57' THEN 'VOLUME DISCOUNT TAKEN'
			WHEN @CDD01 = '79' THEN 'COOPERATIVE ADVERTISING'
			WHEN @CDD01 = '81' THEN 'CREDIT AS AGREED'
			WHEN @CDD01 = '82' THEN 'DEFECTIVE ALLOWANCE'
			WHEN @CDD01 = '88' THEN 'DUTY CHARGE VARIANCE'
			WHEN @CDD01 = '98' THEN 'LABOR CHARGES'
			WHEN @CDD01 = 'A3' THEN 'NEW STORE ALLOWANCE'
			WHEN @CDD01 = 'A5' THEN 'OVERAGE'
			WHEN @CDD01 = 'A8' THEN 'PROMOTIONAL ALLOWANCE'
			WHEN @CDD01 = 'B2' THEN 'REBATE'
			WHEN @CDD01 = 'B6' THEN 'REPAY DISCOUNT'
			WHEN @CDD01 = 'BE' THEN 'FIXTURE ALLOWANCE'
			WHEN @CDD01 = 'E5' THEN 'INVOICE PRICE PROTECTION'
			WHEN @CDD01 = 'E7' THEN 'GOODS AND SERVICES TAX DECREASED DUE TO BILLING ERROR'
			WHEN @CDD01 = 'GE' THEN 'SLOTTING CHARGE'
			WHEN @CDD01 = 'GA' THEN 'FREE GOODS'
			WHEN @CDD01 = 'IA' THEN 'INVOICE AMOUNT DOES NOT MATCH ACCOUNT ANALYSIS STATEMENT'
			WHEN @CDD01 = 'L7' THEN 'MISCELLANEOUS DEDUCTIONS'
			WHEN @CDD01 = 'L8' THEN 'MISCELLANEOUS CREDITS'
			WHEN @CDD01 = 'RB' THEN 'AGREED FREIGHT ALLOWANCE'
			WHEN @CDD01 = 'SF' THEN 'SHIPPING AND FREIGHT CHARGE'
			WHEN @CDD01 = 'WW' THEN 'OVERPAYMENT CREDIT'
			WHEN @CDD01 = 'ZZ' THEN 'MUTUALLY DEFINED'
	ELSE 'err' END	)
SET @SACINFOTYPE =	(
	CASE	WHEN @SAC01INFO = 'A' THEN 'ALLOWANCE'
			WHEN @SAC01INFO = 'C' THEN 'CHARGE'
	ELSE 'err' END	)
SET @SACINFOCODES =	(
	CASE	WHEN @SAC02INFO = 'F050' THEN 'MISCELLANEOUS'
			WHEN @SAC02INFO = 'H850' THEN 'TAXES'
			WHEN @SAC02INFO = 'F180' THEN 'PALLET SURCHARGES'
			WHEN @SAC02INFO = 'G821' THEN 'SHIPPING'
			WHEN @SAC02INFO = 'E890' THEN 'OCEAN FREIGHT'
			WHEN @SAC02INFO = 'A310' THEN 'AIR FREIGHT'
			WHEN @SAC02INFO = 'D240' THEN 'DOMESTIC FREIGHT'
			WHEN @SAC02INFO = 'C530' THEN 'DUTY CHARGE'
			WHEN @SAC02INFO = 'A122' THEN 'TARIFF'
			WHEN @SAC02INFO = 'I530' THEN 'VOLUME DISCOUNT'
			WHEN @SAC02INFO = 'F910' THEN 'QUARTERLY VOLUME REBATE'
			WHEN @SAC02INFO = 'G960' THEN 'SLOTTING ALLOWANCE'
			WHEN @SAC02INFO = 'D170' THEN 'FREE GOODS'
			WHEN @SAC02INFO = 'F970' THEN 'MONTHLY REBATE'
			WHEN @SAC02INFO = 'F680' THEN 'PRICING CORRECTION'
			WHEN @SAC02INFO = 'B720' THEN 'COOPERATIVE ADVERTISING'
			WHEN @SAC02INFO = 'F800' THEN 'PROMOTIONAL ALLOWANCE'
			WHEN @SAC02INFO = 'B210' THEN 'CO-OP CREDIT'
			WHEN @SAC02INFO = 'F810' THEN 'PROMOTIONAL DISCOUNT'
			WHEN @SAC02INFO = 'E190' THEN 'LABOR CHARGES'
			WHEN @SAC02INFO = 'E565' THEN 'MARKDOWN ALLOWANCE'
			WHEN @SAC02INFO = 'B950' THEN 'SHIPPING DAMAGES'
			WHEN @SAC02INFO = 'D350' THEN 'GOODS AND SERVICES CREDIT ALLOWANCES'
			WHEN @SAC02INFO = 'C000' THEN 'DEFECTIVE ALLOWANCE'
			WHEN @SAC02INFO = 'C010' THEN 'DEFICIT FREIGHT'
			WHEN @SAC02INFO = 'C750' THEN 'OVERPAYMENTS'
			WHEN @SAC02INFO = 'D890' THEN 'TRAINING'
			WHEN @SAC02INFO = 'I090' THEN 'TOOL CHARGE'
			WHEN @SAC02INFO = 'A570' THEN 'EXCESS FREIHT, NOT LANDABLE'
			WHEN @SAC02INFO = 'I590' THEN 'WARRANTIES'
			WHEN @SAC02INFO = 'B750' THEN 'CORE CHARGE'
			WHEN @SAC02INFO = 'IDCT' THEN 'IMPROPER DOCUMENTATION'
	ELSE 'err' END	)

SET @EMAILSUBJECT = '<EMAILSUBJECT>' + ISNULL(TRIM(@BCD02), 'missing') + ' (' + @CREDITDEBIT + ') ' + ISNULL(TRIM(@BCD07), 'missing') + ' CREDIT DEBIT ADJUSTMENT<BR>'

SET @EMAILBODY = '<EMAILBODY>' + 
@CREDITDEBIT + ' ADJUSTMENT #: ' + ISNULL(TRIM(@BCD02),'missing') + '<BR>' 
+ REPLICATE('-',40)+'<BR>' 
+ @SENDONTSEND + '<BR>' 
+ 'DATE: ' + ISNULL(TRIM(@BCD01), 'missing') + '<BR>' 
+ 'INV#: ' + ISNULL(TRIM(@BCD07), 'missing') + '   PO#: ' + ISNULL(TRIM(@BCD10), 'missing') + '<BR>' 
+ @CREDITNOTE + '-' + @TRANSTYPE + ISNULL(TRIM(@BCD14),'missing') + '<BR>' 
+ IIF(ISNULL(@SAC02,'')='', '','HEADER ADJUSTMENT: ' + @SAC02 + '(' + @SAC01 + ') = $' + LEFT(TRIM(@SAC05),LEN(TRIM(@SAC05))-2)+'.'+RIGHT(TRIM(@SAC05),2) + '<BR>')
+ 'VENDOR#: '+ISNULL(TRIM(@N902),'missing')+'     STORE#: '+ISNULL(RIGHT('00'+TRIM(@N104),4),'missing')+'<BR><BR>'
+ ISNULL(TRIM(@N102),'missing') + '<BR>' 
+ ISNULL(TRIM(@N301),'missing')+'<BR>' 
+ ISNULL(TRIM(@N401),'missing') + ', ' + ISNULL(TRIM(@N402),'missing') + '  ' + ISNULL(TRIM(@N403),'missing')+'<BR><BR>'
+'LIN#:'+TRIM(@LIN01)+'   SKU:'+TRIM(@LIN03)+'   ITEM#:'+TRIM(@LIN07)+'(UPC:'+TRIM(@LIN05)+')   QTY:'+TRIM(@CDD07)+' @ $'+TRIM(@CDD11)+'   '
+@CDD01 + '-' + @CDDREASON + '   ' + TRIM(@CDD14) + '   '+@N902ZZ + '/' + @N902L1 + '<BR>'
+REPLICATE(' ',20)+TRIM(@SAC02INFO)+': '+ @SACINFOCODES + ' (' + @SACINFOTYPE + ')  RATE: '+ @SAC08INFO + '     $' + LEFT(TRIM(@SAC05INFO),LEN(TRIM(@SAC05INFO))-2)+'.'+RIGHT(TRIM(@SAC05INFO),2) + '<BR>'
+'TOTAL ADJUSTMENT AMOUNT: $'+ LEFT(TRIM(@BCD04),LEN(TRIM(@BCD04))-2)+'.'+RIGHT(TRIM(@BCD04),2) + '<BR><BR>'

Set @EmailSubject = @EmailSubject + '</EmailSubject>'
Set @EmailBody = @EmailBody + '</EmailBody>'

SELECT @EMAILSUBJECT AS EMAILSUBJECT, @EMAILBODY AS EMAILBODY
/*
--Populate ABERRORSHEADER
Set @RowId = NewId()
INSERT INTO ABERRORSHEADER (ROWID, COMPANYID, MODULE, RECORDTYPE, DESCRIPTION, COMMENT)
VALUES (@RowId, 'SB', 'OM', 'R', '812 EDI MESSAGE', @EmailSubject + @EmailBody)
*/
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
/*
Declare 
		@DocumentNo  Varchar(100), 
		@CreditDebitFlagCode Varchar(500),
        @Date        Varchar(20),
        --@Time        Varchar(20),
        --@Reference   Varchar(60),
        --@SenderCode  Varchar(30),
        --@GrpControl  Varchar(20),
        --@TranSetCtrl Varchar(20),
        --@ErrorCond   Varchar(30),
        --@Message     Varchar(80),
        --@Description Varchar(100),
		@RowId       VARCHAR(38),
		@EmailSubject Varchar(1000),
		@EmailBody   Varchar(max)


Set @EmailSubject = '<EmailSubject>'
Set @EmailBody = '<EmailBody>'

--Beginning Segment for Credit/Debit Adjustment

--Email Date
if rtrim(isnull(@BCD01, '')) <> ''
begin
  Set @Date = 'Email/Invoice Date: ' + rtrim(@BCD01) 
  Set @EmailBody = @EmailBody + @Date + '<br>'
end

SET @BCD02 = rtrim(isnull(@BCD02, ''))
SET @BCD05 = rtrim(isnull(@BCD05, ''))
SET @BCD05 = rtrim(isnull(@BCD07, ''))

-- Email Subject
Set @DocumentNo  = rtrim(isnull(@BCD02, '')) + ' ' + (case when @BCD05 = 'C' then ' (CREDIT)' when @BCD05 = 'D' then ' (DEBIT)' END) + ' ' + rtrim(isnull(@BCD07, '')) + ' (Document Rejected)'
Set @EmailSubject = @EmailSubject + @DocumentNo + '<br>'


--Vendor ID = N9
if rtrim(isnull(@N902, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' VENDOR ID = ' + rtrim(@N902) + '<br>'
end

-- SAC SERVICE PROMOTION ALLOWANCE CHARGE INFO
if rtrim(isnull(@SAC01, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' Allowance or Charge Indicator = ' + (case when @SAC01 = 'A' then ' ALLOWANCE' when @SAC01 = 'C' then ' CHARGE' END) + '<br>'
end

if rtrim(isnull(@SAC02, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' Code = ' + rtrim(@SAC02) + '<br>'
end

if rtrim(isnull(@SAC05, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' Code Amount = ' + rtrim(@SAC05) + '<br>'
end


--N1 Ship To
if rtrim(isnull(@N102, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' Ship To Name = ' + rtrim(@N102) + '<br>'
end

if rtrim(isnull(@N102, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' Ship To ID = ' + rtrim(@N104) + '<br>'
end


--(CDD) Credit/Debit Adjustment
if rtrim(isnull(@CDD01, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' Adjustment Reason Code = ' + rtrim(@CDD01)  + '<br>'
end

if rtrim(isnull(@CDD02, '')) <> '' 
begin
  SET @CreditDebitFlagCode = ' Credit/Debit Flage = ' + rtrim(@CDD02) + ' ' + 
  (case when rtrim(@CDD02) = 'C' then ' The supplier is expected to send an 
  810 credit invoice back to Rural King reflecting the credit changes. ' else ' ' END)
  Set @EmailBody = @EmailBody + ' ' +  @CreditDebitFlagCode  + '<br>'
end

if rtrim(isnull(@CDD07, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' # OF UNITS = ' + rtrim(@CDD07)  + '<br>'
end

if rtrim(isnull(@CDD08, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' UOM = ' + rtrim(@CDD08)  + '<br>'
end

if rtrim(isnull(@CDD11, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' PRICE = ' + rtrim(@CDD11)  + '<br>'
end


-- LIN Item Identification 
if rtrim(isnull(@LIN03, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' ITEM = ' + rtrim(@LIN03)  + '<br>'
end

-- N9 Extended Refrence ZZ 
if rtrim(isnull(@N902ZZ, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' Comments = ' + rtrim(@N902ZZ)  + '<br>'
end

-- N9 Extended Refrence L1 
if rtrim(isnull(@N902L1, '')) <> '' 
begin
  Set @EmailBody = @EmailBody + ' Comments = ' + rtrim(@N902L1)  + '<br>'
end

-- (SAC) Service, Promotion, Allowance, or Charge Information 
if rtrim(isnull(@SAC01Info, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' ' + (case when rtrim(@SAC01Info) = 'A' then ' ALLOWANCE' when rtrim(@SAC01Info) = 'C' then ' CHARGE' END) + '<br>'
end

if rtrim(isnull(@SAC02Info, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' CODE = ' + rtrim(@SAC02Info) + '<br>'
end

if rtrim(isnull(@SAC05Info, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' CODE AMOUNT = ' + rtrim(@SAC05Info) + '<br>'
end

if rtrim(isnull(@SAC15Info, '')) <> ''
begin
  Set @EmailBody = @EmailBody + ' CODE DESCRIPTION = ' + rtrim(@SAC15Info) + '<br>'
end



Set @EmailSubject = @EmailSubject + '</EmailSubject>'
Set @EmailBody = @EmailBody + '</EmailBody>'

SELECT @EmailSubject AS EMAILSUBJECT, @EmailBody AS EMAILBODY

----Populate ABERRORSHEADER
--Set @RowId = NewId()
--INSERT INTO ABERRORSHEADER (ROWID, COMPANYID, MODULE, RECORDTYPE, DESCRIPTION, COMMENT)
--VALUES (@RowId, 'GS', 'OM', 'R', 'RURAL KING EDI 824 ACTION', @EmailSubject + @EmailBody)

--<EmailBody>
--Email/Invoice Date: <br>
--VENDOR ID = 999990001<br>
--Allowance or Charge Indicator =  ALLOWANCE<br>
--Code = H850<br>
--Code Amount = 450<br>
--Ship To Name = RURALKING #99<br>
--Ship To ID = 99<br>
--Adjustment Reason Code = 01<br>
--Credit/Debit Flage = C  The supplier is expected to send an     810 credit invoice back to Rural King reflecting the credit changes. <br>
--# OF UNITS = 2<br>
--UOM = EA<br>
--PRICE = 1.25<br>
--ITEM = 801560001<br>
--Comments = BECAUSE<br>
--Comments = REASONS<br>
--ALLOWANCE<br>
--CODE = F050<br>
--CODE AMOUNT = 1.11<br>
--CODE DESCRIPTION = BLAH<br>
--</EmailBody>


*/