      SUBROUTINE SetUAQA( lunUAQ )

      INCLUDE '../AERMET/MAIN1.INC'
      INCLUDE '../AERMET/MAIN2.INC'
      INCLUDE '../AERMET/UA1.INC'
      INCLUDE '../AERMET/UA2.INC'
      INCLUDE '../AERMET/SF1.INC'
      INCLUDE '../AERMET/SF2.INC'
      INCLUDE '../AERMET/OS1.INC'
      INCLUDE '../AERMET/OS2.INC'
      INCLUDE '../AERMET/MP1.INC'
      INCLUDE '../AERMET/MP2.INC'

      INTEGER lunUAQ
      INTEGER ios
      LOGICAL lOpen

      lunUAQ = DEV13
      UASTAT = 3

      INQUIRE(UNIT=DEV70,OPENED=lOpen)
      IF( .NOT.lOpen )THEN
        OPEN(UNIT=DEV70,STATUS='SCRATCH',ACTION='READWRITE',IOSTAT=ios)
      END IF

      RETURN
      END
