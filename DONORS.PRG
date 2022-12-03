#include "box.ch"
#include "keys.ch"
#include "values.ch"

*******************************************
PROCEDURE Donors_Menu

LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aDONOR_MENU[5]

DO WHILE cont
aDONOR_MENU[1] := "A. PRIVATE"
aDONOR_MENU[2] := "B. COMPANY"
aDONOR_MENU[3] := "C. TRUST"
aDONOR_MENU[4] := "D. REPORTS"
aDONOR_MENU[5] := "E. PREVIOUS MENU"
N_CHOICE := MCHOICE(m->aDONOR_MENU,7,23,15,55,"DONOR MENU",.t.)
IF LASTKEY() = 27
	cont := .F.
ENDIF
DO CASE
	CASE N_CHOICE = 1
		Donors_Browse("P")
	
	CASE N_CHOICE = 2
		Donors_Browse("C")
	
	CASE N_CHOICE = 3
		Donors_Browse("T")

	CASE N_CHOICE = 4
		Do_Reports()
		
	CASE N_CHOICE = 5
		cont := .F.

ENDCASE
ENDDO
RETURN

********************************************
PROCEDURE Donors_Browse
PARAMETERS Type

PRIVATE lEdit := .T., Browse := "DONORS"
PRIVATE adonflds[8], adondes[8], afldes[22]

USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE DONORS INDEX DONORS.01X, DONORS.02X, DONORS.03X, DONORS.04X EXCLUSIVE NEW
SET RELATION TO DONORS->C_Centre INTO PCKCENTRE
SELECT DONORS
aDonors := Donors->(DBSTRUCT())  && Get structure of donor database
SET DELETE ON
SET FILTER TO (DONORS->C_TYPE = TYPE) && only view type selected
GO TOP
Struct_Donor(Type, aDonors) && Load structure for type selected
SET ORDER TO 1
IF Type == "C" .OR. Type == "T"
	KEYBOARD CHR(4)   && Right arrow
ENDIF
EDITDB(lEdit, adonflds, adondes,.T.,Browse)
CLOSE DATABASES
RETURN

********************************************
PROCEDURE Add_Donor
PRIVATE box, x, aGet[DONORS->(FCOUNT())]

