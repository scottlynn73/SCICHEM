!*******************************************************************************
!$RCSfile$
!$Revision$
!$Date$
!*******************************************************************************
MODULE SCIMgrparam_fd

!***********************************************************************
!               SCIPTool User Definitions
!***********************************************************************

  USE SCIPresults_fd

!==== SCIP Errors

  INTEGER, PARAMETER :: FORTRAN_IOS_ERROR = 3*(16**6)         !(Z'30000000')
  INTEGER, PARAMETER :: CALLBACK_ERROR    = 2*(16**6)+8*(16**5) !(Z'28000000')

!==== SCIP Buttons

  INTEGER, PARAMETER :: SHOWLEFTBUTTON     =  1
  INTEGER, PARAMETER :: SHOWMIDDLEBUTTON   =  2
  INTEGER, PARAMETER :: SHOWRIGHTBUTTON    =  4
  INTEGER, PARAMETER :: ENABLELEFTBUTTON   =  8
  INTEGER, PARAMETER :: ENABLEMIDDLEBUTTON = 16
  INTEGER, PARAMETER :: ENABLERIGHTBUTTON  = 32

!==== SCIP CallBack Messages

  INTEGER, PARAMETER :: HM_CHECK       = 0
  INTEGER, PARAMETER :: HM_SETWAIT     = 1
  INTEGER, PARAMETER :: HM_RELEASEWAIT = 2
  INTEGER, PARAMETER :: HM_SETCLOCK    = 3
  INTEGER, PARAMETER :: HM_STEPCLOCK   = 4
  INTEGER, PARAMETER :: HM_STOPCLOCK   = 5
  INTEGER, PARAMETER :: HM_EXIT        = 31

!     Parameter = Pointer to MessageT Structure

  INTEGER, PARAMETER :: HM_MESSAGE     = 1024
  INTEGER, PARAMETER :: HM_PROGRESSMSG = HM_MESSAGE
  INTEGER, PARAMETER :: HM_INFO        = HM_MESSAGE + 1
  INTEGER, PARAMETER :: HM_ERROR       = HM_MESSAGE + 2
  INTEGER, PARAMETER :: HM_REPLY       = HM_MESSAGE + 3
  INTEGER, PARAMETER :: HM_STOP        = HM_MESSAGE + 4
  INTEGER, PARAMETER :: HM_BUTTONTAG   = HM_MESSAGE + 5
  INTEGER, PARAMETER :: HM_CAUTION     = HM_MESSAGE + 6

!     Parameter = Integer value

  INTEGER, PARAMETER :: HM_INTEGER     = 512
  INTEGER, PARAMETER :: HM_START       = HM_INTEGER + 1
  INTEGER, PARAMETER :: HM_PROGRESSBAR = HM_INTEGER + 3
  INTEGER, PARAMETER :: HM_BUTTONSTATE = HM_INTEGER + 5
  INTEGER, PARAMETER :: HM_HASOUTPUT   = HM_INTEGER + 7

!     Parameter = Pointer to Structure

  INTEGER, PARAMETER :: HM_STRUCTURE  = 256
  INTEGER, PARAMETER :: HM_PRJAUDIT   = HM_STRUCTURE + 3

!     Parameter = Pointer to ReleaseT Structure

  INTEGER, PARAMETER :: HM_RELEASE    = HM_STRUCTURE + 1

!     Parameter = Pointer to UpdateRelT Structure

  INTEGER, PARAMETER :: HM_UPDATEREL  = HM_STRUCTURE + 2

!     Parameter = Pointer to UpdateRelMCT Structure

  INTEGER, PARAMETER :: HM_UPDATERELMC  = HM_STRUCTURE + 4

!     Parameter = Pointer to an array

  INTEGER, PARAMETER :: HM_ARRAY   = 128

!     Parameter = Pointer to Real Array

  INTEGER, PARAMETER :: HM_SYNC    = HM_ARRAY + 1     !t,t+delt

!==== SCIP Initialization return values
!     Bits

  INTEGER, PARAMETER :: HIB_UTM    = 0

!     Values

  INTEGER, PARAMETER :: HI_UTM    = 2**HIB_UTM


!==== SCIP Control Identifiers

  INTEGER, PARAMETER :: HC_LEFTBUTTON   = 201
  INTEGER, PARAMETER :: HC_MIDDLEBUTTON = 202
  INTEGER, PARAMETER :: HC_RIGHTBUTTON  = 203

