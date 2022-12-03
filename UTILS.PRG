#include "box.ch"
#include "keys.ch"
#include "values.ch"

****************************************
PROCEDURE Util_Menu
PARAMETERS Version
LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aUTIL_MENU[14]

DO WHILE cont
aUTIL_MENU[1] := "A. REINDEX FILES"
aUTIL_MENU[2] := "B. SET COLOURS"

IF Centre = "A"
	aUTIL_MENU[3] := "C. RECEIVE DATA FROM CENTRES"
ELSE
	aUTIL_MENU[3] := "C. SEND DATA TO ADMIN OFFICE"
ENDIF
aUTIL_MENU[4] := "D. CONVERSIONS"
aUTIL_MENU[5] := "E. CALENDER"
aUTIL_MENU[6] := "F. MEMBERS SUBS"
aUTIL_MENU[7] := "G. APRIL MEMBERS' RUN (ADD ARREARS)"
aUTIL_MENU[8] := "H. AUGUST MEMBERS' RUN (CLEAR ARREARS)"
aUTIL_MENU[9] := "I. SET VAT RATE"
aUTIL_MENU[10] := "J. EDIT CENTRE LIST"
aUTIL_MENU[11] := "K. BACKUP"
aUTIL_MENU[12] := "L. RUNTIME INFO"
aUTIL_MENU[13] := "M. FORMAT FLOPPY DISC"
aUTIL_MENU[14] := "N. PREVIOUS MENU"

N_CHOICE := MCHOICE(m->aUTIL_MENU,4,23,20,65,"UTILTIES",.t.)
IF LASTKEY() = 27
	cont := .F.
ENDIF
DO CASE
CASE N_CHOICE = 1
			Indexes()
CASE N_CHOICE = 2
			COLPIK()
			MAINSCR(Long_Centre, CMONTH(DATE())+STR(YEAR(DATE())),Version)
CASE N_CHOICE = 3
			Transfer()
CASE N_CHOICE = 4
			WGT_MEAS()
CASE N_CHOICE = 5
			GETDATE()
CASE N_CHOICE = 6
			Mem_Subs()
CASE N_CHOICE = 7
			Mem_April()
CASE N_CHOICE = 8
			Mem_August()
CASE N_CHOICE = 9
			Set_Vat()
CASE N_CHOICE = 10
			IF Centre = "A"
				Modify_Centre()
			ELSE
				TONE(400,12)
				MSG("ONLY ADMIN CENTRE CAN ADD CENTRES!")
			ENDIF
CASE N_CHOICE = 11
			Backup(Version)
CASE N_CHOICE = 12
			GetInfo()
CASE N_CHOICE = 13
			Format_Disc()
			MAINSCR(Long_Centre, CMONTH(DATE())+STR(YEAR(DATE())),Version)
CASE N_CHOICE = 14
			cont := .F.
ENDCASE
ENDDO
RETURN
******************************************
PROCEDURE Format_Disc


CLS()
RUN FORMAT A:


RETURN
******************************************
PROCEDURE GetInfo
&& Shows various runtime info

MSG("Total memory available in pool: "+STR(BLIMEMAVL())+"bytes",;
	"Largest available memory block: "+STR(BLIMEMMAX())+"bytes",;
	"Overlay pool operating size: "+STR(BLIOVLOPS())+"KB",;
	"Current overlay pool: "+STR(BLIOVLSIZ())+"KB",;
	"Memory available for runtime is: "+STR(MEMORY(2))+"KB",;
	"Operating system: " +OS(),;
	ALLTRIM(STR(diskspace()/1000)) + "KB free on drive" )


RETURN
*****************************************
PROCEDURE Backup
PARAMETERS Version
&& Uses overlay library to shell to dos to run ARJ
PRIVATE EnvVar := "PROMPT Type EXIT to Return $_$P$G"

CLS()
OVERLAY("ARJ A BACKUP.ARJ *.DB?",0,"",EnvVar)
MAINSCR(Long_Centre, CMONTH(DATE())+STR(YEAR(DATE())),Version)
IF FILE("BACKUP.ARJ")
	IF MESSYN("IS THERE A BACKUP DISC IN A: DRIVE?")
		&& If backup file size less than available space on a: drive
		IF FILEINFO("BACKUP.ARJ",1) < DISKSPACE(1)
			COPY FILE BACKUP.ARJ TO A:\BACKUP.ARJ
		ELSE
			TONE(400,9)
			MSG("NOT ENOUGH SPACE ON BACKUP DISC TO COPY FILE!!",;
				 STR(FILEINFO("BACKUP.ARJ",1)/1000) + "Kb WERE REQUIRED.")
		ENDIF
	ENDIF
ELSE
	TONE(400,9)
	MSG("NO BACKUP FILE FOUND!!!!")
ENDIF

RETURN
******************************************
PROCEDURE Modify_Centre
PRIVATE Browse := "CENTRES"
PRIVATE aFlds, aFldes := { "CODE", "DESCRIPTION" }

USE PCKCENTR INDEX PCKCENTR.01X EXCLUSIVE NEW
aFlds := AFIELDSX()  && Gets array of field names
EDITDB(.T.,aFlds,aFldes,.T.,Browse)
CLOSE PCKCENTR

RETURN
*****************************************
PROCEDURE Add_Centre
PRIVATE box
PRIVATE Centre := SPACE(22), Code := " "

SET CURSOR ON

&& Save screen & Create box to show info
box = MAKEBOX(7,20,15,64,sls_normcol(),sls_shadpos())
@ 8,25  SAY "ADD A NEW CENTRE"
@ 9,25  SAY REPLICATE(CHR(223),16)  && Thick line
@ 12,22 SAY "Enter code for Centre: " GET Code PICTURE "@!" ;
				VALID Dups_Code(Code,.T.)
