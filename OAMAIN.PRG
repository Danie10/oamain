&& OAMAIN.PRG Written by DF van der Merwe
&& System analysis by Teresa Schultz
&& Version 1.00 BETA Started 1993-06-06  - Installed 1993-06-30
&& Version 1.01 1993-07-05 Menu's improved, Reports expanded
&& Version 1.02 1993-08-19 Fields added for Donors -> volunteer, club 600, fax
&&              Correspondence -> cash amount.  Reports also work on these new
&&              fields.  Fixed bug that crashed when exiting correspondence.
&&              Date format is now dd/mm/yy.  Can also print all donors.
&& Version 1.03 1993-08-22 Added emphasised printing and condensed printing.
&& Version 2.00 1993-09-22 Includes members data, improved browse titles
&&              printouts to screen, mailmerge in postal code order,
&&              queries added for donors and donations.
&& Version 2.01 1993-10-27 Generates installation discs, correspondence has 2
&&              new fields C_Type and C_Receipt, caps lock switches off,
&&              prints out receipt for money received from corresp, saves
&&              deleted members, if run from floppy tries to install to 
&&              C:\DONORS, also prints to labels now, fixed fault not copying
&&              PCKCENTR onto installation disc.
&& Version 2.02 1994-01-30 Added DR & MRS and REV & MRS titles, prints surnames
&&              in capitals now, EMS support now enabled in linking, new 
&&              oBrowse:forceStabilize Clipper 5.2 function used in browse,
&&              warns when backup is due, displays runtime info.
&& Version 2.03 94-02-01 Added extra field to memeber's database to allow mem
&&              to be linked to a particular centre (only admin centre can book
&&              for other centres, other centres default to their own centre).
&&              Help for members' entry screens updated, moves members to a
&&              different type, eg from private to company.
&& Version 2.04 94-08-08 Automatically detects old databases and updates length
&&              of Title field to 35 characaters and Amount for donations to
&&              10 including point and decimals. Included Date on Donation Query
&&              printout and lengthened Detail 1 & 2 printout fields. Changed
&&              index keys for dates to DTOS which orders dates correctly.
&&              Query prints out below the printout.
&& Version 2.05 94-08-22 Corrects filter problem on reports for Donors on 
&&              newsletters, etc.  It also defaults to Company column when
&&              entering the browse.  Minor help update.
&& Version 2.06 94-09-26 Added new fields to members printout, Added subtotal
&&              to donations printout. Users can themselves setup labels.
&& Version 2.07 95-03-07 Adds a logic field to MEMBERS.DBf for paid and allows
&&              global updating of paid field.  WordPerfect Mailmerge. Fixed
&&              bug that did not save subs.  Centered main title and added a
&&              line at the bottom about F1 key.  Updated help for WP option.
&&              Also added a Donation amount field to Members.  Prompts before
&&              overwriting code files during installation.
&& Version 2.08 95-03-15 Allows empty saluation field if it is a company or
&&              trust.  You can move over pick list fields using the arrow keys.
&&              You can now format a disc from the utility menu - to the
&&              highest capacity for the A drive only.  Option on Utils menu
&&              to calculate the actual subs based on the total required for
&&              members.
&& Version 2.09 95-03-25 Allows total paid for members up to R9999.  Allows sub
&&              including VAT now.
&& Version 2.10 95-09-27 Recomplied using Blinker 3.01 linker
&& Version 2.11 99-11-17 Checked Y2K compliancy. Recompiled with new contact details.
&&
&& LINKS OAMAIN, DONORS, DONATION, CORRESPO, S_EDIT, MICROSCR, MEMBERS,
&&       REPORTS, UTILS
&& BLINKER @OAMAIN
&& LIB EXTEND, SUPER30
&&
&& DATABASE DONOR.DBF   && Donor details
&& INDEXES  DONOR.01X C_SURNAME+C_INITIALS
&&          DONORS.02X C_SURNAME2
&&          DONORS.03X C_CENTRE+STR(N_Donnum)
&&          DONORS.04X C_POSTCODE
&& DATABASE DONATION.DBF  && Donation details for donors
&& INDEXES  DONATION.01X C_CENTRE+STR(N_DONNUM)
&&          DONATION.02X STR(N_DONNUM)+DTOS(D_DATE)
&&          DONATION.03X STR(N_Donnum)
&&          DONATION.04X STR(N_AMOUNT)
&& DATABASE DONDEL.DBF  Deleted donors
&& DATABASE DONADEL.DBF Deleted donations
&& DATABASE CORRESPO.DBF Correspondence
&& INDEXES  CORRESPO.01X C_Centre+RTRIM(C_Corrname)+DTOC(d_datsent)
&&          CORRESPO.02X C_Centre+RTRIM(C_Corrname)
&&				CORRESPO.03X DTOS(d_datsent)
&&          CORRESPO.04X C_Type
&& DATABASE PCKCENTRE.DBF Code file for centres
&& INDEX    PCKCENTRE.01X C_Centre
&& DATABASE CENTRE.DBF  File that tells system where it is installed
&& DATABASE MEMBERS.DBF Member details
&& INDEXES  MEMBERS.01X C_SURNAME+C_INITIALS
&&          MEMBERS.02X C_SURNAME2
&&          MEMBERS.03X C_CENTRE+C_MEMCODE
&&          MEMBERS.04X N_ARREARS
&&          MEMBERS.05X C_POSTCODE
&& DATABASE PCKSUBS.DBF  Code file for members' subs & member types
&& INDEXES  PCKSUBS.01X  C_MEMTYPE
&& DATABASE PCKVAT  && Code file for vat rate
&& This program is a general admin system written for Oasis.  The first 
&& release registers donors and then allows registering of donations
&& by those donors.  Donors records can be sent by floppy from outside
&& to Admin Centre.
&& Super Lib 3.0 customized browses used for editing, data entry & viewing.

