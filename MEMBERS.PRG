#include "box.ch"
#include "keys.ch"
#include "values.ch"

*******************************************
PROCEDURE Members_Menu

LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aMEM_MENU[5]

DO WHILE cont
aMEM_MENU[1] := "A. PRIVATE"
aMEM_MENU[2] := "B. COMPANY"
aMEM_MENU[3] := "C. TRUST"
aMEM_MENU[4] := "D. REPORTS"
aMEM_MENU[5] := "E. PREVIOUS MENU"
N_CHOICE := MCHOICE(m->aMEM_MENU,7,23,15,55,"MEMBER MENU",.t.)
IF LASTKEY() = 27
	cont := .F.
ENDIF
DO CASE
	CASE N_CHOICE = 1
		Members_Browse("P")
	
	CASE N_CHOICE = 2
		Members_Browse("C")
	
	CASE N_CHOICE = 3
		Members_Browse("T")

	CASE N_CHOICE = 4
		Mem_Reports()
		
	CASE N_CHOICE = 5
		cont := .F.
ENDCASE
ENDDO

RETURN

********************************************
PROCEDURE Members_Browse

PARAMETERS Type
PRIVATE lEdit := .T., Browse := "MEMBERS"
PRIVATE adonflds[9], adondes[9], afldes[34]

USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE PCKSUBS INDEX PCKSUBS.01X EXCLUSIVE NEW
USE MEMBERS INDEX MEMBERS.01X, MEMBERS.02X, MEMBERS.03X, MEMBERS.04X, ;
	MEMBERS.05X  EXCLUSIVE NEW
SET RELATION TO MEMBERS->C_Centre INTO PCKCENTRE
SELECT MEMBERS
aMembers := Members->(DBSTRUCT())  && Get structure of member database
SET DELETE ON
SET FILTER TO (MEMBERS->C_TYPE = TYPE) && only view type selected
GO TOP
Struct_Donors(Type,aMembers) && Load structure for type selected
SET ORDER TO 1  && Surname order
EDITDB(lEdit, adonflds, adondes,.T.,Browse) && Don't show company name
CLOSE DATABASES
RETURN

********************************************
PROCEDURE Add_Member
PRIVATE box, x, aGet[MEMBERS->(FCOUNT())]