SET CURSOR ON
Fill_Get(aDonors,DONORS->(FCOUNT()))
&& Defaults
aGet[21] := .F.  && club 600
aGet[22] := .F.  && volunteer
&& Save screen & Create box to show info
box = MAKEBOX(3,1,21,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "ADD A NEW DONOR FOR " + ALLTRIM(Long_Centre)
@ 5,22  SAY REPLICATE(CHR(223),20 + LEN(ALLTRIM(Long_Centre)))  && Thick line
Get_Screen()
READ
IF LASTKEY() = 27
	SET CURSOR OFF
	RETURN
ENDIF
aGet[17] := Large_Num() && Get a new Donor No for this donor
aGet[19] := Type  && Get Type of Donor
aGet[18] := Centre  && Get the Centre where donor to be registered
APPEND BLANK
&& Write Get values to new record
FOR x = 1 TO DONORS->(FCOUNT())
	FIELDPUT(x,aGet[x])
NEXT x


UNBOX(m->box)
SET CURSOR OFF
RETURN
********************************************
PROCEDURE Remove_Donor
PRIVATE Donor_No := DONORS->N_Donnum, Rec := DONORS->(RECNO())
PRIVATE Dona_Rec
&& Scan donations for donations and remove
USE DONATION INDEX DONATION.01X,DONATION.02X,DONATION.03X,DONATION.04X ;
		EXCLUSIVE NEW 
SET FILTER TO (DONATION->(C_Centre == Centre))
DBGOTOP()
DO WHILE !EOF()
	IF DONATION->N_Donnum == Donor_No
		Dona_Rec := DONATION->(RECNO())
		USE DONADEL NEW
		APPEND RECORD Dona_Rec FROM DONATION
		CLOSE DONADEL
		SELECT DONATION
		DBDELETE()
	ENDIF
DBSKIP()
ENDDO
DBGOTOP()
PACK  && remove deleted records
CLOSE DONATION

&& Remove Donor record
USE DONDEL NEW
APPEND RECORD Rec FROM DONORS
CLOSE DONDEL
SELECT DONORS   && Select donors database again
DBDELETE()
IF !BOF()
	DBSKIP(-1)
ELSE
	DBSKIP()
ENDIF
PLSWAIT(.T.,"Please Wait - Busy Packing Database!")
PACK    && Remove deleted record
PLSWAIT(.F.)

RETURN
********************************************
PROCEDURE Move_Donor
&& Changes the donor type to another type
PARAMETERS Short_Type
LOCAL N_CHOICE := 1
PRIVATE Long_Type, aTYPE_MENU[3]
&& Expands the field to the description
IF Short_Type = "P"
	Long_Type := "Private"
ELSEIF Short_Type = "C"
	Long_Type := "Company"
ELSEIF Short_Type = "T"
	Long_Type := "Trust"
ELSE
	TONE(400,9)
	MSG("Unrecognized type!")
	RETURN
ENDIF

aTYPE_MENU[1] := "Private"
aTYPE_MENU[2] := "Company"
aTYPE_MENU[3] := "Trust"
&& Searches to see if the type in the current record matches a menu option
N_CHOICE := ASCAN(aTYPE_MENU,ALLTRIM(Long_Type))  
										&& Scans array to see if field already
										&& contains the choice. If found returns
										&& matching choice no
&& Displays menu with current type highlighted
N_CHOICE := MCHOICE(m->aTYPE_MENU,10,40,18,59,"TYPE",.t.,N_CHOICE)
&& Converts long description to short one to save to file
DO CASE
		CASE N_CHOICE = 1
			Short_Type := "P"
		CASE N_CHOICE = 2
			Short_Type := "C"
		CASE N_CHOICE = 3
			Short_Type := "T"
		OTHERWISE
			RETURN .F.
END CASE
&& Writes new type to file
IF Browse = "DONORS"
	DONORS->C_Type := Short_Type
ELSEIF Browse = "MEMBERS"
	MEMBERS->C_Type := Short_Type
ENDIF
DBSKIP(1)
RETURN
*********************************************
PROCEDURE Rem_Donation
PRIVATE Dona_Rec := DONATION->(RECNO())

USE DONADEL NEW
APPEND RECORD Dona_Rec FROM DONATION
CLOSE DONADEL
SELECT DONATION
DELETE
SKIP -1
SKIP 1

RETURN

*******************************************
PROCEDURE Print_Donor
LOCAL Total := 0, cType := DONORS->C_Type
IF !P_READY("LPT1")
	RETURN
ENDIF
PLSWAIT(.T.,"BUSY PRINTING")
SET DEVICE TO PRINTER
@ PROW(), PCOL() SAY CHR(18)  && Cancel compressed print if present
@ 3,32 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1) && Emp & underlined
@ PROW(), PCOL() SAY "DONORS DETAILS"
@ PROW(), PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0)
@ 5,10 SAY "Donor no : " + STR(DONORS->N_Donnum) + ;
		"   Centre: " + Expand_Centre(DONORS->C_Centre) + ;
		"   Type: " + Expand_Order(cType)

IF Type <> "P"
	@7,4 SAY "Company: " + DONORS->C_Surname
	@7,55 SAY "Title: " + DONORS->C_Title
	@ 8,4 SAY "Surname: " + DONORS->C_Surname2    && Surname2 used for surname
ELSE															 && in Company/Trusts
	@ 8,4  SAY "Surname: " + SUBSTR(LTRIM(DONORS->C_Surname),1,30)
ENDIF
@ 8,43 SAY "Salutation: " + ALLTRIM(DONORS->C_Salut)
@ 8,PCOL()+2 SAY DONORS->C_Initials
@10,4  SAY "Address: " + PROPER(DONORS->C_Address1)
@10,50 SAY "Tel: " + DONORS->C_Telcode
@11,13 SAY PROPER(DONORS->C_Address2)
@11,55 SAY DONORS->C_tel
@12,13 SAY DONORS->C_City
@12,55 SAY DONORS->C_Telext
@13,13 SAY DONORS->C_Postcode
@13,50 SAY "Fax: " + DONORS->C_Fax
@15,4  SAY "Club 600 member? " + IF(DONORS->L_C600==.T.,"Yes","No")
@15,40 SAY "Available as a volunteer? " + IF(DONORS->L_Volunt==.T.,"Yes","No")
@17,4  SAY "Newsletter? " + IF(DONORS->L_Newslett==.T.,"Yes","No")
@17,20 SAY "Annual Report? " + IF(DONORS->L_Annualrt==.T.,"Yes","No")
@17,40 SAY "Contact for further donations: " + ;
				IF(DONORS->L_Contdon==.T.,"Yes","No")
