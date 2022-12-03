*--------------------------------------------------------------
* This module draws the standard screen displays.
*--------------------------------------------------------------

PROCEDURE MAINSCR
PARAMETERS heading, date_str, ver

CLS()
SETCOLOR(sls_normcol())
dispbox(0,0,24,79,'같같같같�')
SETCOLOR(sls_normmenu())
MAKEBOX( 0, 1, 3, 78, sls_normmenu(),sls_shadpos())
MAKEBOX( 22, 1,24,78, sls_normmenu(),sls_shadpos())
@ 1, 2 SAY PADC(heading,75)
@ 1,77-LEN(date_str) SAY date_str
@ 2,77-LEN(date_str) SAY ver
@ 23,2 SAY PADC("<F1> will display help wherever available",75)
SETCOLOR(sls_normcol())

RETURN