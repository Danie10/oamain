#include "box.ch"
#include "keys.ch"
#include "values.ch"

*********************************************
PROCEDURE Do_Reports
LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aREP_MENU[9], Heading, Filt

DO WHILE cont
aREP_MENU[1] := "A. ALL NEWSLETTER DONORS"
aREP_MENU[2] := "B. ALL ANNUAL REPORT DONORS"
aREP_MENU[3] := "C. ALL DONATION CONTACTS"
aREP_MENU[4] := "D. ALL CLUB 600 DONORS"
aREP_MENU[5] := "E. ALL VOLUNTEER DONORS"
aREP_MENU[6] := "F. ALL DONORS"
aREP_MENU[7] := "G. QUERY ON DONORS"
aREP_MENU[8] := "H. QUERY ON DONATIONS"
aREP_MENU[9] := "I. PREVIOUS MENU"
N_CHOICE := MCHOICE(m->aREP_MENU,7,23,18,55,"DONOR REPORT MENU",.t.)
IF LASTKEY() = 27
	cont := .F.
ENDIF
DO CASE
	CASE N_CHOICE = 1
		Heading := "LIST OF DONORS REQURING NEWLETTER"
		Filt := "L_Newslett"
		Rep_General()

	CASE N_CHOICE = 2
		Heading := "LIST OF DONORS REQUIRING ANNUAL REPORT"
		Filt := "L_Annualrt"
		Rep_General()
	
	CASE N_CHOICE = 3
		Heading := "LIST OF DONORS REQUIRING FURTHER CONTACT"
		Filt := "L_Contdon"
		Rep_General()
	
	CASE N_CHOICE = 4
		Heading := "LIST OF CLUB 600 DONORS"
		Filt := "L_C600"
		Rep_General()
	
	CASE N_CHOICE = 5
		Heading := "LIST OF DONORS AVAILABLE AS VOLUNTEERS"
		Filt := "L_Volunt"
		Rep_General()
	
	CASE N_CHOICE = 6
		Heading := "LIST OF ALL DONORS"
		Filt := ""
		Rep_General()
	
	CASE N_CHOICE = 7
		Heading := "QUERY ON DONORS"
		Filt := ""
		Do_Query("DONORS")
	
	CASE N_CHOICE = 8
		Heading := "QUERY ON DONATIONS"
		Filt := ""
		Do_Query("DONATIONS")
	
	CASE N_CHOICE = 9
		cont := .F.

ENDCASE
ENDDO
CLOSE DATABASES
RETURN
******************************************
PROCEDURE Corr_RepMenu
LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aCORR_REPMENU[4], Heading, Filt

DO WHILE cont
aCORR_REPMENU[1] := "A. NO REPLIES FOR PERIOD"
aCORR_REPMENU[2] := "B. LETTERS SENT FOR PERIOD"
aCORR_REPMENU[3] := "C. QUERY FOR CORRESPONDENCE"
aCORR_REPMENU[4] := "D. RETURN TO PREVIOUS MENU"
N_CHOICE := MCHOICE(m->aCORR_REPMENU,7,23,14,55,"CORRESPONDENCE REPORTS",.t.)
IF LASTKEY() = 27
	cont := .F.
ENDIF
DO CASE
	CASE N_CHOICE = 1
		Heading := "LIST OF PERSONS THAT HAVE NOT REPLIED"
		Filt := "EMPTY(D_Datrep)"
		Corr_Report(Heading,Filt)

	CASE N_CHOICE = 2
		Heading := "LETTERS SENT OVER A PERIOD"
		Filt := ""
		Corr_Report(Heading,Filt)	

	CASE N_CHOICE = 3
		Heading := "GENERAL CORRESPONDENCE QUERY"
		Filt := ""
		Corr_Query(Heading,Filt)

	CASE N_CHOICE = 4
		cont := .F.
		
ENDCASE
ENDDO
CLOSE DATABASES

RETURN
******************************************
PROCEDURE Rep_General
LOCAL box
PRIVATE cOrder := "C", lYes := "N", cWhere := "P", aType, aFields, aFdesc
PRIVATE Browse := "QUERY RESULT"
aFields := { "C_Surname2","C_Surname","C_Salut","C_Initials","C_Address1",;
				 "C_Address2","C_City","C_Postcode","L_Newslett","L_Annualrt",;
				 "L_Contdon","L_C600","L_Volunt","C_Centre","C_Type" }
aFdesc := { "Contact Surname","Surname/Company","Salutation","Initials",;
				"Address1","Address2","City","Postal Code","Newsletter?",;
				"Annual Report?","Contact for Donation?","Club 600?","Volunteer?",;
				 "Centre","Donor Type C/T/P" }
