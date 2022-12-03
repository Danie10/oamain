/* Browse DONOR is  for Donors
   Browse DONATION is for Donations
	Browse CORRES is for Correspondence
	Browse CORRDON is for picklist for Correspondence donor
	Browse MEMBERS is for members
	Browse CENTRES is for editing centre list
   Browse QUERY RESULT is for all queries/reports to screen
*/


#include "inkey.ch"

FUNCTION editdb(lAddEdit,aInFields,aInFdescr,lBypassAsk,Browse)
FIELD C_Centre
local nDbSize, nIter
local aFields := {}
local aFdescr := {}
local aSelect, cMemBox,cMemo
local nIndexOrder,cInScreen,nOldCursor
local nCounter,nChoice,cOldColor
local oBrowse, nLkey,cLkey,bOldF10
local cFieldName,cFieldDes, cDeleted
local nrecnoNew,nRecnoOld, cIndexExpr
local bIndexExpr, aView, nLenDesc, nPadding
local nNewCol, aTypes, aLens, cThisType, expGet
local nRow,nCol, cEditScreen,cEditColor
local nFreeze := 0
local getlist := {}
local cEdScreen

local expSeekVar, nLastSeek, lIndexes

* is there a DBF ?
IF !Used()
  RETURN ''
ENDIF

*- save environment ----------------------------------------------
cInscreen  := savescreen(0,0,24,79)
nOldCursor := setcursor(0)

*----- determine index key current----------------------------
cIndexExpr := INDEXKEY(0)
if !empty(cIndexExpr)
  bIndexExpr := &("{||"+cIndexExpr+"}")
endif
lIndexes := !empty(indexkey(1))