@18,4  SAY "Reason for no contact: " + IF(EMPTY(DONORS->C_Reason),"NONE", ;
				DONORS->C_Reason)
&& Cancel compressed printing
@ PROW(), PCOL() SAY CHR(18)
IF Browse = "DONATION"
	&& Select emphasised and underlined printing
	@ PROW() + 2,34 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1)
	@ PROW(),PCOL() SAY "DONATIONS"
	&& Select normal printing
	@ PROW(), PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0)
	&& Select compressed printing
	@ PROW(), PCOL() SAY CHR(27) + CHR(15)
	DONATION->(DBGOTOP())
	DO WHILE !EOF()
		@ PROW()+1,4 SAY "Date: " + DTOC(DONATION->D_Date)
		@ PROW(),19 SAY DONATION->C_Type
		@ PROW(),41 SAY DONATION->C_Event
		@ PROW(),101 SAY "R" + PADL(LTRIM(STR(DONATION->N_Amount)),10)
		@ PROW() + 1,4 SAY DONATION->C_Detail1
		@ PROW(), 30 SAY DONATION->C_Detail2
		@ PROW(), 55 SAY DONATION->C_Detail3
		@ PROW(), 80 SAY DONATION->C_Detail4
		@ PROW() + 1,4 SAY "Comments: " + IF(EMPTY(DONATION->C_Comments),"NONE", ;
						DONATION->C_Comments)
		@ PROW() +1,4 SAY REPLICATE("-",120)
		IF (PROW() >= 55)
			EJECT
			SET DEVICE TO SCREEN
			MSG(0,PADC("INSERT NEW PAPER",28), " ", ;
				PADC("PRESS ANY KEY TO CONTINUE",28), " ", ;
				PADC("OR 'C' TO CANCEL",28))
			IF (LASTKEY() = 67 .OR. LASTKEY() = 99)
				PLSWAIT(.F.)
				UNBOX(box)
				RETURN
			ENDIF
			SET DEVICE TO PRINTER
		ENDIF
		SKIP
	ENDDO
SUM DONATION->N_Amount TO Total
@ PROW() + 1, 95 SAY "TOTAL R" + PADL(LTRIM(STR(Total)),12)
ENDIF
EJECT
SET DEVICE TO SCREEN
PLSWAIT(.F.)

RETURN
*******************************************
FUNCTION Large_Num
&& This function checks highest value in record
PRIVATE largest := 0, cFilter := DBFILTER()  && Save current filter
SET FILTER TO                                && Remove filter to work
DBGOTOP()
DO WHILE !DONORS->(EOF())
	IF (DONORS->C_Centre == Centre)    && Only check donors for this centre
		largest := MAX(DONORS->N_Donnum, largest)  && Compare field to largest
	ENDIF
	DBSKIP()                           && Next record
ENDDO
SET FILTER TO &cFilter                && Restore filter condition
DBGOTOP()
largest := largest + 1
RETURN largest
********************************************
PROCEDURE Fill_Get
PARAMETERS aArray, noEls
LOCAL x

&& Fill aGet with default types for GET for Array just now
FOR x = 1 TO noEls
	IF aArray[x,2] = "C"
		aGet[x] := SPACE(aArray[x,3])
	ELSEIF aArray[x,2] = "N"
		aGet[x] := 0
	ELSEIF aArray[x,2] = "L"
		aGet[x] := .T.
	ELSEIF aArray[x,2] = "D"
		aGet[x] := DATE()
	ENDIF
NEXT x

RETURN
********************************************
PROCEDURE Get_Screen  && Screen layout for GETS for Donors & Members

IF Type <> "P"
	@ 7,4 SAY afldes[2] GET aGet[2] PICTURE "@!S32" COLOR "W+/N,N/W" VALID ;
				!EMPTY(aGet[2]) && Company or Trust
	@ 7,46 SAY afldes[11] GET aGet[11] PICTURE"@!S19" COLOR "W+/N,N/W" ;
				&& Title or position
	@ 8,4 SAY afldes[1] GET aGet[1] PICTURE "@!S23" COLOR "W+/N,N/W"
				&& Surname for Company/Trusts
	@ 8,43 SAY afldes[12] GET aGet[12] PICTURE "@!" COLOR "W+/N,N/W" ;
		VALID (EMPTY(aGet[12]) .OR. Check_Salutation(aGet[12])) 
				&& Salutation
