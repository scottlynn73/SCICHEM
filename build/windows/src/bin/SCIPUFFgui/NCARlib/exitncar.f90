SUBROUTINE ExitNCARGraphics()

USE ncarlib_fi
USE myWinAPI

IMPLICIT NONE

INTEGER irv

irv = DeleteObject( ihpnc )
irv = DeleteObject( ihbnc )
irv = DeleteObject( ihpalnc )
irv = DeleteObject( ihbitnc )

RETURN
END