@ 14,22 SAY "Enter description: " GET Centre PICTURE "@!" ;
			WHEN !EMPTY(Code) VALID !EMPTY(Centre)
READ
IF LASTKEY() = 27
	SET CURSOR OFF
	UNBOX(m->box)
	RETURN
ENDIF
APPEND BLANK
&& Write Get values to new record
PCKCENTR->C_Centre := Code
PCKCENTR->C_Desc := Centre

UNBOX(m->box)
SET CURSOR OFF

RETURN
*****************************************
FUNCTION Dups_Code
PARAMETERS Code, Add
LOCAL ret_val := .T., cur_rec := RECNO()

IF Add = .T.
	DBGOTOP()
	SEEK Code
	IF FOUND()
		TONE(400,12)
		MSG("CODE ALREADY EXISTS! - TRY ANOTHER")
		ret_val := .F.
	ELSE
		ret_val := .T.
	ENDIF
ELSE
	DBGOTOP()
	DO WHILE !EOF()
		SEEK Code
		IF ((FOUND()) .AND. (RECNO()=cur_rec))
			ret_val := .T.
			EXIT
		ELSEIF ((FOUND()) .AND. (RECNO()<>cur_rec))
			TONE(400,12)
			MSG("CODE ALREADY EXISTS! - CHOOSE ANOTHER")
			ret_val := .F.
			EXIT
		ELSEIF !FOUND()
			TONE(400,12)
			MSG("NOT FOUND - CODE CHANGED")
			ret_val := .T.
			EXIT
		ENDIF
	ENDDO
ENDIF
DBGOTO(cur_rec)
RETURN ret_val
*****************************************
PROCEDURE Edit_Centre
PRIVATE box
PRIVATE Centre := PCKCENTR->C_Desc, Code := PCKCENTR->C_Centre

SET CURSOR ON

&& Save screen & Create box to show info
box = MAKEBOX(7,20,16,64,sls_normcol(),sls_shadpos())
@ 8,25  SAY "EDIT A CENTRE"
@ 9,25  SAY REPLICATE(CHR(223),13)  && Thick line
@ 12,22 SAY "Enter code for Centre: " GET Code VALID Dups_Code(Code,.F.)
@ 14,22 SAY "Enter description: " GET Centre PICTURE "@!"
READ
IF LASTKEY() = 27
	SET CURSOR OFF
	UNBOX(m->box)
	RETURN
ENDIF

&& Write Get values to current record
PCKCENTR->C_Centre := Code
PCKCENTR->C_Desc := Centre

UNBOX(m->box)
SET CURSOR OFF

RETURN
****************************************
PROCEDURE Gen_Centre
LOCAL SaveRec := RECNO()
IF MESSYN("IS THERE A FORMATTED DISC IN THE A: DRIVE?")
	IF DISKSPACE(1) < 750000
		TONE(400,9)
		MSG("Installation disc requires 750Kb space!","You have only "+LTRIM(STR((DISKSPACE(1)/1000)))+"Kb space")
		RETURN
	ENDIF
	IF Centre = "A"
		CLOSE PCKCENTR
		PLSWAIT(.T.,"Generating installation disc")
		COPY FILE OAMAIN.EXE TO A:\OAMAIN.EXE
		COPY FILE HELP.DBF TO A:\HELP.DBF
		COPY FILE HELP.DBT TO A:\HELP.DBT
		COPY FILE HELP.NTX TO A:\HELP.NTX
		COPY FILE CENTRE.DBF TO A:\CENTRE.DBF
		COPY FILE PCKCENTR.DBF TO A:\PCKCENTR.DBF
		COPY FILE PCKSUBS.DBF TO A:\PCKSUBS.DBF
		COPY FILE PCKVAT.DBF TO A:\PCKVAT.DBF
		USE PCKCENTR EXCLUSIVE NEW
		GO SaveRec
		IF FILE("CLABELS.DBF")
			COPY FILE CLABELS.DBF TO A:\CLABELS.DBF
			COPY FILE CLABELS.DBT TO A:\CLABELS.DBT
		ENDIF
		COPY FILE ARJ.EXE TO A:\ARJ.EXE
		USE A:\CENTRE ALIAS NEWCENT EXCLUSIVE NEW
		DBGOTOP()
		&& Copy Code and Desc from current PCKCentr to the installation disc
		NEWCENT->C_Centre := PCKCENTR->C_Centre
		NEWCENT->C_Desc := PCKCENTR->C_Desc
		CLOSE NEWCENT
		SELECT PCKCENTR
		PLSWAIT(.F.)
		TONE(400,9)
		MSG("INSTALLATION COMPLETED!!!",;
			"To install put disc in other centre's A: drive and type OAMAIN.",;
			"Installation/Upgrade process will start automatically.")
	ELSE
		TONE(400,9)
		MSG("ONLY ADMIN CENTRE CAN GENERATE DISCS!!!!")
		RETURN
	ENDIF
ENDIF
RETURN
****************************************
PROCEDURE Installation
&& Copies files from installation disc to hard drive
PARAMETERS Version
PRIVATE Source_Drv := CURD()

MAINSCR("INSTALLATION/UPGRADE", CMONTH(DATE())+STR(YEAR(DATE())),Version)
RUN C:     && Tries to go to c: drive
IF CURD() <> "C"
	MSG("No C: drive to install to")
	CLS()
	CAPSLOFF()
	QUIT