PROCEDURE Main  

#include "box.ch"
#include "keys.ch"
#include "values.ch"
EXTERNAL HELP
&& This is where the version number is updated for main screen display
LOCAL Version := "2.11"
LOCAL N_CHOICE := 0, cont := .T.
PRIVATE aMAIN_MENU[5], Centre := "A", Long_Centre, YEAR := "", TMPSTRVAR := "" 
PRIVATE cOrgan := "OASIS ASSOCIATION FOR THE MENTALLY HANDICAPPED"
 
SET DELETE ON
SET CURSOR ON
SET SCOREBOARD OFF
SET WRAP ON
SET DATE TO BRITISH      && dd/mm/yy
SET INTENSITY ON
SET KEY pF1 TO HELP      && F1 to activate help
&& Include following line to enable F2 to edit help
&& SET KEY pF2 TO HELPMOD   && F2 for developing help
YEAR := STR(YEAR(DATE()) - 1900,2,0)
CAPSLOCK(.T.)
INITSUP()

********************************************
&& Main menu routine


CLS()
TMPSTRVAR := BLISERNUM()
MAKEBOX(4,15,19,64,sls_popcol(),sls_shadpos())
@ 5,31 SAY "LICENCE: " + SUBSTR(TMPSTRVAR,21,5)
@ 9,27 SAY "For asssistance contact"
@ 11,23 SAY "Danie v/d MERWE Tel 083 000 0000"
@ 12,19 SAY "Teresa v/d MERWE Tel 082 0000 000 "
@ 14,22 SAY "For use at " + RTRIM(SUBSTR(TMPSTRVAR,1,20)) + " only"
@ 18,17 SAY "IT MAY NOT BE COPIED OR OTHERWISE DISTRIBUTED"
@ 24,31 SAY "Press any key...."
INKEY(5)
CLS()
&& Checks to see if run from floppy, do install
IF UPPER(CURD()) = "A" .OR. UPPER(CURD()) = "B"
	Installation(Version)
ENDIF
&& Procedure checks for existence of DBF files
Check_Files()
&& Procedure checks for version 2.04 file structure and updates if necessary
Check_V203()
&& Procedure checks for version 2.07 file structure
Check_V207()
&& Warns if backup not done recently
CLOSE DATABASES
Check_Backup()
USE Centre  && Get Centre where database is operating
Centre := Centre->C_Centre
Long_Centre := ALLTRIM(Centre->C_Desc)
CLOSE Centre