ELSE
	@ 8,4 SAY afldes[2] GET aGet[2] PICTURE "@!S23" COLOR "W+/N,N/W" VALID ;
				!EMPTY(aGet[2]) && Surname
	@ 8,43 SAY afldes[12] GET aGet[12] PICTURE "@!" COLOR "W+/N,N/W" ;
			VALID Check_Salutation(aGet[12]) && Salutation
ENDIF
@ 8,64 SAY afldes[3] GET aGet[3] PICTURE "@!A" COLOR "W+/N,N/W" && Initials
@ 9,1 SAY CHR(199) + REPLICATE(CHR(196),76) + CHR(182) && Line
@ 10,4 SAY afldes[4] GET aGet[4] PICTURE "@!" COLOR "W+/N,N/W" && Address1
@ 11,4 SAY afldes[5] GET aGet[5] PICTURE "@!" COLOR "W+/N,N/W" ;
		WHEN !EMPTY(aGet[4]) && Address2
@ 12,4 SAY afldes[6] GET aGet[6] PICTURE "@!" COLOR "W+/N,N/W" ;
		WHEN !EMPTY(aGet[4]) && City
@ 12,45 SAY afldes[7] GET aGet[7] PICTURE "9999" COLOR "W+/N,N/W" ;
		WHEN !EMPTY(aGet[4]) VALID (EMPTY(aGet[7]) .OR. Check_Code(aGet[7])) 
		&& Postal Code
@ 13,4 SAY afldes[8] GET aGet[8]  PICTURE "99999" COLOR "W+/N,N/W" && Tel Code
@ 13,22 SAY afldes[9] GET aGet[9] PICTURE "9999999" COLOR "W+/N,N/W" && Tel
@ 13,37 SAY afldes[10] GET aGet[10] PICTURE "99999" COLOR "W+/N,N/W" ;
			WHEN !EMPTY(aGet[9]) && Tel ext
@ 13,52 SAY afldes[20] GET aGet[20] PICTURE "9999999" COLOR "W+/N,N/W" && Fax
@ 14,1 SAY CHR(199) + REPLICATE(CHR(196),76) + CHR(182) && Line
@ 15,4 SAY afldes[21] GET aGet[21] PICTURE "Y" COLOR "W+/N,N/W" && Club 600
@ 15,45 SAY afldes[22] GET aGet[22] PICTURE "Y" COLOR "W+/N,N/W" && Volunteer
@ 16,4 SAY afldes[13] GET aGet[13] PICTURE "Y" COLOR "W+/N,N/W" && Newsletter
@ 16,25 SAY afldes[14] GET aGet[14] PICTURE "Y" COLOR "W+/N,N/W" ;
				&& Annual report
@ 16,45 SAY afldes[15] GET aGet[15] PICTURE "Y" COLOR "W+/N,N/W" ;
				&& Contact for Donation?
@ 17,4 SAY afldes[16] GET aGet[16] PICTURE "@!" COLOR "W+/N,N/W" ;
				WHEN aGet[15]=.F.    && If no contact

IF Browse = "MEMBERS"
@ 18,4 SAY afldes[17] GET aGet[17] PICTURE "@! A999/9999" COLOR "W+/N,N/W" ;
			WHEN { |oGet| Get_NewMemNo(oGet, aGet[2]) }
@ 18,35 SAY afldes[31] GET aGet[31] PICTURE "@! AN" COLOR "W+/N,N/W" ;
			VALID { |oGet| Get_MemType(oGet) } && Member Type
@ 18,50 SAY afldes[23] GET aGet[23] PICTURE "Y" COLOR "W+/N,N/W"
@ 19,4 SAY afldes[32] GET aGet[32] PICTURE "@! A" COLOR "W+/N,N/W" ;
			VALID Check_Centre(aGet[32])	&& Get centre member is booked for
@ 20,4 SAY afldes[24] GET aGet[24] PICTURE "99.99" COLOR "W+/N,N/W" ;
			WHEN { |oGet| Get_Subs(oGet, aGet[31]) }   && subs
@ 20,20 SAY afldes[25] GET aGet[25] PICTURE "99.99" COLOR "W+/N,N/W" ;
        WHEN { |oGet|  Get_Vat(oGet,aGet[24]) }