ENDIF
IF CDIR("\DONORS")  && Tries to change to directory
	IF FILE("OAMAIN.EXE")
		IF MESSYN("Do you want to overwrite the old version?")
			Install_Files()
		ELSE      && Directory exists with previous version in
			MSG("Restart from hard drive")
			CLS()
			CAPSLOFF()
			QUIT
		ENDIF
	ELSE
		Install_Files()
	ENDIF
ELSE          && No directory yet, create it
	RUN MD C:\DONORS
	IF CDIR("\DONORS")
		IF DISKSPACE(3) < 750000
			TONE(400,9)
			MSG("Installation drive requires 750Kb space!","You have only "+LTRIM(STR((DISKSPACE(1)/1000)))+"Kb space")
			RETURN
		ELSE
			Install_Files()
		ENDIF
	ELSE
		TONE(400,9)
		MSG("Cannot find C:\DONORS directory")
		CLS()
		CAPSLOFF()
		QUIT
	ENDIF
ENDIF
RETURN
****************************************
PROCEDURE Install_Files

PLSWAIT(.T.,"Installing Files to C: drive....")
	COPY FILE &Source_Drv:\OAMAIN.EXE TO C:\DONORS\OAMAIN.EXE
	COPY FILE &Source_Drv:\HELP.DBF TO C:\DONORS\HELP.DBF
	COPY FILE &Source_Drv:\HELP.DBT TO C:\DONORS\HELP.DBT
	COPY FILE &Source_Drv:\HELP.NTX TO C:\DONORS\HELP.NTX
	COPY FILE &Source_Drv:\CENTRE.DBF TO C:\DONORS\CENTRE.DBF
	IF FILE("C:\DONORS\PCKCENTR.DBF")
		TONE(400,9)
		IF MESSYN("Do you want to overwrite the list of centres?")
			COPY FILE &Source_Drv:\pckcentr.DBF TO C:\DONORS\pckcentr.DBF
		ENDIF
	ELSE
		COPY FILE &Source_Drv:\pckcentr.DBF TO C:\DONORS\pckcentr.DBF
	ENDIF
	IF FILE("C:\DONORS\PCKsubs.DBF")
		TONE(400,9)
		IF MESSYN("Do you want to overwrite the list of subscriptions?")
			COPY FILE &Source_Drv:\pcksubs.DBF TO C:\DONORS\pcksubs.DBF
		ENDIF
	ELSE
		COPY FILE &Source_Drv:\pcksubs.DBF TO C:\DONORS\pcksubs.DBF
	ENDIF
	IF FILE("C:\DONORS\PCKVAT.DBF")
		TONE(400,9)
		IF MESSYN("Do you want to overwrite the VAT rate file?")
			COPY FILE &Source_Drv:\pckvat.DBF TO C:\DONORS\pckvat.DBF
		ENDIF
	ELSE
		COPY FILE &Source_Drv:\pckvat.DBF TO C:\DONORS\pckvat.DBF
	ENDIF
	COPY FILE &Source_Drv:\ARJ.EXE TO C:\DONORS\ARJ.EXE
	IF FILE("&Source_Drv:\CLABELS.DBF")
		TONE(400,9)
		IF MESSYN("Do you want to install the default labels?")
			COPY FILE &Source_Drv:\CLABELS.DBF TO C:\DONORS\CLABELS.DBF
			COPY FILE &Source_Drv:\CLABELS.DBT TO C:\DONORS\CLABELS.DBT
		ENDIF
	ELSE
		COPY FILE &Source_Drv:\CLABELS.DBF TO C:\DONORS\CLABELS.DBF
		COPY FILE &Source_Drv:\CLABELS.DBT TO C:\DONORS\CLABELS.DBT
	ENDIF
	PLSWAIT(.F.)
	TONE(400,9)
	MSG("Installation/Upgrade completed.",;
		"To start program stand in C:\DONORS directory",;
		"and type OAMAIN to execute new program.")
	CAPSLOFF()
	CLS()
	QUIT
PLSWAIT(.F.)

RETURN
****************************************
PROCEDURE Mem_Subs
&& Function allows user to adjust members' subs
LOCAL i, aDesc := {}, aGets := {}

USE PCKSUBS EXCLUSIVE NEW
FOR i := 1 TO RECCOUNT()
	&& Get the amount and description for each member type
	AADD(aGets, PCKSUBS->N_Subs)
	AADD(aDesc, TRIM(PCKSUBS->C_Memdesc))
	@ maxrow()+1, maxcol()+1 GET aGets[i]
	DBSKIP()
NEXT
&& Write back to database if updated
IF SGETMANY(getlist,aDesc,5,20,19,60,"Editing Membership Subs",;
			"ESC quits, F10 saves",2)
	DBGOTOP()
	FOR i = 1 TO RECCOUNT()
		PCKSUBS->N_Subs := aGets[i]
		DBSKIP()
	NEXT i
ENDIF
CLOSE PCKSUBS
RETURN
******************************************
PROCEDURE Set_Vat
PRIVATE vat

USE PCKVAT EXCLUSIVE NEW
DBGOTOP()
vat := PCKVAT->N_Vat
POPREAD(.F., "Enter current VAT % ", @vat, "99.9")
IF UPDATED()
	FIELDPUT(1,vat)
ENDIF
CLOSE PCKVAT