DO WHILE cont
CLS()
MAINSCR(Long_Centre, CMONTH(DATE())+STR(YEAR(DATE())),Version)
aMAIN_MENU[1]:="A. DONATIONS"
aMAIN_MENU[2]:="B. MEMBERS"
aMAIN_MENU[3]:="C. CORRESPONDENCE"
aMAIN_MENU[4]:="D. UTILITIES"
aMAIN_MENU[5]:="E. EXIT TO DOS"
N_CHOICE := MCHOICE(m->aMAIN_MENU,7,23,15,55,"MAIN MENU",.t.)
IF LASTKEY() = 27
	IF MESSYN("Do you want to Quit?")
		CLS()
		CAPSLOFF()
		QUIT
	ENDIF
ENDIF

DO CASE
     CASE N_CHOICE = 1
	       Donors_Menu()
     CASE N_CHOICE = 2
			 Members_Menu()
  	CASE N_CHOICE = 3
			 Correspon()	  
	  CASE N_CHOICE = 4
	  		 Util_Menu(Version)
	  CASE N_CHOICE = 5
             cont := .F.
			 CLS()
			 CAPSLOFF()
			 QUIT
ENDCASE

ENDDO

RETURN
*******************************************
FUNCTION Expand_Centre   && Returns Description
PARAMETERS Short_Centre
LOCAL Oldarea := SELECT(), lOpen := .F., Long_Centre := ""

IF SELECT("PCKCENTRE") = 0      && Not open yet
	lOpen := .F.
	USE PCKCENTRE INDEX PCKCENTRE.01X EXCLUSIVE NEW
ELSE
	lOpen  := .T.
	SELECT SELECT("PCKCENTRE")   && Otherwise select that workarea
ENDIF
SEEK Short_Centre
IF FOUND()
	Long_Centre := RTRIM(PCKCENTRE->C_Desc)
ELSE
	Long_Centre := "LOST LINK!"
ENDIF

IF lOpen = .F.         && Freshly opened
	CLOSE PCKCENTRE
ENDIF
SELECT (Oldarea)

RETURN Long_Centre

*******************************************
FUNCTION Expand_Order
PARAMETERS cOrder
LOCAL cType := ""
DO CASE

	CASE cOrder = "C"
		cType := "Company"
	CASE cOrder = "T"
		cType := "Trust"
	CASE cOrder = "P"
		cType := "Private"
	CASE cOrder = "A"
		cType := "All"
	CASE cOrder = "Q"
		cType := "Query"

END CASE
RETURN RTRIM(cType)

*********************************************
FUNCTION Check_Salutation
PARAMETERS Sal_Type
PRIVATE aTYPE_MENU[19], N_CHOICE := 0

aTYPE_MENU[1] := "MR"
aTYPE_MENU[2] := "MRS"
aTYPE_MENU[3] := "MR & MRS"
aTYPE_MENU[4] := "MISS"
aTYPE_MENU[5] := "MS"
aTYPE_MENU[6] := "PROF"
aTYPE_MENU[7] := "DR"
aTYPE_MENU[8] := "DR & MRS"
aTYPE_MENU[9] := "THE HON"
aTYPE_MENU[10] := "REV"
aTYPE_MENU[11] := "REV & MRS"
aTYPE_MENU[12] := "MNR"
aTYPE_MENU[13] := "MEV"
aTYPE_MENU[14] := "MNR & MEV"
aTYPE_MENU[15] := "MEJ"
aTYPE_MENU[16] := "ME"
aTYPE_MENU[17] := "SY EDELE"
aTYPE_MENU[18] := "DS"
aTYPE_MENU[19] := "DS & MEV"
SET EXACT ON
N_CHOICE := ASCAN(aTYPE_MENU,ALLTRIM(Sal_Type))  
										&& Scans array to see if field already
										&& contains the choice. If found returns
										&& matching choice no 
IF N_CHOICE = 0   && Not found
	N_CHOICE := MCHOICE(m->aTYPE_MENU,10,40,18,59,"SALUTATION",.t.,N_CHOICE)
	IF N_CHOICE > 0
		Sal_Type := PADR(aTYPE_MENU[N_CHOICE],LEN(Sal_Type))
	ELSE
		RETURN .F.
	ENDIF
ENDIF

&& aGet[12] :=  Sal_Type

RETURN .T.

********************************************
&& End of File
********************************************