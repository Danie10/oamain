#include "box.ch"
#include "keys.ch"
#include "values.ch"

*****************************************
PROCEDURE Correspon

LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aCORR_MENU[3]

DO WHILE cont
aCORR_MENU[1] := "A. CORRESPONDENCE BROWSE"
aCORR_MENU[2] := "B. CORRESPONDENCE REPORTS"
aCORR_MENU[3] := "C. PREVIOUS MENU"
N_CHOICE := MCHOICE(m->aCORR_MENU,7,23,11,55,"CORRESPONDENCE MENU",.t.)
IF LASTKEY() = 27
	cont := .F.
ENDIF
DO CASE
	CASE N_CHOICE = 1
		Corr_Browse()
	
	CASE N_CHOICE = 2
		Corr_RepMenu()
	
	CASE N_CHOICE = 3
		cont := .F.
ENDCASE
ENDDO

RETURN
*****************************************
PROCEDURE Corr_Browse
PRIVATE lEdit := .T., Browse := "CORRES"


USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE CORRESPO INDEX CORRESPO.01X, CORRESPO.02X, CORRESPO.03X, CORRESPO.04X ;
		EXCLUSIVE NEW
SET RELATION TO C_Centre INTO PCKCENTRE
PRIVATE aCorflds := AFIELDSX(), aCorlen := AFLENSX(), aCordes[CORRESPO->(FCOUNT())]
PRIVATE aCortype := AFTYPESX()
Struct_Corr()
GO TOP
EDITDB(lEdit, aCorflds, aCordes,.T.,Browse)
CLOSE DATABASES
RETURN
*******************************************
PROCEDURE Add_Corres
PRIVATE box, x, aGet[CORRESPO->(FCOUNT())]
SET CURSOR ON
Fill_GetCor()
aGet[5] := CTOD("")		
&& Save screen & Create box to show info
box = MAKEBOX(3,1,21,78,sls_normcol(),sls_shadpos())
@ 4,22  SAY "ADD NEW CORRESPONDENCE FOR " + ALLTRIM(Long_Centre)
@ 5,22  SAY REPLICATE(CHR(223),27 + LEN(ALLTRIM(Long_Centre)))  && Thick line
Get_CorScr()
READ
aGet[2] := ALLTRIM(Centre)
IF LASTKEY() = 27
	SET CURSOR OFF
	RETURN
ELSE
	APPEND BLANK
	&& Write Get values to new record
	FOR x = 1 TO CORRESPO->(FCOUNT())
	CORRESPO->(FIELDPUT(x,aGet[x]))
	NEXT x
ENDIF

UNBOX(m->box)
SET CURSOR OFF
RETURN
*******************************************
PROCEDURE Rem_Corres
LOCAL status

TONE(400,9)
status := DELREC()
IF status <> 0
	IF !BOF()
		DBSKIP(-1)
	ELSE
		DBSKIP()
	ENDIF
ENDIF

RETURN
*******************************************
PROCEDURE Edit_Corres


PRIVATE box, x, aGet[CORRESPO->(FCOUNT())]
SET CURSOR ON
Fill_GetCor()
FOR x := 1 TO CORRESPO->(FCOUNT())
	aGet[x] := FIELDGET(x)
NEXT x

&& Save screen & Create box to show info
box = MAKEBOX(3,1,21,78,sls_normcol(),sls_shadpos())
@ 4,30  SAY "EDIT CORRESPONDENCE"
@ 5,30  SAY REPLICATE(CHR(223),19)  && Thick line
Get_CorScr()
READ
IF LASTKEY() = 27
	UNBOX(box)
	RETURN
ENDIF
IF AUPDATED(aGet)
	IF MESSYN("Save Changes To File?","Yes","No")
		&& Write Get values to new record
		ARRAY2DBF(aGet)
	ENDIF
ENDIF
UNBOX(box)
SET CURSOR OFF
RETURN
*******************************************
PROCEDURE Fill_GetCor
LOCAL x
&& Fill aGet with default types for GET for Correspondance just now
FOR x = 1 TO CORRESPO->(FCOUNT())
	IF aCortype[x] = "C"
		aGet[x] := SPACE(aCorlen[x])
	ELSEIF aCortype[x] = "N"
		aGet[x] := 0
	ELSEIF aCortype[x] = "L"
		aGet[x] := .T.
	ELSEIF aCortype[x] = "D"
		aGet[x] := DATE()
	ENDIF
NEXT x

RETURN
********************************************
PROCEDURE Get_CorScr   && Screen layout for GETS for Correspondence


@ 8,7 SAY aCordes[1] GET aGet[1] PICTURE "@!" COLOR "W+/N,N/W" ;
		VALID !EMPTY(aGet[1])