RETURN
*****************************************
PROCEDURE Transfer
PRIVATE Disc_Centre, Long_NCentre, Space_Needed := 0
IF MESSYN("IS THERE A DATA DISC IN THE A: DRIVE?")
	IF Centre = "A"
	&& Admin Centre receives data from other centres
		IF FILE("A:\CENTRE.DBF")
			USE A:\CENTRE ALIAS NEWCENTRE EXCLUSIVE NEW
			Disc_Centre := NEWCENTRE->C_Centre
			Long_NCentre := NEWCENTRE->C_Desc
			CLOSE NEWCENTRE
			IF MESSYN("DO YOU WANT TO IMPORT FROM "+ALLTRIM(Long_NCentre))
				PLSWAIT(.T.,"DELETING THEIR OLD DATA")
				USE DONORS EXCLUSIVE NEW
				DELETE FOR C_Centre == Disc_Centre  && Delete donors
				USE DONATION EXCLUSIVE NEW
				DELETE FOR C_Centre == Disc_Centre  && Delete donations
				USE MEMBERS EXCLUSIVE NEW
				DELETE FOR C_Centre == Disc_Centre  && Delete members
				PLSWAIT(.F.)
				PLSWAIT(.T.,"IMPORTING FROM DISC")
				SELECT DONORS
				APPEND FROM A:\DONORS      && Append donors from other centre
				PACK
				SELECT DONATION
				APPEND FROM A:\DONATION    && Append donations
				PACK
				SELECT MEMBERS
				APPEND FROM A:\MEMBERS     && Append members
				PLSWAIT(.F.)
				CLOSE DATABASES
				Indexes()
			ENDIF
		ELSE
			&& Cannot read drive a:
			TONE(400,9)
			MSG("DRIVE A: NOT READY OR NOT CORRECT DISC","INSERT CORRECT DISC", ;
				"AND TRY AGAIN")
		ENDIF
	ELSE
		&& Other Centre sending to Admin Office
		&& Get space required to backup to floppy
		USE DONORS EXCLUSIVE NEW
		Space_Needed := Space_Needed + DbfSize()
		USE DONATION EXCLUSIVE NEW
		Space_Needed := Space_Needed + DbfSize()
		USE CENTRE EXCLUSIVE NEW
		Space_Needed := Space_Needed + DbfSize()
		USE MEMBERS EXCLUSIVE NEW
		Space_Needed := Space_Needed + DbfSize()
		IF DISKSPACE(1) < Space_Needed
			TONE(400,9)
			MSG("Not enough disk space on floppy disc to copy files",;
					"You have " + ALLTRIM(STR(DISKSPACE()/1000)) + "bytes free and the",;
					"program requires " + ALLTRIM(STR(Space_Needed)/1000) + "bytes.",;
					"You could try deleting files on the floppy to make space.")
			RETURN
		ELSE
			PLSWAIT(.T., "COPYING FILES TO DISC")
			COPY FILE DONORS.DBF TO A:\DONORS.DBF
			COPY FILE DONATION.DBF TO A:\DONATION.DBF
			COPY FILE CENTRE.DBF TO A:\CENTRE.DBF
			COPY FILE MEMBERS.DBF TO A:\MEMBERS.DBF
			PLSWAIT(.F.)
			MSG("COMPLETED OPERATION")
		ENDIF
	ENDIF
ENDIF
RETURN
*****************************************
PROCEDURE Indexes
			PLSWAIT(.T.,"Busy Reindexing....",4,30,6,50)

			IF FILE("DONORS.01X")
				DELETE FILE DONORS.01X
			ENDIF
			IF FILE("DONORS.02X")
				DELETE FILE DONORS.02X
			ENDIF
			IF FILE("DONORS.03X")
				DELETE FILE DONORS.03X
			ENDIF
			IF FILE("DONORS.04X")
				DELETE FILE DONORS.04X
			ENDIF
				USE DONORS
				PACK
				PROGINDEX("DONORS.01X","C_Surname + C_Initials", ;
							.f.,.t.,.f.)
				PROGINDEX("DONORS.02X","C_Surname2",.f.,.t.,.f.)
				PROGINDEX("DONORS.03X","C_Centre+STR(N_Donnum)",.f.,.t.,.f.)
				PROGINDEX("DONORS.04X","C_Postcode",.f.,.t.,.f.)
				CLOSE DONORS

			IF FILE("MEMBERS.01X")
				DELETE FILE MEMBERS.01X
			ENDIF
			IF FILE("MEMBERS.02X")
				DELETE FILE MEMBERS.02X
			ENDIF
			IF FILE("MEMBERS.03X")
				DELETE FILE MEMBERS.03X
			ENDIF
			IF FILE("MEMBERS.04X")
				DELETE FILE MEMBERS.04X
			ENDIF
			IF FILE("MEMBERS.05X")
				DELETE FILE MEMBERS.05X
			ENDIF
			
			USE MEMBERS
			PACK
			PROGINDEX("MEMBERS.01X","C_Surname + C_Initials",.f.,.t.,.f.)
			PROGINDEX("MEMBERS.02X","C_Surname2",.f.,.t.,.f.)
			PROGINDEX("MEMBERS.03X","C_Centre+C_Memcode",.f.,.t.,.f.)
			PROGINDEX("MEMBERS.04X","N_Arrears",.f.,.t.,.f.)
			PROGINDEX("MEMBERS.05X","C_Postcode",.f.,.t.,.f.)
			CLOSE MEMBERS


			IF FILE("DONATION.01X")
				DELETE FILE DONATION.01X
			ENDIF
			IF FILE("DONATION.02X")
				DELETE FILE DONATION.02X
			ENDIF
			IF FILE("DONATION.03X")
				DELETE FILE DONATION.03X
			ENDIF
			IF FILE("DONATION.04X")
				DELETE FILE DONATION.04X
			ENDIF
				USE DONATION
				PACK
				PROGINDEX("DONATION.01X","C_Centre+STR(N_Donnum)",.f., ;
								.t.,.f.)
				PROGINDEX("DONATION.02X","STR(N_Donnum)+DTOS(D_Date)", ;
								.f.,.t.,.f.)
				PROGINDEX("DONATION.03X","C_Centre+STR(N_Donnum)",.f.,.t.,.f.)
				PROGINDEX("DONATION.04X","STR(N_Amount)",.f.,.t.,.f.)
				CLOSE DONATION

			IF FILE("CORRESPO.01X")
				DELETE FILE CORRESPO.01X
			ENDIF
			IF FILE("CORRESPO.02X")
				DELETE FILE CORRESPO.02X
			ENDIF
			IF FILE("CORRESPO.03X")
				DELETE FILE CORRESPO.03X
			ENDIF
			IF FILE("CORRESPO.04X")
				DELETE FILE CORRESPO.04X
			ENDIF


				USE CORRESPO
				PACK
				PROGINDEX("CORRESPO.01X","C_Centre+RTRIM(C_Corrname)+DTOS(D_datsent)", ;
								.f.,.t.,.f.)
				PROGINDEX("CORRESPO.02X","C_Centre+RTRIM(C_Corrname)",.f.,.t.,.f.)
				PROGINDEX("CORRESPO.03X","DTOS(D_datsent)",.f.,.t.,.f.)
				PROGINDEX("CORRESPO.04X","C_Type",.f.,.t.,.f.)
				CLOSE CORRESPO

			IF FILE("PCKSUBS.01X")
				DELETE FILE PCKSUBS.01X
			ENDIF
				USE PCKSUBS
				PACK
				PROGINDEX("PCKSUBS.01X","C_Memtype",.F.,.T.,.F.)
				CLOSE PCKSUBS

			IF FILE("PCKCENTRE.01X")
				DELETE FILE PCKCENTRE.01X
			ENDIF
				USE PCKCENTRE EXCLUSIVE NEW
				PROGINDEX("PCKCENTRE.01X","C_Centre",.F.,.T.,.F.)
				CLOSE PCKCENTRE

			DBCLOSEALL()
			PLSWAIT(.F.)
			TONE(400,12)
			MSG("Completed")