aType := { "C","C","C","C","C","C","C","C","L","L","L","L","L","C","C" }
box := MAKEBOX(5,13,19,72,sls_popcol(),sls_shadpos())
@ 6,22 SAY Heading
@ 10,18 SAY "PRINT PRIVATE/COMPANY/TRUST/ALL (P/C/T/A)" GET cOrder PICTURE "@!" ;
				COLOR "W+/N,N/W" VALID (cOrder = "C" .OR. cOrder = "P" ;
				.OR. cOrder = "T" .OR. cOrder = "A")
@ 12,18 SAY "ONLY FOR YOUR CENTRE (Y/N)" GET lYes PICTURE "@!" COLOR "W+/N,N/W" ;
				VALID (lYes ="Y" .OR. lYes = "N")
@ 14,15 SAY "TO PRINTER, MAILMERGE, LABELS, SCREEN OR WP (P/M/L/S/W)" GET cWhere ;
			PICTURE "@!" COLOR "W+/N,N/W" VALID ;
			(cWhere = "P" .OR. cWhere = "M" .OR. cWhere="S" .OR. cWhere = "L";
			.OR. cWhere = "W")
READ
&& Esc pressed
IF LASTKEY() = 27
	UNBOX(box)
	RETURN
ENDIF

USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
USE DONORS INDEX DONORS.01X,DONORS.02X, DONORS.03X, DONORS.04X EXCLUSIVE NEW
SET RELATION TO C_Centre INTO PCKCENTRE
IF LEN(Filt) > 0      && There  is something set in filter
	IF lYes = "Y"
		IF cOrder <> "A"
			SET FILTER TO (&Filt = .T. .AND. C_Centre=Centre .AND. C_Type=cOrder)
		ELSE
			SET FILTER TO (&Filt = .T. .AND. C_Centre=Centre)
		ENDIF
	ELSE
		IF cOrder <> "A"
			SET FILTER TO (&Filt = .T. .AND. C_Type = cOrder)
		ELSE
			SET FILTER TO &Filt
		ENDIF
	ENDIF
ELSE
	IF lYes = "Y"
		IF cOrder <> "A"
			SET FILTER TO (C_Centre=Centre .AND. C_Type=cOrder)
		ELSE
			SET FILTER TO (C_Centre=Centre)
		ENDIF
	ELSE
		IF cOrder <> "A"
			SET FILTER TO (C_Type = cOrder)
		ENDIF
	ENDIF
ENDIF
GO TOP
&& Do printout to Printer or else to mailmerge file for Multi-Mate
UNBOX(box)
IF cWhere = "P"
	Donor_Printout("DONORS")
ELSEIF cWhere = "M"
	PLSWAIT(.T.,"BUSY EXPORTING TO MAILMERGE.DBF")
	SET ORDER TO 4
	COPY FIELDS C_Surname2, C_Surname, C_Initials, C_Salut, C_Title, ;
			C_Address1, C_Address2, C_City, C_Postcode TO MAILMERGE
	PLSWAIT(.F.)
ELSEIF cWhere = "S"
	KEYBOARD CHR(4) && Right arrow
	EDITDB(.F.,aFields,aFdesc,.T.,Browse)
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
*****************************************
PROCEDURE Do_Query
PARAMETERS Select
LOCAL cWhere := "P"
PRIVATE aFields, aFdesc, aType, cOrder := "Q", Browse := "QUERY RESULT"

IF Select = "DONORS"
	aFields := { "C_Surname2","C_Surname","C_Salut","C_Initials","C_Address1",;
				 "C_Address2","C_City","C_Postcode","L_Newslett","L_Annualrt",;
				 "L_Contdon","L_C600","L_Volunt","C_Centre","C_Type" }
	aFdesc := { "Contact Surname","Surname/Company","Salutation","Initials",;
				"Address1","Address2","City","Postal Code","Newsletter?",;
				"Annual Report?","Contact for Donation?","Club 600?","Volunteer?",;
				 "Centre","Donor Type C/T/P" }
	aType := { "C","C","C","C","C","C","C","C","L","L","L","L","L","C","C" }
	USE DONORS INDEX DONORS.01X, DONORS.04X EXCLUSIVE NEW
ELSE        && Is Donations
	aFields := { "C_Centre","D_Date","C_Type","N_Amount","C_Event",;
				 "C_Detail1","C_Detail2","C_Detail3","C_Detail4","C_Comments" }
	aFdesc := { "Centre","Date","Type","Amount","Event",;
				 "Detail 1","Detail 2","Detail 3","Detail 4","Comments" }
	aType := { "C","D","C","N","C","C","C","C","C","C" }
	USE DONORS INDEX DONORS.03X, DONORS.04X EXCLUSIVE NEW
	USE DONATION INDEX DONATION.02X EXCLUSIVE NEW
	SET RELATION TO C_Centre+STR(N_Donnum) INTO DONORS
ENDIF


Filt := QUERY(aFields,aFdesc,aType,"to Print",.T.)
IF LASTKEY() = 27
	CLOSE DATABASES
	RETURN
