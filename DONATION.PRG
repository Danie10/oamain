#include "box.ch"
#include "keys.ch"
#include "values.ch"
*******************************************
PROCEDURE Get_DonScr    && Screen layout for GETS for donations

@ 8,7 SAY adonatdes[3] GET aGet[3] COLOR "W+/N,N/W" ;
			VALID { |oGet| Check_Date(oGet)}  && Date
@ 10,7 SAY adonatdes[4] GET aGet[4] PICTURE "@!" COLOR "W+/N,N/W" ;
			VALID Check_Type(aGet[4]) && Type
@ 12,7 SAY adonatdes[5] GET aGet[5] PICTURE "9999999.99" COLOR "W+/N,N/W" ;
			WHEN aGet[4] = "MONEY" && Amount if type is money
@ 14,7 SAY adonatdes[6] GET aGet[6] PICTURE "@!" COLOR "W+/N,N/W" ;
			VALID Check_Event(aGet[6]) && Event
@ 16,7 SAY adonatdes[7] GET aGet[7] PICTURE "@!" COLOR "W+/N,N/W" && Detail 1
@ 16,45 SAY adonatdes[8] GET aGet[8] PICTURE "@!" COLOR "W+/N,N/W" && Detail 2
@ 17,7 SAY adonatdes[9] GET aGet[9] PICTURE "@!" COLOR "W+/N,N/W" && Detail 3
@ 17,45 SAY adonatdes[10] GET aGet[10] PICTURE "@!" COLOR "W+/N,N/W" &&Detail 4
@ 19,7 SAY adonatdes[11] GET aGet[11] PICTURE "@!" COLOR "W+/N,N/W" && Comments

RETURN
********************************************
FUNCTION Check_Date
PARAMETERS oGet
PRIVATE Date

IF EMPTY(oGet:varGet())
	Date := Date()
ELSE
	Date := oGet:varGet()
ENDIF

&& aGet[3] := POPVDATE(Date,.t.,"Select Date")
Date := POPVDATE(Date,.t.,"Select Date")

oGet:varPut( Date )

RETURN .T.
*******************************************
FUNCTION Check_Type
PARAMETERS Don_Type
PRIVATE aTYPE_MENU[6], N_CHOICE := 1

aTYPE_MENU[1] := "ADVICE"
aTYPE_MENU[2] := "GOODS DONATED"
aTYPE_MENU[3] := "GOODS LOANED"
aTYPE_MENU[4] := "MONEY"
aTYPE_MENU[5] := "SERVICE"
aTYPE_MENU[6] := "ADVERTISING"
N_CHOICE := ASCAN(aTYPE_MENU,ALLTRIM(Don_Type))
										&& Scans array to see if field already
										&& contains the choice. If found returns
										&& matching choice no 
N_CHOICE := MCHOICE(m->aTYPE_MENU,10,40,18,59,"TYPE OF DONATION",.t.,N_CHOICE)
IF N_CHOICE <> 0
	aGet[4] := PADR(aTYPE_MENU[N_CHOICE],LEN(Don_Type))
ELSE
	RETURN .F.
ENDIF
RETURN .T.
*******************************************
FUNCTION Check_Event
PARAMETERS Event_Type
PRIVATE aTYPE_MENU[13], N_CHOICE := 1

aTYPE_MENU[1] := "GENERAL DONATION"
aTYPE_MENU[2] := "GOLF DAY"
aTYPE_MENU[3] := "TRUST"
aTYPE_MENU[4] := "CHILD SPONSORSHIP"
aTYPE_MENU[5] := "FUND RAISING"
aTYPE_MENU[6] := "ANNUAL REPORT"
aTYPE_MENU[7] := "FOOD FAIR"
aTYPE_MENU[8] := "TRAIN TRIP"
aTYPE_MENU[9] := "FETE"
aTYPE_MENU[10] := "ADVERTISING"
aTYPE_MENU[11] := "XMAS PARTY"
aTYPE_MENU[12] := "GRANT"
aTYPE_MENU[13] := "OTHER"
N_CHOICE := ASCAN(aTYPE_MENU,ALLTRIM(Event_Type))
											&& Scans array to see if field already
											&& contains the choice. If found returns
											&& matching choice no 