RETURN

******************************************
PROCEDURE Check_Files
PRIVATE aDonors := {}, aDonat := {}, aCentre := {}, aCENT_MENU[4], N_CHOICE
PRIVATE lIndex := .F., aCor := {}, aMembers := {}, aSubs := {}, aVat := {}
PRIVATE vat := 0
PLSWAIT(.T.,"CHECKING FILES")
&& Creates DBF files if they are not present
IF (!FILE("DONORS.DBF") .OR. !FILE("DONDEL.DBF"))
	AADD(aDonors, {"C_surname2","C",40,0})
	AADD(aDonors, {"C_surname","C",40,0})
	AADD(aDonors, {"C_initials","C",3,0})
	AADD(aDonors, {"C_address1","C",30,0})
	AADD(aDonors, {"C_address2","C",30,0})
	AADD(aDonors, {"C_city","C",20,0})
	AADD(aDonors, {"C_postcode","C",4,0})
	AADD(aDonors, {"C_telcode","C",5,0})
	AADD(aDonors, {"C_tel","C",7,0})
	AADD(aDonors, {"C_telext","C",5,0})
	AADD(aDonors, {"C_title","C",32,0})
	AADD(aDonors, {"C_salut","C",9,0})
	AADD(aDonors, {"L_newslett","L",1,0})
	AADD(aDonors, {"L_annualrt","L",1,0})
	AADD(aDonors, {"L_contdon","L",1,0})
	AADD(aDonors, {"C_reason","C",50,0})
	AADD(aDonors, {"N_donnum","N",5,0})
	AADD(aDonors, {"C_centre","C",1,0})
	AADD(aDonors, {"C_type","C",1,0})
	AADD(aDonors, {"C_fax","C",7,0})
	AADD(aDonors, {"L_c600","L",1,0})
	AADD(aDonors, {"L_volunt","L",1,0})
	IF !FILE("DONORS.DBF")
		DBCREATE("DONORS.DBF",aDonors)
		DBCREATE("DONDEL.DBF",aDonors)
		lIndex := .T.
	ELSE
		DBCREATE("DONDEL.DBF",aDonors)
	ENDIF
ENDIF
IF (!FILE("DONATION.DBF") .OR. !FILE("DONADEL.DBF"))
	AADD(aDonat, {"N_donnum","N",5,0})
	AADD(aDonat, {"C_centre","C",1,0})
	AADD(aDonat, {"D_date","D",8,0})
	AADD(aDonat, {"C_type","C",20,0})
	AADD(aDonat, {"N_amount","N",8,2})
	AADD(aDonat, {"C_event","C",20,0})
	AADD(aDonat, {"C_detail1","C",20,0})
	AADD(aDonat, {"C_detail2","C",20,0})
	AADD(aDonat, {"C_detail3","C",20,0})
	AADD(aDonat, {"C_detail4","C",20,0})
	AADD(aDonat, {"C_comments","C",60,0})
	IF !FILE("DONATION.DBF")
		DBCREATE("DONATION.DBF",aDonat)
		DBCREATE("DONADEL.DBF",aDonat)
		lIndex := .T.
	ELSE
		DBCREATE("DONADEL.DBF",aDonat)
	ENDIF
	