SET CURSOR ON
Fill_Get(aMembers,MEMBERS->(FCOUNT()))
&& Defaults
aGet[21] := .F.  && club 600
aGet[22] := .F.  && volunteer
aGet[23] := .F.  && stop order
aGet[28] := CTOD("") && No date for payment yet
aGet[32] := Centre && default to current centre for new
&& Save screen & Create box to show info
box = MAKEBOX(3,1,22,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "ADD A NEW MEMBER FOR " + ALLTRIM(Long_Centre)
@ 5,22  SAY REPLICATE(CHR(223),21 + LEN(ALLTRIM(Long_Centre)))  && Thick line
Get_Screen()
READ
IF LASTKEY() = 27
	SET CURSOR OFF
	RETURN
ENDIF
aGet[19] := Type  && Get Type of Donor
aGet[18] := Centre  && Get the Centre where donor to be registered
APPEND BLANK
&& Write Get values to new record
FOR x = 1 TO MEMBERS->(FCOUNT())
	FIELDPUT(x,aGet[x])
NEXT x


UNBOX(m->box)
SET CURSOR OFF
RETURN
********************************************
PROCEDURE Remove_Member
PRIVATE MemRec := MEMBERS->(RECNO())

USE MEMDEL EXCLUSIVE NEW
APPEND RECORD MemRec FROM MEMBERS
CLOSE MEMDEL
SELECT MEMBERS
DBDELETE()
IF !BOF()
	DBSKIP(-1)
ELSE
	DBSKIP()
ENDIF

PACK    && Remove deleted record

RETURN
********************************************
PROCEDURE Mem_Reports

LOCAL cWhere := "P"
PRIVATE aFields, aFdesc, aType, Heading := "MEMBERS QUERY", cOrder := "Q"

aFields := { "C_Surname2","C_Surname","C_Salut","C_Initials","C_Address1",;
				 "C_Address2","C_City","C_Postcode","L_Newslett","L_Annualrt",;
				 "L_Contdon","L_C600","L_Volunt","C_Centre","C_Type","L_Stopord",;
				 "N_Subs","N_Vat","N_Total","N_Arrears","D_Datpaid","C_Receipt",;
				 "N_Amtpaid","C_Memtype","C_MemCent","L_Paid","N_Donation" }
aFdesc := { "Contact Surname","Surname/Company","Salutation","Initials",;
				"Address1","Address2","City","Postal Code","Newsletter?",;
				"Annual Report?","Contact for Donation?","Club 600?","Volunteer?",;
				 "Centre","Donor Type C/T/P","Stop Order?","Subs","VAT",;
				 "Total Owed","Arrears","Date Paid","Receipt No","Amount Paid",;
				 "Member Code P1,S2,etc","Booked at Centre","Paid?","Donation" }
aType := { "C","C","C","C","C","C","C","C","L","L","L","L","L","C","C",;
				"L","N","N","N","N","D","C","N","C","C","L","N" }

USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE MEMBERS INDEX MEMBERS.01X,MEMBERS.02X, MEMBERS.03X, MEMBERS.04X, MEMBERS.05X ;
		EXCLUSIVE NEW
SET RELATION TO MEMBERS->C_Memcent INTO PCKCENTRE
Filt := QUERY(aFields,aFdesc,aType,"to Print",.T.)
SET FILTER TO &Filt
DBGOTOP()
box := MAKEBOX(7,11,14,72,sls_popcol(),sls_shadpos())
@ 9,28 SAY Heading
@ 11,14 SAY "TO PRINTER, MAILMERGE, LABELS, SCREEN OR WP(P/M/L/S/W)" GET cWhere PICTURE "@!" ;
	COLOR "W+/N,N/W" VALID (cWhere = "P" .OR. cWhere = "M" .OR. cWhere="S" .OR. ;
	cWhere = "L" .OR. cWhere = "W")
READ
UNBOX(box)
IF LASTKEY() = 27
	CLOSE DATABASES
	RETURN
ENDIF
IF cWhere = "P"
	SET ORDER TO 1
	Mem_Printout()
ELSEIF cWhere = "M"
	PLSWAIT(.T.,"BUSY EXPORTING TO MAILMERGE.DBF")
	SET ORDER TO 5
	COPY FIELDS C_Surname2, C_Surname, C_Initials, C_Salut, ;
			PROPER(C_Title), PROPER(C_Address1), PROPER(C_Address2), C_City, ;
			C_Postcode, N_Subs, N_VAT, N_Arrears,;
			N_Total, D_Datpaid, N_Amtpaid, C_Receipt, C_MemCent, L_Paid, N_Donation ;
			TO MAILMERGE
	PLSWAIT(.F.)
	SET ORDER TO 1
ELSEIF cWhere = "S"
	EDITDB(.F., aFields, aFdesc,.T.,"QUERY RESULT")
ELSEIF cWhere = "L"
	IF P_READY("LPT1")
		SET DEVICE TO PRINTER
		&& Set condenced printing
		@ PROW(), PCOL() SAY CHR(27) + CHR(15)
		SET DEVICE TO SCREEN
		CLABEL(aFields,aFdesc,aType)
	ELSE
		TONE(400,9)
		MSG("MAKE SURE PRINTER IS ONLINE")
	ENDIF
ELSEIF cWhere = "W"
	SMAILMERGE()
ENDIF
CLOSE DATABASES

RETURN
*******************************************
PROCEDURE Mem_Printout


	IF !P_READY("LPT1")
		UNBOX(box)
		CLOSE DATABASES
		RETURN
	ENDIF
	PLSWAIT(.T.,"BUSY PRINTING")
	SET DEVICE TO PRINTER
	&& Turn on emphasised & underlined print
	@ PROW(),15 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1)
	@ PROW(),PCOL() SAY Heading
	&& Back to normal printing
	@ PROW(),PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0)
	&& Select compressed printing
	@ PROW()+1,1 SAY CHR(27) + CHR(15)
	@ PROW(),PCOL() SAY "Company/Surname         Type/Initial    Address               City           P/Code  Mem No/Code   Subs Arrear VAT    Total Date  & Amt Pd  Receipt  Centre        Pd  Donation"
	DO WHILE !EOF()
		@ PROW()+1,2 SAY TRIM(PROPER(SUBSTR(C_Surname,1,25)))
		IF (MEMBERS->C_Type = "P")
			@ PROW(),PCOL() + 1 SAY TRIM(PROPER(MEMBERS->C_salut))+" "+MEMBERS->C_Initials
		ELSEIF (MEMBERS->C_Type = "C")
			@ PROW(),35 SAY "COMP"
		ELSEIF (MEMBERS->C_Type = "T")
			@ PROW(),35 SAY "TRUST"
		ENDIF
		@ PROW(),41 SAY PROPER(SUBSTR(C_Address1,1,20))
		@ PROW(),63 SAY SUBSTR(C_City,1,16)
		@ PROW(),80 SAY C_Postcode
		@ PROW(),85 SAY C_memcode
		@ PROW(),95 SAY C_memtype
		@ PROW(),99 SAY "R"+LTRIM(STR(N_subs))
		@ PROW(),106 SAY "R"+LTRIM(STR(N_Arrears))
      @ PROW(),112 SAY "R"+LTRIM(STR(N_vat))
		@ PROW(),119 SAY "R"+LTRIM(STR(N_Total))
		@ PROW(),126 SAY DTOC(D_Datpaid)
		@ PROW(),136 SAY "R"+LTRIM(STR(N_Amtpaid))
		@ PROW(),142 SAY TRIM(C_receipt)
		@ PROW(),149 SAY ALLTRIM(PCKCENTRE->C_Desc)
		@ PROW(),165 SAY L_Paid
		@ PROW(),169 SAY "R" + LTRIM(STR(N_Donation))
		IF (PROW() >= 56)
			CHR(7)
			EJECT
			SET DEVICE TO SCREEN
			MSG(0,PADC("INSERT NEW PAPER",28), " ", ;
					PADC("PRESS ANY KEY TO CONTINUE",28), " ", ;
					PADC("OR 'C' TO CANCEL",28))
			IF (LASTKEY() = 67 .OR. LASTKEY() = 99)
				PLSWAIT(.F.)
				RETURN
			ENDIF
			SET DEVICE TO PRINTER
		ENDIF
		SKIP
	ENDDO
	@ PROW() + 2, 2 SAY "QUERY = " + Filt    && Print query string
	@ PROW(), PCOL() SAY CHR(18) && Normal size printing
	EJECT
	SET DEVICE TO SCREEN
	PLSWAIT(.F.)