*- initialize missing paramaters-------------------------------
lAddEdit   := iif(laddEdit#nil,lAddEdit,.f.)
lByPassAsk := iif(lByPassAsk#nil,lByPassAsk,.f.)
if valtype(aInFields)+valtype(aInFdescr)<>"AA"
  nDbSize   := Fcount()
  aInFields := array(nDbSize)
  aInFdescr := array(nDbSize)
  aFields(aInFields)
  aFields(aInFdescr)
else
  nDbSize := len(aInFdescr)
ENDIF

*--------- determine fields-----------------------------------
selfields(aInFields,aInFdescr,aFields,aFDescr,lByPassAsk)
aTypes := array(len(aFields))
aLens  := array(len(aFields))
fillarr(aFields,aTypes,aLens)


*---------- draw screen----------------------------------------
DISPBEGIN()
cOldColor   := Setcolor(sls_popcol())
@ 0,0 CLEAR TO  24,79
dispbox(0,0,2,79)
dispbox(21,0,24,79)

IF Browse = "DONORS"
	@ 22,2 SAY "(Q)uit     (D)onations   (S)earch       (V)ertical View   (P)rint     "
ELSEIF Browse = "CENTRES"
	@ 22,2 SAY "(Q)uit     (S)earch      (V)ertical View    (O)rder                   "
ELSE
	@ 22,2 SAY "(Q)uit     (S)earch      (V)ertical View    (O)rder       (P)rint     "
ENDIF

IF lAddEdit .AND. Browse = "DONORS"
   @ 23,2 say "(E)dit     (A)dd         (R)emove       (M)ove    (L)ock  (O)rder"
ELSEIF lAddEdit .AND. Browse = "CENTRES"
   @ 23,2 say "(E)dit     (A)dd         (R)emove           (G)enerate    (L)ock"
ELSEIF lAddEdit .AND. Browse = "MEMBERS"
   @ 23,2 say "(E)dit     (A)dd         (R)emove           (M)ove        (L)ock         "
ELSEIF Browse = "QUERY RESULT"
	@ 23,2 say " "
ELSE
   @ 23,2 say "(E)dit     (A)dd         (R)emove           (L)ock"
ENDIF

@1,50 SAY  " (F1 for Help)"
IF (Browse = "DONOR" .OR. Browse = "MEMBERS")
	@0,5  SAY Browse + " BROWSE" + " - " + Expand_Order(Type)  && Title for browse
ELSE
	@0,5  SAY Browse + " BROWSE"  && Title for browse
ENDIF
SETCOLOR(sls_normcol())
dispbox(3,0,20,79,"ฺฤฟณูฤภณ ")
DISPEND()

//-----------create tbrowse --------------------------------
oBrowse := maketb(aFields,aFdescr,aTypes)

while .t.
   dispbegin()
&&   while !oBrowse:stabilize()  Replaced with new 5.2 code
&&   end
	oBrowse:forceStable()
   nRow     := ROW()
   nCol     := COL()
   nRecnoOld := recno()

   cfieldName  :=  aFields[oBrowse:colpos]
   cFieldDes   :=  aFdescr[oBrowse:colpos]
   cDeleted    := IIF(DELETED(),"  [Deleted]","           ")
   @1,5 say '[Record # '+TRANS(RECNO(),'9,999,999,999')+']'+cDeleted ;
                color sls_popcol()
   dispend()

   nLkey := inkey(0)
   cLkey := upper(chr(nLkey))
   do case
   case nLkey == K_DOWN
      oBrowse:down()
   case nLkey == K_PGDN
      oBrowse:pagedown()
   case nLkey == K_UP
      oBrowse:up()
   case nLkey == K_PGUP
      oBrowse:pageup()
   case nLkey == K_CTRL_PGUP
      oBrowse:gotop()
   case nLkey == K_CTRL_PGDN
      oBrowse:gobottom()

   case nLkey == K_LEFT
      oBrowse:left()
   case nLkey == K_RIGHT
      oBrowse:right()
   case nLkey == K_CTRL_RIGHT
      oBrowse:panright()
   case nLkey == K_CTRL_LEFT
      oBrowse:panleft()
   case nLkey == K_HOME
      oBrowse:home()
   case nLkey == K_END
      oBrowse:end()
   case nLkey == K_CTRL_END
      oBrowse:colpos := obrowse:colcount
      oBrowse:refreshall()
   case nLkey == K_CTRL_HOME
      oBrowse:colpos := 1
      oBrowse:refreshall()
	case nLkey == K_ENTER
		IF Browse = "CORRDON"
			Gotit := .T.
			EXIT
		ENDIF

   CASE cLkey == "L"
     PopRead(.F.,'Number of columns to Lock: ',@nFreeze,'9')
     oBrowse:freeze := nFreeze
     oBrowse:refreshall()

   CASE cLkey=="K" .AND. lIndexes
     SPOPSEEK()
     oBrowse:rowpos = 1
     oBrowse:configure()
     oBrowse:refreshall()

   CASE cLkey=="O" .AND. lIndexes
     SPOPORDER()
     oBrowse:refreshall()

   CASE cLkey=="Q" .or. nLkey = K_ESC
     IF messyn("Quit ")
       IF Browse = "CORRDON"
		 	Gotit := .F.
		 ENDIF
		 EXIT
     ENDIF

   CASE nLkey = K_F1
     db_navig()

	CASE cLkey=="M"
		IF Browse = "DONORS"
			Move_Donor(DONORS->C_Type)
			oBrowse:refreshall()
		ELSEIF Browse = "MEMBERS"
			Move_Donor(MEMBERS->C_Type)
			oBrowse:refreshall()
		ENDIF

	CASE cLkey=="P"   && Print Donor details
		IF (Browse = "DONORS" .OR. Browse = "DONATION")
			Print_Donor()
		ELSEIF Browse = "MEMBERS"
			Print_Member()
		ELSEIF Browse = "CORRES"
			Print_Receipt()
		ENDIF

	CASE cLkey=="G"
		IF Browse = "CENTRES"
			Gen_Centre()
		ENDIF

   CASE cLkey=="F"
      selfields(aInFields,aInFdescr,aFields,aFDescr,.f.)
      aTypes := array(len(aFields))
      aLens  := array(len(aFields))
      fillarr(aFields,aTypes,aLens)
      oBrowse := maketb(aFields,aFdescr,aTypes)
      oBrowse:configure()
      oBrowse:refreshall()

   CASE cLkey=="S"
     searchme(aFields,aTypes,aLens)
     oBrowse:refreshall()

   CASE cLkey=="R" .AND. lAddEdit
     	  	IF ((Browse="DONORS" .OR. Browse="DONATION" .OR. ;
					Browse="CORRESPO" .OR. Browse="MEMBERS") ;
								.AND. (C_Centre <> Centre))
  				TONE(400,9)
				MSG("CANNOT REMOVE DATA FROM ANOTHER CENTRE")
	  		ELSEIF Browse = "DONOR"
				TONE(400,12)
				IF MESSYN("Remove Donor and all related Donations")
	  				Remove_Donor()
   			ENDIF
  	  		ELSEIF Browse = "DONATION"
  				TONE(400,12)
				IF MESSYN("Remove this Donation?")
					Rem_Donation()
				ENDIF
   		ELSEIF Browse = "CORRES"
				TONE(400,12)
				IF MESSYN("Remove this Correspondence?")
					Rem_Corres()
				ENDIF
			ELSEIF Browse = "MEMBERS"
				TONE(400,12)
				IF MESSYN("Remove this member? (Y/N)")
					Remove_Member()
				ENDIF
			ELSEIF Browse = "CENTRES"
				TONE(400,12)
				IF MESSYN("ARE YOU SURE? (Y/N)")
					DELREC()
				ENDIF
			ENDIF
  oBrowse:refreshall()

   CASE cLkey=="E"  .AND. lAddEdit
     cEdScreen := SAVESCREEN(0,0,24,79)
     DISPBOX(0,0,24,79,"ฑฑฑฑฑฑฑฑฑ")

	  IF ((Browse <> "CENTRES") .AND. (C_Centre = " "))
	  		TONE(400,9)
			MSG("NO DATA TO EDIT","FIRST ADD")
	  ELSE
	  		IF ((Browse <> "CENTRES") .AND. (C_Centre <> Centre))
  				TONE(400,9)
				MSG("CANNOT EDIT DATA FROM ANOTHER CENTRE")
	  		ELSE
	  			IF Browse = "DONORS"
  					Edit_Donor()
  				ELSEIF Browse = "DONATION"
  					Edit_Donation()
				ELSEIF Browse = "CORRES"
					Edit_Corres()
				ELSEIF Browse = "MEMBERS"
					Edit_Member()
  				ELSEIF Browse = "CENTRES"
					Edit_Centre()
				ENDIF
	  		ENDIF
	  ENDIF
	  oBrowse:Refreshall()
     SS_FADE(0,0,24,79,cEdScreen)

	CASE cLkey=="D"      && Donation
		IF Browse =  "DONORS"
  			Donation_Browse()
  		ENDIF
  		oBrowse:Refreshall()

   CASE cLkey=="V"
     aView := aclone(aFdescr)
     FOR nCounter = 1 TO len(aFields)
       cFieldname := aFields[nCounter]
       cThisType  := aTypes[nCounter]
       nLenDesc   := LEN(aFdescr[nCounter])
       nPadding   := 15-nLenDesc

       *- complete the array element with the current value
       DO CASE
       CASE !isfield(cFieldName)
         aView[nCounter] += SPACE(nPadding)+TRANS(eval(getexpb(cFieldName)),"")
       CASE cThisType == "C"
         aView[nCounter] +=SPACE(nPadding)+LTRIM( eval(getwb(cfieldname)) )
       CASE cThisType == "D"
         aView[nCounter] +=SPACE(nPadding)+DTOC( eval(getwb(cfieldname)) )
       CASE cThisType == "N"
         aView[nCounter] +=SPACE(nPadding)+LTRIM(STR( eval(getwb(cfieldname)) ))
       CASE cThisType == "L"
         aView[nCounter] +=SPACE(nPadding)+IIF(eval(getwb(cfieldname)),'True','False')
       ENDCASE

     NEXT
     *- achoice it - view only
     nNewCol = mchoice(aView,5,10,20,75)
     IF nNewCol > 0
       oBrowse:colpos := nNewCol
       oBrowse:refreshall()
     ENDIF

   CASE cLkey=="A" .AND. lAddEdit      // add
     SET CURSOR ON
     cEdScreen := SAVESCREEN(0,0,24,79)
     DISPBOX(0,0,24,79,"ฑฑฑฑฑฑฑฑฑ")
	  IF Browse = "DONORS"
     		Add_Donor()
	  ELSEIF Browse = "CORRES"
	  		Add_Corres()
	  ELSEIF Browse = "MEMBERS"
	  		Add_Member()
	  ELSEIF Browse = "DONATION"         
	  		IF (DONORS->C_Centre <> Centre)
				TONE(400,9)
				MSG("CANNOT ADD DONATIONS FOR ANOTHER CENTRE'S DONOR!", ;
						"contact that Centre so they can add the donation")
			ELSE
				Add_Donation()
			ENDIF
     ELSEIF Browse = "CENTRES"
	  		Add_Centre()
	  ENDIF
     oBrowse:Refreshall()
	  SS_FADE(0,0,24,79,cEdScreen)
   endcase

End
* restore environment
setcursor(nOldCursor)
SS_FADE(0,0,24,79,cInScreen)
Setcolor(cOldColor)
return ''

//=================================================================
static FUNCTION v_editd(nRow)
IF nRow >=10
  dispbox(5,28,7,62,sls_frame())
  @6,29 SAY "Enter to Save - Escape to Cancel"
ELSE
  dispbox(12,28,14,62,sls_frame())
  @13,29 SAY "Enter to Save - Escape to Cancel"
ENDIF
RETURN ''

//=================================================================
STATIC FUNCTION db_navig
LOCAL cNavBox
cNavBox = makebox(4,4,23,70,sls_popcol())
IF Browse = "DONORS"
&& @5,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@6,5 SAY "                       DONORS HELP"         
@7,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@8,5 SAY  " The keys at the bottom of the screen indicate the actions"
@9,5 SAY  " that will be carried out.                                "
@10,5 SAY " Key        "
@11,5 SAY " ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ"
@12,5 SAY " <A> Add new donors            <D> Donations Browse"
@13,5 SAY "                                                            "
@14,5 SAY " <E> Edit existing donors      <S> Search for a donor"
@15,5 SAY "                                                           "
@16,5 SAY " <R> Remove donor and donations<L> Lock columns"
@17,5 SAY "                                              "
@18,5 SAY " <F> View certain fields       <O> Change viewing order"
@19,5 SAY "                           "
@20,5 SAY " <P> Print donor details       <M> Move to another type   "
@21,5 SAY "                                   eg Private donor to company"
&& @22,5 SAY " อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
ELSEIF Browse = "DONATION"
&& @5,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@6,5 SAY "                     DONATIONS HELP"         
@7,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@8,5 SAY  " The keys at the bottom of the screen indicate the actions"
@9,5 SAY  " that will be carried out.                                "
@10,5 SAY " Key        "
@11,5 SAY " ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ"
@12,5 SAY " <A> Add new donation          <S> Search for a donation"
@13,5 SAY "                                                            "
@14,5 SAY " <E> Edit existing donation    <L> Lock columns"
@15,5 SAY "                                                           "
@16,5 SAY " <R> Remove a donation"
@17,5 SAY "                                              "
@18,5 SAY " <F> Select certain fields to view                   "
@19,5 SAY "                           "
@20,5 SAY " <P> Print donor and their donations details                                  "
@21,5 SAY "                                   "
&& @22,5 SAY " อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"

ELSEIF Browse = "CORRES"
&& @5,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@6,5 SAY "                   CORRESPONDENCE HELP"         
@7,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@8,5 SAY  " The keys at the bottom of the screen indicate the actions"
@9,5 SAY  " that will be carried out.                                "
@10,5 SAY " Key                                                     "
@11,5 SAY " ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ"
@12,5 SAY " <A> Add new correspondence     <O> Change viewing order    "
@13,5 SAY "                                                             "
@14,5 SAY " <E> Edit existing correspondence                            "
@15,5 SAY "                                                            "
@16,5 SAY " <R> Remove correspondence      <L>ock                       "
@17,5 SAY "                                               "
@18,5 SAY " <S> Search for correspondence "
@19,5 SAY "                           "
@20,5 SAY " <P> Print a receipt for money received                   "
@21,5 SAY "       "
&& @22,5 SAY " อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"

ELSEIF Browse = "CENTRES"
&& @5,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@6,5 SAY "                        CENTRES HELP"         
@7,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@8,5 SAY  " The keys at the bottom of the screen indicate the actions"
@9,5 SAY  " that will be carried out.                                "
@10,5 SAY " Key                                                     "
@11,5 SAY " ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ"
@12,5 SAY " <A> Add new centre - make sure there are no other centres  "
@13,5 SAY "     with the SAME code                                     "
@14,5 SAY " <E> Edit existing centre                                 "
@15,5 SAY "                                                            "
@16,5 SAY " <R> Remove centre                                 "
@17,5 SAY "                                               "
@18,5 SAY " <S> Search for centre               "
@19,5 SAY "                                                 "
@20,5 SAY " <G> Generates an installation/upgrade disc for a centre    "
@21,5 SAY "                                                          "
&& @22,5 SAY " อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"

ELSEIF Browse = "MEMBERS"
&& @5,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@6,5 SAY "                       MEMBERS HELP"         
@7,5 SAY " ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"
@8,5 SAY  " The keys at the bottom of the screen indicate the actions"
@9,5 SAY  " that will be carried out.                                "
@10,5 SAY " Key                                                     "
@11,5 SAY " ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ"
@12,5 SAY " <A> Add new members           <P> Print member's details    "
@13,5 SAY "                                                             "
@14,5 SAY " <E> Edit existing members     <O> Change viewing order     "
@15,5 SAY "                                                            "
@16,5 SAY " <R> Remove members            <M> Move to different type   "
@17,5 SAY "                                "
@18,5 SAY " <S> Search for members        <L> Lock columns              "
@19,5 SAY "                                                 "
@20,5 SAY " <F> Select only certain fields to view                   "
@21,5 SAY " "
&& @22,5 SAY " อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"

ELSE
	@13,5 SAY "                NO HELP AVAILABLE"
ENDIF
INKEY(30)
unbox(cNavBox)
RETURN ''

//=================================================================
static function dskip(n)
  local skipcount := 0
  do case
  case n > 0
    do while !eof().and. skipcount < n
      dbskip(1)
      if !eof()
        skipcount++
      endif
    enddo
  case n < 0
    do while !bof() .and. skipcount > n
      dbskip(-1)
      if !bof()
        skipcount--
      endif
    enddo
  endcase
  if eof()
    dbgobottom()
  elseif bof()
    dbgotop()
  endif
return skipcount

static function getexpb(combo)
local bBlock
bBlock := &("{||"+combo+"}")
return bBlock

static function getwb(combo)
local workarea
if "->"$combo
  workarea := select( getalias(combo) )
else
  workarea := select()
endif
return fieldwblock(getfield(combo),workarea)

//-------------------------------------------------------------------------
static function getalias(combo)
if "->"$combo
  return left(combo,at("-",combo)-1)
else
  return alias()
endif
return ''

//-------------------------------------------------------------------------
static function getfield(combo)
if "->"$combo
  return subst(combo,at(">",combo)+1)
else
  return combo
endif
return ''

//-------------------------------------------------------------------------
static function selfields(aInFields,aInFdescr,aFields,aFDescr,lBypassAsk)
local aSelect
local i
IF !lByPassAsk .and. ;
     !messyn("Field Selection:","Browse all fields","Select fields") .and. lastkey()#27
  aSelect := tagarray(aInFdescr,"Tag Fields for Browse")
  if len(aSelect) > 0
    asize(aFields,len(aSelect))
    asize(aFdescr,len(aSelect))
    for i = 1 to len(aSelect)
      aFields[i] := aInFields[aSelect[i]]
      aFDescr[i] := aInFdescr[aSelect[i]]
    next
  else
   aSize(aFields,len(aInFields))
   aSize(aFDescr,len(aInFdescr))
   acopy(aInFields,aFields)
   acopy(aInFdescr,aFdescr)
  endif
ELSE
   aSize(aFields,len(aInFields))
   aSize(aFDescr,len(aInFdescr))
   acopy(aInFields,aFields)
   acopy(aInFdescr,aFdescr)
ENDIF
return nil

//------------------------------------------------------------
static function maketb(aFields,aFdescr,aTypes)
local nIter, cFieldName
local oBrowse := tbrowseNew(4,1,19,78)
for nIter = 1 to len(aFields)
   if aTypes[nIter]=="M"
    cFieldName := aFields[nIter]
    oBrowse:addColumn(TBColumnNew( aFdescr[nIter],{||"(memo)"}  ) )
   elseif isfield(aFields[nIter])
    oBrowse:addcolumn(TBColumnNew( aFdescr[nIter],getwb(aFields[nIter])))
   else
    oBrowse:addcolumn(TBColumnNew( aFdescr[nIter],getexpb(aFields[nIter])))
   endif
next
oBrowse:gobottomblock := {||dbgobottom()}
oBrowse:gotopblock := {||dbgotop()}
oBrowse:skipblock := {|n|dskip(n)}
oBrowse:headsep := "ฤ"
oBrowse:colsep := "ณ"
//oBrowse:freeze := nFreeze
return oBrowse
