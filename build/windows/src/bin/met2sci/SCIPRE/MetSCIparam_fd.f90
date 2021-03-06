MODULE MetSCIparam_fd

  SAVE
  
  INTEGER, PARAMETER :: SUCCESS =  1
  INTEGER, PARAMETER :: NULL    =  0
  INTEGER, PARAMETER :: FAILURE = -1

  INTEGER, PARAMETER :: NOPATHWAY = 0
  INTEGER, PARAMETER :: JOB       = 1
  INTEGER, PARAMETER :: UPPERAIR  = 2
  INTEGER, PARAMETER :: SURFACE   = 3
  INTEGER, PARAMETER :: ONSITE    = 4

  CHARACTER(5), PARAMETER :: MISSING_C = '-9999'
  INTEGER,      PARAMETER :: MISSING_I = -9999
  REAL,         PARAMETER :: MISSING_R = -9999.
  REAL,         PARAMETER :: NOT_SET_R = -1.E+36

  INTEGER, PARAMETER :: OSHGT  = 1
  INTEGER, PARAMETER :: OSTEMP = 2
  INTEGER, PARAMETER :: OSWDIR = 3
  INTEGER, PARAMETER :: OSWSPD = 4
  INTEGER, PARAMETER :: OSRH   = 5
  INTEGER, PARAMETER :: OSHFLX = 6
  INTEGER, PARAMETER :: OSUSTR = 7
  INTEGER, PARAMETER :: OSMHGT = 8
  INTEGER, PARAMETER :: OSZ0HT = 9
  INTEGER, PARAMETER :: OSPRES = 10
  INTEGER, PARAMETER :: OSSKY  = 11

END MODULE MetSCIparam_fd