N_CHOICE := MCHOICE(m->aTYPE_MENU,10,40,18,59,"TYPE OF EVENT",.t.,N_CHOICE)
IF N_CHOICE <> 0
	aGet[6] := PADR(aTYPE_MENU[N_CHOICE],LEN(Event_Type))
ELSE
	RETURN .F.
ENDIF
RETURN .T.
******************************************
PROCEDURE Fill_DonGet
LOCAL x
&& Fill aGet with default types for GET for Donations just now
aGet[1] := Donnum
aGet[2] := Centre
FOR x = 3 TO DONATION->(FCOUNT())
	IF aDonattype[x] = "C"
		aGet[x] := SPACE(aDonatlen[x])
	ELSEIF aDonattype[x] = "N"
		aGet[x] := 0
	ELSEIF aDonattype[x] = "L"
		aGet[x] := .T.
	ELSEIF aDonattype[x] = "D"
		aGet[x] := DATE()
	ENDIF
NEXT x

RETURN

******************************************
PROCEDURE Add_Donation
PRIVATE box, x, aGet[DONATION->(FCOUNT())], Don_Name

SET CURSOR ON
Get_Don_Name()
Fill_DonGet()

&& Save screen & Create box to show info
box = MAKEBOX(3,1,21,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "ADD A NEW DONATION FOR " + Don_Name
@ 5,22  SAY REPLICATE(CHR(223),22 + LEN(Don_Name))  && Thick line
Get_DonScr()
READ
IF LASTKEY() = 27
	SET CURSOR OFF
	RETURN
ENDIF
APPEND BLANK
&& Write Get values to new record
ARRAY2DBF(aGet)
UNBOX(m->box)
SET CURSOR OFF
RETURN
********************************************
PROCEDURE Edit_Donation

PRIVATE box, x, aGet[DONATION->(FCOUNT())], Don_Name
SET CURSOR ON
Get_Don_Name()
Fill_DonGet()
FOR x := 1 TO DONATION->(FCOUNT())
	aGet[x] := FIELDGET(x)
NEXT x


&& Save screen & Create box to show info
box = MAKEBOX(3,1,21,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "EDIT A DONATION FOR " + Don_Name
@ 5,22  SAY REPLICATE(CHR(223),20 + LEN(Don_Name))  && Thick line
Get_DonScr()
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
******************************************
PROCEDURE Get_Don_Name


IF (DONORS->C_Type = "P")
	Don_Name := RTRIM(DONORS->C_Salut) + " " + RTRIM(DONORS->C_Surname)
ELSE
	Don_Name := ALLTRIM(DONORS->C_Surname)
ENDIF

RETURN
******************************************
PROCEDURE Donation_Browse

PRIVATE lEdit := .T., Browse := "DONATION", Donnum := DONORS->N_Donnum
USE DONATION EXCLUSIVE NEW
SET DELETE ON
&& only view donor for centre selected
SET FILTER TO (DONATION->N_DONNUM = Donnum .AND. ;
					DONATION->C_Centre = DONORS->C_Centre)
GO TOP     && Activates the filter
PRIVATE adonatflds := AFIELDSX(), adonatlen := AFLENSX(), adonatdes[11]
PRIVATE aDonattype := AFTYPESX()
Stru_Donation() && Load structure of donations in arrays
SET INDEX TO DONATION.02X,DONATION.01X,DONATION.03X,DONATION.04X  
				&& Donor and date order
	EDITDB(lEdit, adonatflds, adonatdes,.T.,Browse)
CLOSE DONATION
SELECT DONORS
RETURN
******************************************
PROCEDURE Stru_Donation
PRIVATE x

&& Create array holding descriptions for GET
adonatdes[1] := "Donor"
adonatdes[2] := "Centre"
adonatdes[3] := "Date DD/MM/YY"
adonatdes[4] := "Type of Donation"
adonatdes[5] := "Amount  R"
adonatdes[6] := "Event"
adonatdes[7] := "Detail 1"
adonatdes[8] := "Detail 2"
adonatdes[9] := "Detail 3"
adonatdes[10] := "Detail 4"
adonatdes[11] := "Comments"
&& Change array[1] for relation
adonatflds[1] := "DONORS->C_Surname"
adonatflds[2] := "PCKCENTRE->C_Desc"
RETURN
*******************************************