ENDIF
IF !FILE("CORRESPO.DBF")
	AADD(aCor, {"C_Corrname","C",50,0})
	AADD(aCor, {"C_centre","C",1,0})
	AADD(aCor, {"D_datsent","D",8,0})
	AADD(aCor, {"C_Subject","C",50,0})
	AADD(aCor, {"D_datrep","D",8,0})
	AADD(aCor, {"C_reply","C",50,0})
	AADD(aCor, {"N_Amount","N",8,2})
	AADD(aCor, {"C_Type","C",20,0})
	AADD(aCor, {"C_Receipt","C",5,0})
	DBCREATE("CORRESPO.DBF",aCor)
	lIndex := .T.
ENDIF

IF (!FILE("MEMBERS.DBF") .OR. !FILE("MEMDEL.DBF"))
	AADD(aMembers, {"C_surname2","C",40,0})
	AADD(aMembers, {"C_surname","C",40,0})
	AADD(aMembers, {"C_initials","C",3,0})
	AADD(aMembers, {"C_address1","C",30,0})
	AADD(aMembers, {"C_address2","C",30,0})
	AADD(aMembers, {"C_city","C",20,0})
	AADD(aMembers, {"C_postcode","C",4,0})
	AADD(aMembers, {"C_telcode","C",5,0})
	AADD(aMembers, {"C_tel","C",7,0})
	AADD(aMembers, {"C_telext","C",5,0})
	AADD(aMembers, {"C_title","C",32,0})
	AADD(aMembers, {"C_salut","C",9,0})
	AADD(aMembers, {"L_newslett","L",1,0})
	AADD(aMembers, {"L_annualrt","L",1,0})
	AADD(aMembers, {"L_contdon","L",1,0})
	AADD(aMembers, {"C_reason","C",50,0})
	AADD(aMembers, {"C_Memcode","C",9,0})
	AADD(aMembers, {"C_centre","C",1,0})
	AADD(aMembers, {"C_Type","C",1,0})
	AADD(aMembers, {"C_fax","C",7,0})
	AADD(aMembers, {"L_c600","L",1,0})
	AADD(aMembers, {"L_volunt","L",1,0})
	AADD(aMembers, {"L_Stopord","L",1,0})
	AADD(aMembers, {"N_Subs","N",5,2})
	AADD(aMembers, {"N_Vat","N",5,2})
	AADD(aMembers, {"N_Total","N",6,2})
	AADD(aMembers, {"N_Arrears","N",6,2})
	AADD(aMembers, {"D_Datpaid","D",8,0})
	AADD(aMembers, {"C_Receipt","C",5,0})
	AADD(aMembers, {"N_Amtpaid","N",7,2})
	AADD(aMembers, {"C_Memtype","C",2,0})
	AADD(aMembers, {"C_MemCent","C",1,0})
	AADD(aMembers, {"L_Paid","L",1,0})
	AADD(aMembers, {"N_Donation","N",6,2})
	IF !FILE("MEMBERS.DBF")
		DBCREATE("MEMBERS.DBF",aMembers)
		DBCREATE("MEMDEL.DBF",aMembers)
		lIndex := .T.
	ELSE
		DBCREATE("MEMDEL.DBF",aMembers)
	ENDIF
ENDIF

IF !FILE("PCKSUBS.DBF")
	AADD(aSubs, {"C_Memtype","C",2,0})
	AADD(aSubs, {"C_Memdesc","C",18,0})
	AADD(aSubs, {"N_Subs","N",5,2})
	DBCREATE("PCKSUBS.DBF", aSubs)
	TONE(400,15)
	MSG("MUST ENTER MEMBERSHIP SUBS & TYPES")
	lIndex := .T.
ENDIF

&& If no centre file - install for centre
IF !FILE("CENTRE.DBF")
	AADD(aCentre, {"C_centre","C",1,0})
	AADD(aCentre, {"C_desc","C",22,0})
	DBCREATE("CENTRE.DBF",aCentre)
	USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
	IF SMALLS("C_Desc","Choose Installation Centre","PCKCENTRE")
		Centre := PCKCENTRE->C_Centre
		CentDes := PCKCENTRE->C_Desc
	ENDIF
	CLOSE PCKCENTRE
	USE CENTRE EXCLUSIVE NEW
	APPEND BLANK
	&& Centre.dbf is the code file that tells the system at which centre it is
	&& running.  Various functions are dependant upon this.
	&& Place first character of selected description into C_centre field
	&& Place description into C_desc field
	REPLACE C_centre WITH Centre, C_desc WITH CentDes
	CLOSE CENTRE
	lIndex := .T.
ENDIF

&& Check VAT file - if none create and put VAT rate in it
IF !FILE("PCKVAT.DBF")
	AADD(aVat, {"N_Vat","N",4,1})
	DBCREATE("PCKVAT.DBF", aVat)
	USE PCKVAT EXCLUSIVE NEW
	APPEND BLANK
	POPREAD(.f.,"Enter current VAT % ", @vat, "99.9")
	FIELDPUT(1,vat)
	CLOSE PCKVAT
ENDIF
PLSWAIT(.F.)
IF lIndex = .T.
	Indexes()
ENDIF

RETURN
*********************************************
PROCEDURE Check_Backup
&& Displays message if backup not done recently
LOCAL LastDate, Diff

IF FILE("backup.arj")   && File does exist, now check date
	LastDate := FILEINFO("backup.arj",2)  && get date
	Diff := DATE() - LastDate
	IF Diff >= 7
		TONE(400,9)
		MSG("Backup last performed "+ALLTRIM(STR(Diff))+" days ago on "+DTOC(LastDate)+".",;
			"You should perform a backup at least once a week.")
	ENDIF

ELSE
	TONE(400,9)
	MSG("     No copy of the backup file exists.",;
		 "                                  ",;
		 "Make sure that you regularly perform backups!!!!")
ENDIF