RETURN
*******************************************
PROCEDURE Print_Member
LOCAL Total := 0, cType := MEMBERS->C_Type
IF !P_READY("LPT1")
	RETURN
ENDIF
PLSWAIT(.T.,"BUSY PRINTING")
SET DEVICE TO PRINTER
@ PROW(), PCOL() SAY CHR(18)  && Cancel compressed print if present
@ 3,32 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1) && Emp & underlined
@ PROW(), PCOL() SAY "MEMBER DETAILS"
@ PROW(), PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0)
@ 5,4 SAY "Membership no : " + MEMBERS->C_Memcode + ;
		"   Centre: " + Expand_Centre(MEMBERS->C_Centre) + "   Type: " + Expand_Order(cType)
IF Type =  "C"
	@7,4 SAY "Company: " + MEMBERS->C_Surname
	@7,54 SAY "Title: " + PROPER(MEMBERS->C_Title)
	@ 8,4  SAY "Surname: " + MEMBERS->C_Surname2
ELSEIF Type = "T"
	@7,4 SAY "Trust: " + MEMBERS->C_Surname
	@7,59 SAY "Title: " + PROPER(MEMBERS->C_Title)
	@ 8,4  SAY "Surname: " + MEMBERS->C_Surname2
ELSEIF Type = "P"
	@ 8,4  SAY "Surname: " + MEMBERS->C_Surname
ENDIF