ENDIF
SET FILTER TO &Filt
DBGOTOP()
box := MAKEBOX(7,13,14,72,sls_popcol(),sls_shadpos())
@ 8,30 SAY Heading
@ 11,15 SAY "TO PRINTER, MAILMERGE, LABELS, SCREEN OR WP (P/M/L/S/W)" GET cWhere ;
		PICTURE "@!" COLOR "W+/N,N/W" ;
		VALID (cWhere = "P" .OR. cWhere = "M" .OR. cWhere = "S" .OR. ;
		cWhere = "L" .OR. cWhere = "W")
READ
UNBOX(box)
IF LASTKEY() = 27
	CLOSE DATABASES
	RETURN
ENDIF
IF cWhere = "P"
	Donor_Printout(Select)
ELSEIF cWhere = "M"
	PLSWAIT(.T.,"BUSY EXPORTING TO MAILMERGE.DBF")
	IF Select = "DONORS"
		SET ORDER TO 2
		COPY FIELDS C_Surname2, C_Surname, C_Initials, C_Salut, ;
				PROPER(C_Title), PROPER(C_Address1), PROPER(C_Address2), C_City, ;
				C_Postcode TO MAILMERGE
		SET ORDER TO 1
	ELSE
		COPY FIELDS Donors->C_Surname2, DONORS->C_Surname, ;
				DONORS->C_Initials, PROPER(DONORS->C_Title), ;
				PROPER(DONORS->C_Address1), PROPER(DONORS->Address2),;
				DONORS->C_City, DONORS->C_Postcode, D_Date, C_Type,;
				STR(N_Amount), C_Event, C_Detail1, C_Detail2, C_Detail3,;
				C_Detail4, C_Comments TO MAILMERGE
	ENDIF
	PLSWAIT(.F.)
ELSEIF cWhere = "S"
	EDITDB(.F.,aFields,aFdesc,.T.,Browse)
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
*****************************************
PROCEDURE Donor_Printout
PARAMETERS Select
LOCAL ChangeDonor := 0, DonorTotal := 0
	IF !P_READY("LPT1")
		UNBOX(box)
		CLOSE DATABASES
		RETURN
	ENDIF
	PLSWAIT(.T.,"BUSY PRINTING")
	SET DEVICE TO PRINTER
	&& Turn on emphasised & underlined print
	@ PROW(),15 SAY CHR(27) + CHR(71) + CHR(27) + CHR(45) + CHR(1)
	@ PROW(),PCOL() SAY Heading + " - " + Expand_Order(cOrder) + " donors"
	&& Back to normal printing
	@ PROW(),PCOL() SAY CHR(27) + CHR(72) + CHR(27) + CHR(45) + CHR(0)
	&& Select compressed printing
	@ PROW()+1,1 SAY " " + CHR(27) + CHR(15)
	DO WHILE !EOF()
		@ PROW()+1,3 SAY SUBSTR(DONORS->C_Surname,1,25)
		IF (DONORS->C_Type = "P")
			@ PROW(),30 SAY DONORS->C_Initials
		ELSEIF (DONORS->C_Type = "C")
			@ PROW(),30 SAY "COMP"
		ELSEIF (DONORS->C_Type = "T")
			@ PROW(),30 SAY "TRUST"
		ENDIF
		IF Select = "DONORS"
			@ PROW(),36 SAY PROPER(SUBSTR(DONORS->C_Address1,1,20))
			@ PROW(),58 SAY PROPER(SUBSTR(DONORS->C_Address2,1,20))
			@ PROW(),80 SAY SUBSTR(DONORS->C_City,1,16)
			@ PROW(),98 SAY DONORS->C_Postcode
			@ PROW(),103 SAY DONORS->C_Telcode
			@ PROW(),110 SAY DONORS->C_Tel
		ELSE
			@ PROW(),36 SAY SUBSTR(DONATION->C_Type,1,13)
			@ PROW(),50 SAY SUBSTR(DONATION->C_Detail1,1,25)
			@ PROW(),76 SAY SUBSTR(DONATION->C_Detail2,1,22)
			@ PROW(),99 SAY DTOC(DONATION->D_Date)
			@ PROW(),108 SAY "R"+STR(DONATION->N_Amount)
		ENDIF
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
		&& Increment donation and print total if donor changes
		DonorTotal := DonorTotal + N_Amount
		ChangeDonor := N_Donnum
		SKIP
		IF ChangeDonor <> 0 .AND. N_Donnum <> ChangeDonor && New donor's donation
			@ PROW()+1,108 SAY "-----------"
			@ PROW()+1,101 SAY "TOTAL"  + TRIM(STR(DonorTotal))
			@ PROW()+1,101 SAY " "
			DonorTotal := 0
			ChangeDonor := N_Donnum
		ENDIF
	ENDDO
	@ PROW() + 2, 3 SAY "QUERY = " + Filt    && Print query string
	@ PROW(), PCOL() SAY CHR(18) && Normal size printing
	EJECT
	SET DEVICE TO SCREEN
	PLSWAIT(.F.)

RETURN
*****************************************