@ 10,7 SAY aCordes[3] GET aGet[3] COLOR "W+/N,N/W" ;
		VALID (aGet[3] <= DATE())
@ 10,40 SAY aCordes[8] GET aGet[8] PICTURE "@!" COLOR "W+/N,N/W" && Type of appeal
@ 12,7 SAY aCordes[4] GET aGet[4] PICTURE "@!" COLOR "W+/N,N/W" ;
		VALID !EMPTY(aGet[4])
@ 14,7 SAY aCordes[5] GET aGet[5] COLOR "W+/N,N/W" VALID ;
		( (aGet[5] > aGet[3]) .AND. (aGet[5] <= DATE()) .OR. EMPTY(aGet[5]))  && Date reply received
@ 14,40 SAY aCordes[7] GET aGet[7] PICTURE "99999.99" COLOR "W+/N,N/W" ;
		WHEN !EMPTY(aGet[5])  && Cash amount if a reply
@ 16,7 SAY aCordes[6] GET aGet[6] PICTURE "@!" COLOR "W+/N,N/W" ;
		WHEN !EMPTY(aGet[5])  && Reply if reply received on a date
@ 18,7 SAY aCordes[9] GET aGet[9] PICTURE "@!" COLOR "W+/N,N/W" ;
		WHEN !EMPTY(aGet[7])  && Receipt number if money received
RETURN
******************************************
PROCEDURE Struct_Corr

&& Create array holding descriptions for Correspondence
aCordes[1] := "Name"
aCordes[2] := "Centre"
aCordes[3] := "Date Sent"
aCordes[4] := "Subject"
aCordes[5] := "Date Replied"
aCordes[6] := "Reply"
aCordes[7] := "Cash received  R"
aCordes[8] := "Type of Appeal"
aCordes[9] := "Receipt no"

aCorflds[2] := "PCKCENTRE->C_Desc"

RETURN
*************************************************
PROCEDURE Corr_Query
LOCAL cWhere := "P"
PRIVATE aFields, aFdesc, aType

aFields := { "C_Corrname","C_Centre","D_Datsent","C_Type","C_Subject",;
				"D_Datrep","C_Reply","N_Amount","C_Receipt" }
aFdesc := { "Name","Centre","Date Sent","Type","Subject","Date Replied",;
				"Reply","Amount Received","Receipt No" }
aType := { "C","C","D","C","C","D","C","N" }

USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE CORRESPO INDEX CORRESPO.01X EXCLUSIVE NEW
SET RELATION TO C_Centre INTO PCKCENTRE

Filt := QUERY(aFields,aFdesc,aType,"to Print",.T.)
IF LASTKEY() = 27
	CLOSE DATABASES
	RETURN
ENDIF
SET FILTER TO &Filt
DBGOTOP()
box := MAKEBOX(7,15,14,68,sls_popcol(),sls_shadpos())
@ 9,28 SAY Heading
@ 11,20 SAY "TO PRINTER, MAILMERGE, SCREEN OR WP (P/M/S/W)" GET cWhere PICTURE "@!" ;
				COLOR "W+/N,N/W" VALID (cWhere = "P" .OR. cWhere = "M" ;
				.OR. cWhere = "S" .OR. cWhere = "W")
READ
UNBOX(box)
IF LASTKEY() = 27
	CLOSE DATABASES
	RETURN
ENDIF
IF cWhere = "P"
	Corr_Printout("QUERY")
ELSEIF cWhere = "M"
	PLSWAIT(.T.,"BUSY EXPORTING TO MAILMERGE.DBF")
	COPY FIELDS C_Corrname, C_Centre,D_Datsent, C_Type,C_Subject, D_Datrep, ;
			C_Reply, STR(N_Amount), C_Receipt TO MAILMERGE
	PLSWAIT(.F.)
ELSEIF cWhere = "S"
	EDITDB(.F.,aFields,aFdesc,.T.,"QUERY RESULT")
ELSEIF cWhere = "W"
	SMAILMERGE()
ENDIF
CLOSE DATABASES

RETURN
*************************************************
PROCEDURE Corr_Report
PARAMETERS Heading, Filt
PRIVATE box, lYes := "N", S_Date := CTOD("  /  /  "), E_Date := DATE()

USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE CORRESPO INDEX CORRESPO.01X EXCLUSIVE NEW
SET RELATION TO C_Centre INTO PCKCENTRE
box := MAKEBOX(4,15,19,64,sls_popcol(),sls_shadpos())
@ 5,22 SAY Heading
@ 10,20 SAY "Starting Date " GET S_Date COLOR "W+/N,N/W" ;
		VALID (!EMPTY(S_Date) .AND. S_Date<=DATE())