RETURN
*********************************************
PROCEDURE Check_V203
&& Checks to see if database files in version 2.03 format and changes format
&& Title field has been lengthened
PRIVATE aArray := {}

IF FILE("DONORS.DBF")
	USE DONORS EXCLUSIVE NEW
	aArray := DBSTRUCT()    && Read structure of file into Array
	IF aArray[11][1] == "C_TITLE"
		IF aArray[11][3] = 20           && Still old size
			PLSWAIT(.T.,"BUSY UPDATING TO VERSION 2.04 ....")
			Upgrade_V203()                    && Do upgrade
			PLSWAIT(.F.)
		ELSE
			RETURN                            && Already upgraded
		ENDIF
	ELSE
		TONE(400,9)
		MSG("COULD NOT FIND C_TITLE FIELD")   
	ENDIF
ELSE
	TONE(400,9)
	MSG("COULD NOT OPEN DONORS.DBF FOR UPGRADE")
ENDIF

RETURN
*********************************************
PROCEDURE Upgrade_V203

&& Update Donors first
aArray[11][3] := 35    && Changes to new length
IF FILE("OLD.DBF")
	ERASE OLD.DBF
ENDIF
CLOSE DONORS                && Close it
IF FRENAME("DONORS.DBF", "OLD.DBF") = 0  && Rename file to copy from
	DBCREATE("DONORS.DBF",aArray)         && Create new structure Donors file
	USE DONORS EXCLUSIVE NEW
	APPEND FROM OLD                       && Copies to new file
	IF FILE("OLD.DBF")
		ERASE OLD.DBF
	ENDIF
	IF FILE("DONDEL.DBF")
		ERASE DONDEL.DBF
	ENDIF
	CLOSE DONORS
ELSE
	TONE(400,9)
	MSG("SERIOUS ERROR WITH RENAMING OF NEW STRUCTURE FILE! (DONORS)")
	QUIT
ENDIF

&& Now update the Title field for MEMBERS
IF FILE("MEMBERS.DBF")
	USE MEMBERS EXCLUSIVE NEW
	aArray := DBSTRUCT()            && Read structure of file into Array
	aArray[11][3] := 35        && Changes to new length
	CLOSE MEMBERS
	IF FRENAME("MEMBERS.DBF", "OLD.DBF") = 0  && Rename file to copy from
		DBCREATE("MEMBERS.DBF",aArray)         && Create new structure Members file
		USE MEMBERS EXCLUSIVE NEW
		APPEND FROM OLD                       && Copies to new file
		IF FILE("OLD.DBF")
			ERASE OLD.DBF
		ENDIF
		IF FILE("MEMDEL.DBF")
			ERASE MEMDEL.DBF
		ENDIF
		CLOSE MEMBERS
	ELSE
		TONE(400,9)
		MSG("SERIOUS ERROR WITH RENAMING OF NEW STRUCTURE FILE! (MEMBERS)")
		QUIT
	ENDIF
ELSE
	TONE(400,9)
	MSG("CANNNOT OPEN MEMBERS.DBF FOR UPGRADING")
ENDIF
&& Now update the Amount field for DONATIONS
IF FILE("DONATION.DBF")
	USE DONATION EXCLUSIVE NEW
	aArray := DBSTRUCT()            && Read structure of file into Array
	aArray[5][3] := 10              && Changes to new length
	CLOSE DONATION
	IF FRENAME("DONATION.DBF", "OLD.DBF") = 0  && Rename file to copy from
		DBCREATE("DONATION.DBF",aArray)         && Create new structure Members file
		USE DONATION EXCLUSIVE NEW
		APPEND FROM OLD                       && Copies to new file
		IF FILE("OLD.DBF")
			ERASE OLD.DBF
		ENDIF
		IF FILE("DONADEL.DBF")
			ERASE DONADEL.DBF
		ENDIF
		MSG("UPDATED TO VERSION 2.04 DATABASE","RESTART PROGRAM")
		CLOSE DONATION
		QUIT
	ELSE
		TONE(400,9)
		MSG("SERIOUS ERROR WITH RENAMING OF NEW STRUCTURE FILE! (DONATION)")
		QUIT
	ENDIF
ELSE
	TONE(400,9)
	MSG("CANNNOT OPEN DONATION.DBF FOR UPGRADING")
ENDIF

RETURN
********************************************
PROCEDURE Check_V207
&& Checks to make sure new L_Paid field is in members for other centres
PRIVATE aArray := {}

IF FILE("MEMBERS.DBF")
	USE MEMBERS EXCLUSIVE NEW
	aArray := DBSTRUCT()    && Read structure of file into Array
	IF LEN(aArray) < 33     && New field not yet added
		IF LASTREC() > 0     && Members file not empty
			IF MESSYN("Members database needs to be updated - OVERWRITE?","YES","NO")
				CLOSE MEMBERS
				DELETE FILE members.dbf
				Check_Files()
			ELSE
				MSG("You cannot proceed until the file is deleted.",;
					 "Contact the programmer if you need assistance",;
					 "to retain your old members data.",;
					 " ", "Quitting program")
				QUIT
			ENDIF
		ELSE
			CLOSE MEMBERS
			DELETE FILE members.dbf
		ENDIF
	ELSE
		CLOSE MEMBERS
		RETURN                            && Already upgraded
	ENDIF
ELSE
	TONE(400,9)
	MSG("COULD NOT OPEN MEMBERS.DBF FOR UPGRADE")
ENDIF
RETURN
********************************************
FUNCTION DbfSize
&& Calculates size required to store dbf data file

