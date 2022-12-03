#include "box.ch"
#include "keys.ch"
#include "values.ch"

PROCEDURE Conv_Main
LOCAL counter := 0, x := 0
SET DELETE ON
SET CURSOR ON
SET SCOREBOARD OFF
SET WRAP ON
SET DATE TO BRITISH      && dd/mm/yy
SET INTENSITY ON
INITSUP()
CLEAR SCREEN


PRIVATE aDonors := {}

IF FILE("DONORS.DBF")
	USE DONORS EXCLUSIVE NEW
	IF FIELDNAME(1)="C_SURNAME2"
		MSG("DATABASE ALREADY CONVERTED!!!!")
		CLOSE DONORS
		QUIT
	ELSE
		PLSWAIT(.T.,"MAKING NEW STRUCTURE")
		CLOSE DONORS
		RENAME DONORS.DBF TO OLDONORS.DBF
		IF !FILE("DONORS.DBF")
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
			AADD(aDonors, {"C_title","C",20,0})
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
			DBCREATE("DONORS.DBF",aDonors)
		ENDIF
		USE OLDONORS EXCLUSIVE NEW
		USE DONORS EXCLUSIVE NEW
		SELECT DONORS
		PLSWAIT(.F.)
		PROGON("COPYING FILES ACROSS")
		DO WHILE .NOT. OLDONORS->(EOF())
			counter++
			PROGDISP(counter, OLDONORS->(RECCOUNT()))
			APPEND BLANK
			IF (OLDONORS->C_TYPE<>"P")
				FIELDPUT(1, OLDONORS->(FIELDGET(2)))
				FIELDPUT(2, OLDONORS->(FIELDGET(1)))
			ELSE
				FIELDPUT(1, OLDONORS->(FIELDGET(1)))
				FIELDPUT(2, OLDONORS->(FIELDGET(2)))
			ENDIF
			FOR x := 3 TO 22
				FIELDPUT(x, OLDONORS->(FIELDGET(x)))
			NEXT
			OLDONORS->(DBSKIP())
		ENDDO
		PROGOFF()
		TONE(600,18)
		MSG("COMPLETED")
		CLEAR SCREEN
	ENDIF	
ELSE
	MSG("CANNOT FIND 'DONORS.DBF'!!!!")
	QUIT
ENDIF
QUIT

RETURN