@ 20,35 SAY afldes[27] GET aGet[27] PICTURE "999.99" COLOR "W+/N,N/W"
@ 20,50 SAY afldes[26] GET aGet[26]	PICTURE "999.99" COLOR "W+/N,N/W" ;
        WHEN { |oGet| Get_Total(oGet,aGet[24],aGet[27]) }
@ 20,65 SAY afldes[33] GET aGet[33] PICTURE "L" COLOR "W+/N,N/W" && Paid?
@ 21,4 SAY afldes[28] GET aGet[28] COLOR "W+/N,N/W" VALID (aGet[28] <= DATE())
			&& Date paid
@ 21,27 SAY afldes[29] GET aGet[29] PICTURE "@!" COLOR "W+/N,N/W" ;
			WHEN (!EMPTY(aGet[28]))  && Receipt
@ 21,43 SAY afldes[30] GET aGet[30] PICTURE "9999.99" COLOR "W+/N,N/W" ;
			WHEN (!EMPTY(aGet[28])) VALID (aGet[30] >=0)  && Amount paid
@ 21,61 SAY afldes[34] GET aGet[34] PICTURE "999.99" COLOR "W+/N,N/W" ;
			&& Donation

ENDIF

RETURN
********************************************
FUNCTION Check_Centre
PARAMETERS Centre_Code
&& To check if centre code exists

SELECT PCKCENTRE
SEEK Centre_Code
IF PCKCENTRE->(FOUND())  && Is there a matching record for centre in relation?
	@ 19,17 SAY PADR(PCKCENTRE->C_Desc,20," ")
	SELECT MEMBERS
	RETURN .T.
ELSE
	@ 19,17 SAY PADR("CODE NOT FOUND",20," ")
	SELECT MEMBERS
	RETURN .F.
ENDIF



RETURN .F.
********************************************
/*FUNCTION Get_MemCent
PARAMETERS oGet
PRIVATE cCentre := oGet:varGet(), OldArea := SELECT()


IF (SELECT("PCKCENTRE") <> 0)
	SELECT SELECT("PCKCENTRE")
ELSE
	USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
ENDIF
SEEK cCentre
IF FOUND()
	cCentre := PCKCENTRE->C_Centre
ELSE
	&& Procedure to select centre
ENDIF
CLOSE PCKCENTRE

oGet:varPut( cCentre )
SELECT ( OldArea )
RETURN .F.
*/
*******************************************
FUNCTION Get_Subs
PARAMETERS oGet, Mem_Code
PRIVATE nSubs := oGet:varGet(), OldArea := SELECT()


IF (SELECT("PCKSUBS") <> 0)
	SELECT SELECT("PCKSUBS")
ELSE
	USE PCKSUBS INDEX PCKSUBS.01X EXCLUSIVE NEW
ENDIF
SEEK Mem_Code
IF FOUND()
	nSubs := PCKSUBS->N_Subs
ELSE
	TONE(400,12)
	MSG("MAY STILL HAVE TO EDIT MEMBERSHIP SUBS")
ENDIF
CLOSE PCKSUBS

oGet:varPut( nSubs )
SELECT ( OldArea )
RETURN .F.
********************************************
FUNCTION Get_MemType
PARAMETERS oGet
LOCAL N_CHOICE := 0
PRIVATE Mem_Type, aMEM_MENU[9]

Mem_Type := oGet:varGet()

Mem_Type := Expand_MemType( Mem_Type )

aMEM_MENU[1] := "Parent Single"
aMEM_MENU[2] := "Parent Double"
aMEM_MENU[3] := "Staff Single"
aMEM_MENU[4] := "Staff Double"
aMEM_MENU[5] := "Ordinary Single"
aMEM_MENU[6] := "Ordinary Double"
aMEM_MENU[7] := "Company"
aMEM_MENU[8] := "Honorary"
aMEM_MENU[9] := "Mentally Handicap"
SET EXACT ON
N_CHOICE := ASCAN(aMEM_MENU,ALLTRIM(Mem_Type))  
										&& Scans array to see if field already
										&& contains the choice. If found returns
										&& matching choice no 
IF N_CHOICE = 0               && No match
	N_CHOICE := MCHOICE(m->aMEM_MENU,10,40,18,59,"MEMBER TYPE",.t.,N_CHOICE)