@ 8,43 SAY "Salutation: " + MEMBERS->C_Salut
@ 8,66 SAY MEMBERS->C_Initials
@10,4  SAY "Address: " + PROPER(MEMBERS->C_Address1)
@10,50 SAY "Tel: " + MEMBERS->C_Telcode
@11,13 SAY PROPER(MEMBERS->C_Address2)
@11,55 SAY MEMBERS->C_tel
@12,13 SAY MEMBERS->C_City
@12,55 SAY MEMBERS->C_Telext
@13,13 SAY MEMBERS->C_Postcode
@13,50 SAY "Fax: " + MEMBERS->C_Fax
@15,4  SAY "Club 600 member? " + IF(MEMBERS->L_C600==.T.,"Yes","No")
@16,40 SAY "Available as a volunteer? " + IF(MEMBERS->L_Volunt==.T.,"Yes","No")
@17,4  SAY "Newsletter? " + IF(MEMBERS->L_Newslett==.T.,"Yes","No")
@18,4 SAY "Annual Report? " + IF(MEMBERS->L_Annualrt==.T.,"Yes","No")
@19,4 SAY "Contact for further donations: " ;
				+ IF(MEMBERS->L_Contdon==.T.,"Yes","No")
@20,4  SAY "Reason for no contact: " + IF(EMPTY(MEMBERS->C_Reason),"NONE", ;
				MEMBERS->C_Reason)
@21,4  SAY "Member Type: " + Expand_MemType(MEMBERS->C_Memtype)
@21,50 SAY "SUBS:     R" + PADL(LTRIM(STR(MEMBERS->N_Subs)),8)
@22,4  SAY "Stop Order?: " + IF(MEMBERS->L_StopOrd,"Yes","No")
@22,50 SAY "VAT:      R" + PADL(LTRIM(STR(MEMBERS->N_Vat)),8)
@23,4  SAY "Last Date Paid: " + DTOC(MEMBERS->D_Datpaid)
@23,50 SAY "Arrears:  R" + PADL(LTRIM(STR(MEMBERS->N_Arrears)),8)
@24,4  SAY "Receipt no: " + MEMBERS->C_Receipt
@24,50 SAY "Total:    R" + PADL(LTRIM(STR(MEMBERS->N_Total)),8)
@25,4  SAY "Last Payment Amount: R" + LTRIM(STR(MEMBERS->N_Amtpaid))
@25,50 SAY "Booked at: " + ALLTRIM(PCKCENTRE->C_Desc)
@26,4  SAY "Paid?      " + IF(MEMBERS->L_Paid,"Yes","No")
@26,50 SAY "Donation: R" + PADL(LTRIM(STR(MEMBERS->N_Donation)),8)
&& Cancel compressed printing
@ PROW(), PCOL() SAY CHR(18)
EJECT
SET DEVICE TO SCREEN
PLSWAIT(.F.)

RETURN
*******************************************
FUNCTION NewMem_Num
&& This function gets a new membership number
PRIVATE largest := 0, cFilter := DBFILTER()  && Save current filter
SET FILTER TO                                && Remove filter to work
DBGOTOP()
DO WHILE !MEMBERS->(EOF())
	IF (MEMBERS->C_Centre == Centre)    && Only check donors for this centre
		largest := MAX(MEMBERS->C_Memcode, largest)  && Compare field to largest
	ENDIF
	DBSKIP()                           && Next record
ENDDO
SET FILTER TO &cFilter                && Restore filter condition
DBGOTOP()
largest := largest + 1
RETURN largest
********************************************
PROCEDURE Edit_Member
PRIVATE box, x, aGet[MEMBERS->(FCOUNT())]

SET CURSOR ON
Fill_Get(aMembers,MEMBERS->(FCOUNT()))
FOR x := 1 TO MEMBERS->(FCOUNT())
	aGet[x] := FIELDGET(x)
NEXT x

&& Save screen & Create box to show info
box = MAKEBOX(3,1,22,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "EDIT A MEMBER FOR " + ALLTRIM(Long_Centre)
@ 5,22  SAY REPLICATE(CHR(223),18 + LEN(ALLTRIM(Long_Centre)))  && Thick line
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