RETURN ((RECSIZE() * LASTREC()) + HEADER() + 1)
*********************************************
PROCEDURE Mem_April
Local lArrears := .F., Vat_Rate := 0

&& Get VAT rate
IF FILE("PCKVAT.DBF")
	USE PCKVAT EXCLUSIVE NEW
	DBGOTOP()
	Vat_Rate := PCKVAT->N_VAT
	CLOSE PCKVAT
ELSE
	TONE(400,9)
	MSG("NO VAT RATE FILE FOUND!")
	RETURN
ENDIF


IF FILE("MEMBERS.DBF")    && Check file exists
	TONE(600,9)
	TONE(400,14)
	TONE(600,9)
	MSG("THIS FUNCTION MUST ONLY BE RUN once A YEAR IN APRIL",;
		 "IF THIS IS THE SECOND TIME, PRESS <ESC> KEY TO EXIT",;
		 " ",;
		 "ALSO MAKE SURE THAT YOU HAVE ALREADY ADJUSTED SUBS",;
		 "TO A NEW RATE IF THEY HAVE CHANGED.  YOU MUST ADJUST",;
		 "THE SUBS before RUNNING THIS UPDATE!!!!!",;
		 " ",;
		 "THIS FUNCTION WILL CHANGE all MEMBERS TO NOT PAID, AND",;
		 "WILL ACCUMULATE ARREARS FOR MEMBERS THAT DID NOT PAY.")
	IF LASTKEY() = 27
		RETURN
	ENDIF
	TONE(400,9)
	MSG("YOU WILL NOW BE FORCED TO DO A BACKUP",;
		"PUT THE DATE ON THE BACKUP DISC AND KEEP IT.",;
		" ","PRESS <ESC> IF YOU NEED TO FORMAT A DISC",;
		"FIRST, OR PRESS ANY OTHER KEY TO CONTINUE.")
	IF LASTKEY() = 27
		RETURN
	ENDIF
	Backup(Version)
	USE PCKSUBS INDEX PCKSUBS.01X EXCLUSIVE NEW
	USE MEMBERS EXCLUSIVE NEW
	SET RELATION TO MEMBERS->C_Memtype INTO PCKSUBS
	IF LASTREC() > 0      && Only do if records entered
		PLSWAIT(.T.,"PLEASE WAIT - BUSY UPDATING MEMBERS")
		DO WHILE !EOF()
			&& Carry old totals to arrears if necessary
			IF MEMBERS->L_Paid = .F.       && These did not pay
				MEMBERS->N_Arrears := MEMBERS->N_Total
			ELSE                           && These did pay
				MEMBERS->N_Arrears := 0     && Reset Arrears to zero
			ENDIF
			MEMBERS->L_Paid := .F.         && Reset all Paid to False
			&& Work out new subs and total owed for all
			MEMBERS->N_Subs := PCKSUBS->N_Subs
			MEMBERS->N_Vat := MEMBERS->N_Subs - (MEMBERS->N_SUBS/(1+(Vat_Rate/100)))
			MEMBERS->N_Total := MEMBERS->N_Subs + MEMBERS->N_Arrears
			SKIP
		ENDDO
		PLSWAIT(.F.)
	ELSE
		TONE(400,9)
		MSG("NO RECORDS TO UPDATE YET!")
	ENDIF
	CLOSE MEMBERS
	CLOSE PCKSUBS
ELSE
	TONE(400,9)
	MSG("COULD NOT OPEN MEMBERS.DBF TO UPDATE PAID FIELD")
ENDIF


RETURN
*********************************************
PROCEDURE Mem_August

&& Just clears arrears for no-paid members
IF FILE("MEMBERS.DBF")    && Check file exists
	TONE(600,9)
	TONE(400,14)
	TONE(600,9)
	MSG("THIS FUNCTION MUST ONLY BE RUN once A YEAR IN AUGUST",;
		 "IF THIS IS THE SECOND TIME, PRESS <ESC> KEY TO EXIT",;
		 " ",;
		 "IT WILL RESET ALL OUTSTANDING ARREARS TO ZERO AND ",;
		 "CALCULATE NEW TOTALS BASED ON ZEROED ARREARS. IT WILL",;
		 "NOT RESET PAID MEMBERS TO NOT PAID")
	IF LASTKEY() = 27
		RETURN
	ENDIF
	TONE(400,9)
	MSG("YOU WILL NOW BE FORCED TO DO A BACKUP",;
		"PUT THE DATE ON THE BACKUP DISC AND KEEP IT.",;
		" ","PRESS <ESC> IF YOU NEED TO FORMAT A DISC",;
		"FIRST, OR PRESS ANY OTHER KEY TO CONTINUE.")
	IF LASTKEY() = 27
		RETURN
	ENDIF
	Backup(Version)
	USE MEMBERS EXCLUSIVE NEW
	IF LASTREC() > 0      && Only do if records entered
		PLSWAIT(.T.,"PLEASE WAIT - BUSY UPDATING MEMBERS")
		DO WHILE !EOF()
			&& Reset arrears and calculate new total
			IF MEMBERS->L_Paid = .F.       && These did not pay
				MEMBERS->N_Arrears := 0     && Clear arrears
				&& Work out new total owed for members
				MEMBERS->N_Total := MEMBERS->N_Subs
			ENDIF
			SKIP
		ENDDO
		PLSWAIT(.F.)
	ELSE
		TONE(400,9)
		MSG("NO RECORDS TO UPDATE YET!")
	ENDIF
	CLOSE MEMBERS
ELSE
	TONE(400,9)
	MSG("COULD NOT OPEN MEMBERS.DBF TO UPDATE PAID FIELD")
ENDIF


RETURN
*********************************************