ENDIF
	DO CASE
		CASE N_CHOICE = 1
			Mem_Type := "P1"
		CASE N_CHOICE = 2
			Mem_Type := "P2"
		CASE N_CHOICE = 3
			Mem_Type := "S1"
		CASE N_CHOICE = 4
			Mem_Type := "S2"
		CASE N_CHOICE = 5
			Mem_Type := "M1"
		CASE N_CHOICE = 6
			Mem_Type := "M2"
		CASE N_CHOICE = 7
			Mem_Type := "C "
		CASE N_CHOICE = 8
			Mem_Type := "H "
		CASE N_CHOICE = 9
			Mem_Type := "MH"
		OTHERWISE
			RETURN .F.
	END CASE

oGet:varPut( Mem_Type )

RETURN .T.
*******************************************
FUNCTION Expand_MemType
PARAMETERS Mem_Type

&& Convert type to description for searching array
	DO CASE
		CASE Mem_Type == "P1"
			Mem_Type := "Parent Single"
		CASE Mem_Type == "P2"
			Mem_Type := "Parent Double"
		CASE Mem_Type == "S1"
			Mem_Type := "Staff Single"
		CASE Mem_Type == "S2"
			Mem_Type := "Staff Double"
		CASE Mem_Type == "M1"
			Mem_Type := "Ordinary Single"
		CASE Mem_Type == "M2"
			Mem_Type := "Ordinary Double"
		CASE Mem_Type == "C "
			Mem_Type := "Company"
		CASE Mem_Type == "H "
			Mem_Type := "Honorary"
		CASE Mem_Type == "MH"
			Mem_Type := "Mentally Handicap"
	END CASE

RETURN Mem_Type
******************************************
FUNCTION Get_NewMemNo  && This function checks highest memno value in record
PARAMETERS oGet, Surname
PRIVATE Memno := "", FirstLet := SUBSTR(Surname,1,1), WholeCode := ""
PRIVATE largest := 0, cFilter := DBFILTER(), nRecno := RECNO()  && Save current filter

IF EMPTY(SUBSTR(oGet:varGet(),1,4))  && Only gets if first four letters empty
	&& Set filter to only work on members with same first letter in surname
	SET FILTER TO (SUBSTR(MEMBERS->C_Surname,1,1)==FirstLet)
	DBGOTOP()
	DO WHILE !MEMBERS->(EOF())
		IF (MEMBERS->C_Centre == Centre)    && Only check donors for this centre
			largest := MAX(VAL(SUBSTR(MEMBERS->C_Memcode,2,3)), largest)  && Compare field to largest
		ENDIF
		DBSKIP()                           && Next record
	ENDDO
	SET FILTER TO &cFilter                && Restore filter condition
	DBGOTO(nRecno)
	largest := largest + 1
	IF largest > 999
		MSG("ERROR - MEMBER NO GREATER THAN 999")
		QUIT
	ENDIF
	&& Convert number back to string
	Memno := PADL(LTRIM(STR(largest)),3,"0")

	WholeCode := FirstLet + Memno + "/" + LTRIM(STR(YEAR(DATE())))

	oGet:varPut( WholeCode)
ENDIF

RETURN .F.
********************************************
FUNCTION Get_Total
PARAMETERS oGet, No1, No2
LOCAL Total

Total := No1 + No2
oGet:varPut( Total )
RETURN .F.
********************************************
FUNCTION Get_Vat
PARAMETERS oGet, Amount

LOCAL Vat_Rate, Vat, nOldArea, Temp
&& Save current work area
nOldArea := SELECT()
&& Open code file to get current VAT rate
USE PCKVAT EXCLUSIVE NEW
DBGOTOP()
Vat_Rate := PCKVAT->N_VAT
CLOSE PCKVAT

&& Restore old work area
SELECT (nOldArea)
Temp := 1 + (Vat_Rate/100)
Vat := Amount - (Amount/Temp)
oGet:varPut( Vat )

RETURN .F.
*******************************************
FUNCTION Check_Code
PARAMETERS code

&& Checks if all characters are numeric
IF LASTKEY() = pUP_ARROW .OR. LASTKEY() = pDOWN_ARROW
	RETURN .T.
ELSE
	FOR x := 1 TO 4
		IF ((ASC(SUBSTR(code,x,1)) < 48) .OR. (ASC(SUBSTR(code,x,1)) > 57))
			RETURN .F.
		ENDIF
	NEXT x
ENDIF
RETURN .T.
********************************************
PROCEDURE Edit_Donor
PRIVATE box, x, aGet[DONORS->(FCOUNT())]