!==== SCIP input types

  INTEGER, PARAMETER :: SCIPB_STATUS   = 10
  INTEGER, PARAMETER :: SCIPB_WEATHER  = 8
  INTEGER, PARAMETER :: SCIPB_RELEASE  = 7
  INTEGER, PARAMETER :: SCIPB_MATERIAL = 6
  INTEGER, PARAMETER :: SCIPB_OPTIONS  = 5
  INTEGER, PARAMETER :: SCIPB_DOMAIN   = 4
  INTEGER, PARAMETER :: SCIPB_FLAGS    = 3
  INTEGER, PARAMETER :: SCIPB_END      = 2
  INTEGER, PARAMETER :: SCIPB_START    = 1
  INTEGER, PARAMETER :: SCIPB_CTRL     = 0
  INTEGER, PARAMETER :: SCIP_STATUS   = 2**SCIPB_STATUS
  INTEGER, PARAMETER :: SCIP_WEATHER  = 2**SCIPB_WEATHER
  INTEGER, PARAMETER :: SCIP_RELEASE  = 2**SCIPB_RELEASE
  INTEGER, PARAMETER :: SCIP_MATERIAL = 2**SCIPB_MATERIAL
  INTEGER, PARAMETER :: SCIP_OPTIONS  = 2**SCIPB_OPTIONS
  INTEGER, PARAMETER :: SCIP_DOMAIN   = 2**SCIPB_DOMAIN
  INTEGER, PARAMETER :: SCIP_FLAGS    = 2**SCIPB_FLAGS
  INTEGER, PARAMETER :: SCIP_END      = 2**SCIPB_END
  INTEGER, PARAMETER :: SCIP_START    = 2**SCIPB_START
  INTEGER, PARAMETER :: SCIP_CTRL     = 2**SCIPB_CTRL
  INTEGER, PARAMETER :: SCIP_TIME     = SCIP_START + SCIP_END
  INTEGER, PARAMETER :: SCIP_RUN      = SCIP_CTRL + SCIP_END
  INTEGER, PARAMETER :: SCIP_INPUT    = SCIP_CTRL + SCIP_TIME + SCIP_FLAGS + &
                                        SCIP_DOMAIN + SCIP_OPTIONS + SCIP_MATERIAL
  INTEGER, PARAMETER :: SCIP_RESTART  = SCIP_CTRL + SCIP_END + SCIP_FLAGS + &
                                        SCIP_DOMAIN + SCIP_OPTIONS
  INTEGER, PARAMETER :: SCIP_COMPLETE = SCIP_INPUT + SCIP_RELEASE + SCIP_WEATHER

!==== SCIP Input control modes

  INTEGER, PARAMETER :: HCB_FILE    = 0
  INTEGER, PARAMETER :: HCB_SEARCH  = 1
  INTEGER, PARAMETER :: HCB_APPEND  = 2
  INTEGER, PARAMETER :: HCB_REPLACE = 3
  INTEGER, PARAMETER :: HC_FILE     = 2**HCB_FILE
  INTEGER, PARAMETER :: HC_SEARCH   = 2**HCB_SEARCH
  INTEGER, PARAMETER :: HC_APPEND   = 2**HCB_APPEND
  INTEGER, PARAMETER :: HC_REPLACE  = 2**HCB_REPLACE

!==== SCIP conversion modes

  INTEGER, PARAMETER :: HCB_UTM   = 0
  INTEGER, PARAMETER :: HCB_LLA   = 1
  INTEGER, PARAMETER :: HC_UTM    = 2**HCB_UTM
  INTEGER, PARAMETER :: HC_LLA    = 2**HCB_LLA

!==== SCIP update modes

  INTEGER, PARAMETER :: HUB_TIME        = 10
  INTEGER, PARAMETER :: HUB_SPACE       = 11
  INTEGER, PARAMETER :: HUB_INCIDENT    = 12
  INTEGER, PARAMETER :: HUB_LASTCHANCE  = 20
  INTEGER, PARAMETER :: HUB_ENVIRONMENT = 21
  INTEGER, PARAMETER :: HUB_MATERIAL    = 22
  INTEGER, PARAMETER :: HU_TIME         = 2**HUB_TIME
  INTEGER, PARAMETER :: HU_SPACE        = 2**HUB_SPACE
  INTEGER, PARAMETER :: HU_INCIDENT     = 2**HUB_INCIDENT + HU_SPACE + HU_TIME
  INTEGER, PARAMETER :: HU_LASTCHANCE   = 2**HUB_LASTCHANCE
  INTEGER, PARAMETER :: HU_ENVIRONMENT  = 2**HUB_ENVIRONMENT
  INTEGER, PARAMETER :: HU_MATERIAL     = 2**HUB_MATERIAL

!==== SCIP Release status modes

  INTEGER, PARAMETER :: HS_INVALID    = 0
  INTEGER, PARAMETER :: HS_VALID      = 1