@ 14,20 SAY "Ending Date  " GET E_Date COLOR "W+/N,N/W" ;
		VALID (E_Date>=S_Date .AND. E_Date<=DATE())
@ 16,20 SAY "Date format is dd/mm/yy"
READ
IF LASTKEY() = pESC
	UNBOX(box)
	CLOSE DATABASES
	RETURN
ENDIF
IF !EMPTY(Filt)
	SET FILTER TO (&Filt .AND. CORRESPO->D_Datsent>=S_Date .AND. ;
				CORRESPO->D_Datsent<=E_Date)
ELSE
	SET FILTER TO (CORRESPO->D_Datsent>=S_Date .AND. ;
				CORRESPO->D_Datsent<=E_Date)
ENDIF
Corr_Printout("NOQUERY")

RETURN
**********************************************
PROCEDURE Corr_Printout
PARAMETERS CorrType
LOCAL counter := 0, total := 0
GO TOP
IF !P_READY("LPT1")
		UNBOX(box)
		CLOSE DATABASES
		RETURN
ENDIF
UNBOX(box)
PLSWAIT(.T.,"BUSY PRINTING")
SET DEVICE TO PRINTER
&& Set emphasised & underlined printing on
@ PROW(),14 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1)
IF CorrType = "NOQUERY"
	@ PROW(),PCOL() SAY Heading + " " + DTOC(S_Date) + " TO " + DTOC(E_Date)
ELSE
	@ PROW(),PCOL() SAY Heading
ENDIF
&& Set back to normal printing
@ PROW(), PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0)
@ PROW()+1,1 SAY " "
DO WHILE !EOF()
	counter++
	@ PROW()+2,3 SAY "Name: " + C_Corrname
	@ PROW(),45 SAY "Centre: " + PCKCENTRE->C_Desc
	@ PROW()+1,3 SAY "Date Sent: " + DTOC(D_Datsent)
	@ PROW(),24 SAY "Subject: " + C_Subject
	@ PROW()+1,3 SAY "Type: " + C_Type
	@ PROW()+1,3 SAY "Date Received: " + DTOC(D_Datrep)
	@ PROW(),29 SAY IF(EMPTY(C_Reply),"NO REPLY YET",C_Reply)
	@ PROW()+1,3 SAY "Cash received: R" + STR(N_Amount)
	@ PROW(), 40 SAY "Receipt no: " + C_Receipt
	total := total + N_Amount
	@ PROW()+1,1 SAY CHR(27) + CHR(45) + CHR(1) && Underline record
	@ PROW(),79 SAY CHR(27) + CHR(45) + CHR(0)
	IF (PROW() >= 56)
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
@ PROW()+2,4 SAY "Number of letters = " + STR(counter)
@ PROW()+1,4 SAY "Total value of correspondence = R" + LTRIM(STR(total))
@ PROW(), PCOL() SAY CHR(18)  && Normal size printing
EJECT
SET DEVICE TO SCREEN
PLSWAIT(.F.)
CLOSE DATABASES
RETURN
****************************************************
PROCEDURE Print_Receipt
&& Hot-key print out from correspondence browse for a receipt
IF (CORRESPO->N_Amount <= 0)
	TONE(400,9)
	MSG("No money received yet!!")
	RETURN
ELSEIF !P_READY("LPT1")
		TONE(400,9)
		MSG("Printer not ready!!!")
		RETURN
ENDIF

PLSWAIT(.T.,"BUSY PRINTING")
SET DEVICE TO PRINTER
@ PROW(),5 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1)  && Emphasise
@ PROW(),PCOL() SAY cOrgan    && Organisation name
@ PROW(),PCOL() SAY " - " + Expand_Centre(CORRESPO->C_Centre)
@ PROW(), PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0) && Normal
@ PROW()+2,28 SAY "RECEIPT FOR PAYMENT RECEIVED"
@ PROW(), 65 SAY CORRESPO->D_Datrep
@ PROW()+2,4 SAY "Received from " + ALLTRIM(CORRESPO->C_Corrname)
@ PROW()+2,4 SAY "the sum of R" + ALLTRIM(STR(CORRESPO->N_Amount))
@ PROW(),PCOL()+2 SAY REPLICATE(".",40)
@ PROW()+2,4 SAY "For " + ALLTRIM(CORRESPO->C_Type)
@ PROW()+2,4 SAY "Receipt no: " + LTRIM(CORRESPO->C_Receipt)
@ PROW()+3,4 SAY "With Thanks ......................................"
@ PROW()+3,1 SAY REPLICATE("-",75)
@ PROW()+3,1 SAY " "       && Add three lines so next receipt can be printed
SET DEVICE TO SCREEN
PLSWAIT(.F.)
RETURN
****************************************************