SET CURSOR ON
Fill_Get(aDonors,DONORS->(FCOUNT()))
FOR x := 1 TO DONORS->(FCOUNT())
	aGet[x] := FIELDGET(x)
NEXT x

&& Save screen & Create box to show info
box = MAKEBOX(3,1,21,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "EDIT A DONOR FOR " + ALLTRIM(Long_Centre)
@ 5,22  SAY REPLICATE(CHR(223),17 + LEN(ALLTRIM(Long_Centre)))  && Thick line
Get_Screen()
READ
IF LASTKEY() = 27
	SET CURSOR OFF
	RETURN
ENDIF
IF AUPDATED(aGet)
	IF MESSYN("Save Changes To File?","Yes","No")
		&& Write Get values to new record
		ARRAY2DBF(aGet)
	ENDIF
ENDIF
UNBOX(m->box)
SET CURSOR OFF
RETURN
*******************************************
PROCEDURE Struct_Donor
PARAMETERS Type, aArray
LOCAL x

	&& Create adonflds array to hold field names for browse
	FOR x = 1 TO 6
		adonflds[x] := aArray[x,1]
	NEXT x
	adonflds[7] := "PCKCENTRE->C_Desc"  && aArray[18,1]  Related description
	&& Add member no + Paid for member's browse, or donor no for donors
	IF Browse = "MEMBERS"
		adonflds[8] := "MEMBERS->C_Memcode"
		adonflds[9] := "MEMBERS->L_Paid"
	ELSE
		adonflds[8] := "DONORS->N_donnum"
	ENDIF
	&& Create descriptions for use in browse and GETS
	IF Type = "P"
		afldes[1] := "COMPANY"
		afldes[2] := "SURNAME"
	ELSEIF Type = "C"
		afldes[1] := "CONTACT SURNAME"
		afldes[2] := "COMPANY"
	ELSEIF Type = "T"
		afldes[1] := "CONTACT SURNAME"
		afldes[2] := "TRUST"
	ENDIF
	afldes[3] := "INITIALS"
	afldes[4] := "ADDRESS 1"
	afldes[5] := "ADDRESS 2"
	afldes[6] := "CITY"
	afldes[7] := "POSTAL CODE"
	afldes[8] := "TEL CODE"
	afldes[9] := "TEL NO"
	afldes[10]:= "TEL EXT"
	afldes[11]:= "JOB TITLE"
	afldes[12]:= "SALUTATION"
	afldes[13]:= "NEWSLETTER?"
	afldes[14]:= "ANNUAL REPORT?"
	afldes[15]:= "CONTACT FOR DONATION?"
	afldes[16]:= "REASON"
	IF Browse = "DONORS"
		afldes[17]:= "DONOR NO"
	ELSEIF Browse = "MEMBERS"
		afldes[17] := "MEMBERSHIP NO"
	ENDIF
	afldes[18]:= "CENTRE"
	afldes[19]:= "TYPE"
	afldes[20]:= "FAX NO"
	afldes[21]:= "CLUB 600 MEMBER?"
	afldes[22]:= "AVAILABLE AS VOLUNTEER?"
	IF Browse = "MEMBERS"
		afldes[23] := "STOP ORDER?"
		afldes[24] := "SUBS"
		afldes[25] := "VAT"
		afldes[26] := "TOTAL"
		afldes[27] := "ARREARS"
		afldes[28] := "DATE PAID"
		afldes[29] := "RECEIPT"
		afldes[30] := "AMOUNT PD"
		afldes[31] := "MEMBER TYPE"
		afldes[32] := "BOOKED FOR"
		afldes[33] := "PAID?"
		afldes[34] := "DONATION"
	ENDIF
	&& Create adondes array of descriptions for browse
	ACOPY(afldes,adondes,1,6,1)
	adondes[7] := afldes[18]
	adondes[8] := afldes[17]
	IF Browse = "MEMBERS"
		adondes[9] := afldes[33]
	ENDIF
IF Type = "P"
	&& Move elements one down in array so as not to
	&& display company field for personal donors in browse
	FOR x := 1 TO LEN(adonflds)-1
		adonflds[x] := adonflds[x+1]
		adondes[x] := adondes[x+1]
	NEXT x
	
	&& Resize arrays for browse
	ASIZE(adonflds,LEN(adonflds)-1)
	ASIZE(adondes,LEN(adondes)-1)
ENDIF
RETURN
********************************************