!==== SCIP Project status modes

  INTEGER, PARAMETER :: HSB_HASTERRAIN = 1
  INTEGER, PARAMETER :: HSB_HASDOS     = 2
  INTEGER, PARAMETER :: HSB_HASDEP     = 3
  INTEGER, PARAMETER :: HSB_HASPUFFS   = 10
  INTEGER, PARAMETER :: HS_HASTERRAIN  = 2**HSB_HASTERRAIN
  INTEGER, PARAMETER :: HS_HASDOS      = 2**HSB_HASDOS
  INTEGER, PARAMETER :: HS_HASDEP      = 2**HSB_HASDEP
  INTEGER, PARAMETER :: HS_HASPUFFS    = 2**HSB_HASPUFFS

!==== SCIP Project file codes

  INTEGER, PARAMETER :: HDB_METFILE  =  0
  INTEGER, PARAMETER :: HDB_TERFILE  =  1
  INTEGER, PARAMETER :: HDB_RELFILE  =  2
  INTEGER, PARAMETER :: HDB_SAMFILE  =  3
  INTEGER, PARAMETER :: HDB_INPFILE  =  4
  INTEGER, PARAMETER :: HDB_MSCFILE  =  5
  INTEGER, PARAMETER :: HDB_SCNFILE  =  6
  INTEGER, PARAMETER :: HDB_RADFILE  =  7
  INTEGER, PARAMETER :: HDB_PRJFILE  =  8
  INTEGER, PARAMETER :: HDB_PUFFILE  =  9
  INTEGER, PARAMETER :: HDB_DOSFILE  = 10
  INTEGER, PARAMETER :: HDB_DEPFILE  = 11
  INTEGER, PARAMETER :: HDB_LOGFILE  = 12
  INTEGER, PARAMETER :: HDB_MCWFILE  = 14
  INTEGER, PARAMETER :: HDB_SMPFILE  = 16
  INTEGER, PARAMETER :: HDB_ICDFILE  = 17
  INTEGER, PARAMETER :: HDB_CAUTION  = 18

  INTEGER, PARAMETER :: HDB_SPSFILE  = HDB_CAUTION + 1
  INTEGER, PARAMETER :: HDB_OFFSETA  = 1
  INTEGER, PARAMETER :: HDB_DGNFILE  = HDB_CAUTION + HDB_OFFSETA + 1
  INTEGER, PARAMETER :: HDB_AMRFILE  = HDB_CAUTION + HDB_OFFSETA + 2
  INTEGER, PARAMETER :: HDB_OFFSETB  = 4
  INTEGER, PARAMETER :: HD_MAXBITS   = HDB_CAUTION + HDB_OFFSETA + HDB_OFFSETB
  INTEGER, PARAMETER :: HD_METFILE   = 2**HDB_METFILE
  INTEGER, PARAMETER :: HD_TERFILE   = 2**HDB_TERFILE
  INTEGER, PARAMETER :: HD_RELFILE   = 2**HDB_RELFILE
  INTEGER, PARAMETER :: HD_SAMFILE   = 2**HDB_SAMFILE
  INTEGER, PARAMETER :: HD_INPFILE   = 2**HDB_INPFILE
  INTEGER, PARAMETER :: HD_MSCFILE   = 2**HDB_MSCFILE
  INTEGER, PARAMETER :: HD_SCNFILE   = 2**HDB_SCNFILE
  INTEGER, PARAMETER :: HD_RADFILE   = 2**HDB_RADFILE
  INTEGER, PARAMETER :: HD_PRJFILE   = 2**HDB_PRJFILE
  INTEGER, PARAMETER :: HD_PUFFILE   = 2**HDB_PUFFILE
  INTEGER, PARAMETER :: HD_DOSFILE   = 2**HDB_DOSFILE
  INTEGER, PARAMETER :: HD_DEPFILE   = 2**HDB_DEPFILE
  INTEGER, PARAMETER :: HD_LOGFILE   = 2**HDB_LOGFILE
  INTEGER, PARAMETER :: HD_MCWFILE   = 2**HDB_MCWFILE
  INTEGER, PARAMETER :: HD_SMPFILE   = 2**HDB_SMPFILE
  INTEGER, PARAMETER :: HD_ICDFILE   = 2**HDB_ICDFILE
  INTEGER, PARAMETER :: HD_SPSFILE   = 2**HDB_SPSFILE
  INTEGER, PARAMETER :: HD_CAUTION   = 2**HDB_CAUTION
  INTEGER, PARAMETER :: HD_DGNFILE   = 2**HDB_DGNFILE
  INTEGER, PARAMETER :: HD_AMRFILE   = 2**HDB_AMRFILE
  INTEGER, PARAMETER :: HD_INPUT     = HD_INPFILE + HD_MSCFILE + HD_SCNFILE
  INTEGER, PARAMETER :: HD_OUTPUT    = HD_PRJFILE + HD_PUFFILE + HD_DOSFILE + &
                                       HD_DEPFILE + HD_LOGFILE + HD_SMPFILE + &
                                       HD_CAUTION + HD_DGNFILE + HD_AMRFILE

END MODULE SCIMgrparam_fd
