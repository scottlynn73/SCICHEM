!*******************************************************************************
!$RCSfile$
!$Revision$
!$Date$
!*******************************************************************************
MODULE  prog_inc
  USE release_fd
  USE prjstruct_fd
  LOGICAL :: lProg = .FALSE.
  INTEGER :: nProg = 0
  TYPE( projectIDT ) callbackProject
END MODULE prog_inc

!==============================================================================

PROGRAM runSCI

USE basic_fd
USE tooluser_fd
USE default_fd
USE param_fd
USE SCIPtool
USE prog_inc
USE myWinAPI
USE mpi_fi, ONLY: UseMPI, isSerial, numprocs, myid, ierr
USE localmpi
USE SCIPUFFdriver_fi
USE LoadSen_fi
USE UpdateRelList_fi

!     This program creates a new SCIP project from an existing project
!     through calls to the SCIPtool.

IMPLICIT NONE

!==== Parameters

!==== Local storeage

TYPE ( messageT  ) error
TYPE ( pinputT   ) input
TYPE ( preleaseT ) scenario
TYPE ( pweatherT ) weather
TYPE( matGasT   )                            :: mtlData
TYPE ( fileNameT ) ini_str

INTEGER                  :: irv
INTEGER                  :: request
INTEGER(LEN_ADDRESS)     :: ToolCallBackAddress
INTEGER                  :: ToolUserID
INTEGER                  :: maxGrd
INTEGER                  :: nhit_target

CHARACTER(PATH_MAXLENGTH) :: ini_file,OldPrjName,script_file
CHARACTER(PATH_MAXLENGTH) :: file_sci

CHARACTER(1)             :: ans
CHARACTER(256)           :: senfile
CHARACTER(128)           :: runMPI
TYPE ( char128T )        :: projectName
REAL(8)                  :: start_time, end_time
CHARACTER(128)           :: string1,string2,string3,string4

INTEGER                  :: i,j,nMtl,nRel,idefault
INTEGER                  :: ios, lun_in
LOGICAL                  :: Init,lexist,restart, create
LOGICAL                  :: lsensor
LOGICAL                  :: lAermod
CHARACTER(PATH_MAXLENGTH), EXTERNAL :: AddExtension
CHARACTER(PATH_MAXLENGTH), EXTERNAL :: StripNull, AddNull

INTEGER,        EXTERNAL :: sysGetProfileString
INTEGER,        EXTERNAL :: sysGetProfileInt
INTEGER,        EXTERNAL :: runSCIRdCmdLine
CHARACTER(32)            :: mode

INTEGER, EXTERNAL              :: LoadSen
INTEGER, EXTERNAL              :: TimeToString
INTEGER, EXTERNAL              :: ToolCallBack

!==== CallBack address

ToolCallBackAddress = ADDRESSOF(ToolCallBack)
ToolUserID          = 4321
limit%met1D         = HUGE(1)
limit%puffs         = 20000
limit%surfaceGrid   = 25000
Init                = .FALSE.
useMPI              = .FALSE.

CALL InitMPI( myid,numprocs,useMPI )
start_time = MPI_Wtime()

!==== Initialization request

request = HI_UTM

!--- Start up : Read Command line input

CAll SCIPInitError()
irv = SCIPGetLastError( error )
IF( irv == SCIPfailure )THEN
  error%iParm   = 999
  error%routine = 'runSCI'
  error%aString = 'Failed to initialize error structure'
  error%bString = 'Unknown error - SCIPGetLastError failure'
  error%cString = 'ignoring error'
END IF

IF( myid == 0 )THEN

!--- Start up : Read Command line input

ini_file    = ''
script_file = ''
OldPrjName  = ''
lun_in      = 5
irv = runSCIRdCmdLine( script_file,ini_file,OldPrjName,maxGrd )
IF( irv /= 0 )THEN
  IF( irv == -999 )GO TO 9998
  WRITE(6,*)'runSCI RdCmdLine error',irv
  GO TO 9999
END IF

IF( LEN_TRIM(script_file) > 0 )THEN
  lun_in = 105
  OPEN(lun_in,FILE=TRIM(script_file),IOSTAT=ios)
END IF

!==== INI file

IF( LEN_TRIM(ini_file) <= 0 )THEN
  WRITE(6,*)
  WRITE(6,'(''INI file (press Enter for default):'',$)')
  READ(5,'(A)')ini_file
  ini_file = ADJUSTL(ini_file)
  INQUIRE(file=ini_file,EXIST=lexist)
  IF( .NOT.lexist )THEN
    irv = GetModuleFileName( 0,string1,LEN(string1) )
    CALL SplitName( string1(1:irv),string2,string3 )
    ini_file = 'scipuff.ini'
    CALL AddPath( ini_file,TRIM(string3) )
  END IF
  INQUIRE(file=ini_file,EXIST=lexist)
  IF( .NOT.lexist )ini_file = 'DEFAULT'
ELSE
  ini_file = ADJUSTL(ini_file)
ENDIF
IF( TRIM(ini_file) == 'DEFAULT' )THEN
  ini_file = 'scipuff.ini'
  WRITE(6,*)'Using default '//TRIM(ini_file)
  irv = GetWindowsDirectory( string2,LEN(string2) )
  string1 = TRIM(StripNull(string2))//'\'
  CALL AddPath( ini_file,TRIM(string1) )
ENDIF

INQUIRE(file=ini_file,EXIST=lexist)
IF( .NOT.lexist )THEN
  error%iParm   = 999
  error%routine = 'runSCI'
  error%aString = 'Failed to initialize SCIPtool'
  error%bString = 'Unable to find ini file'
  error%cString = 'INI file='//TRIM(ini_file)
  GOTO 9999
END IF
string4 = AddNull( TRIM(ini_file) )
string1 = AddNull( 'SCIPMode' )
string2 = AddNull( 'GUIMode' )
string3 = 'Standard'
irv = sysGetProfileString( string1,string2,string3,mode,string4 )

CALL cupper( mode )

SELECT CASE( TRIM(mode) )
  CASE( 'STANDARD' )
    limit%met1D       = HUGE(1)
    limit%puffs       = 20000
    limit%surfaceGrid = 25000

  CASE( 'OPERATIONAL' )
    limit%met1D       = HUGE(1)
    limit%puffs       = 20000
    limit%surfaceGrid = 25000

  CASE( 'EXTENDED' )
    limit%met1D       = HUGE(1)
    limit%puffs       = 40000
    limit%surfaceGrid = 85000

  CASE( 'ULTIMATE' )
    limit%met1D       = HUGE(1)
    limit%puffs       = 60000
    limit%surfaceGrid = 100000

  CASE DEFAULT
    limit%met1D       = HUGE(1)
    limit%puffs       = 60000
    limit%surfaceGrid = 100000

    string2 = AddNull( 'MaxMet1D' )
    idefault = limit%met1D
    irv = sysGetProfileInt( string1,string2,idefault,limit%met1D,string4 )
    string2 = AddNull( 'MaxPuff' )
    idefault = limit%puffs
    irv = sysGetProfileInt( string1,string2,idefault,limit%puffs,string4 )
    string2 = AddNull( 'MaxGrid' )
    idefault = limit%surfaceGrid
    irv = sysGetProfileInt( string1,string2,idefault,limit%surfaceGrid,string4 )

END SELECT

isSerial = .TRUE.
string1 = AddNull( 'Parallel' )  ! section
string2 = AddNull( 'isSerial' )  ! key
WRITE(string3,'(A)') 'ON'        ! cdefault
irv = sysGetProfileString( string1,string2,string3,runMPI,string4 )
IF( irv == SCIPfailure )THEN
  error%iParm   = 999
  error%routine = 'runSCI'
  error%aString = 'Failure reading runMPI from INI file'
  error%bString = 'INI file='//TRIM(ini_file)
  error%cString = TRIM(OldPrjName)
  GOTO 9999
END IF
READ(runMPI,'(A)') string3
CALL cupper( string3 )
IF( TRIM(string3) == 'OFF' )isSerial = .FALSE.

useMPI = .FALSE.
IF( numprocs > 1 .AND. .NOT.isSerial )THEN
  string1 = AddNull( 'Parallel' )  ! section
  string2 = AddNull( 'MPI'      )  ! key
  WRITE(string3,'(A)') 'OFF'       ! cdefault
  irv = sysGetProfileString( string1,string2,string3,runMPI,string4 )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'runSCI'
    error%aString = 'Failure reading runMPI from INI file'
    error%bString = 'INI file='//TRIM(ini_file)
    error%cString = TRIM(OldPrjName)
    GOTO 9999
  END IF
  READ(runMPI,'(A)') string3
  CALL cupper( string3 )
  IF( TRIM(string3) == 'ON' )useMPI = .TRUE.
END IF
IF( useMPI )THEN
  CALL SetUpPrjMPI( error )
  IF( error%iParm /= 0 )GOTO 9999
END IF
!==== Initialize SCIPtool

WRITE(6,*)
WRITE(6,*)'Initializing SCIPtool from '//TRIM(ini_file)
WRITE(6,*)
WRITE(6,'("Running SCIP in ",A," mode")')TRIM(mode)
WRITE(6,'("MaxPuff = ",I15)')limit%puffs
IF ( maxGrd > 0 )THEN
  limit%surfaceGrid = maxGrd
  WRITE(6,*)'Setting MaxGrid from command line '
END IF
WRITE(6,'("MaxGrid = ",I15)')limit%surfaceGrid

ini_str%string = ini_file
irv = SCIPInitTool( ToolUserID,ToolCallBackAddress,request,limit,ini_str )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPInitTool'
    error%aString = 'Failed to initialize SCIPtool library'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = 'Unable to continue'
  END IF
  GOTO 9999
END IF

Init = .TRUE.

!==== Get old project name

IF( LEN_TRIM(OldPrjName) <= 0 )THEN
  WRITE(6,100)
  100   FORMAT(/,' Old Project name(Use RST:prj or CRT:prj for restart or create only ): ',$)
  READ(lun_in,*)string1
  string1 = ADJUSTL(string1)
ELSE
  string1 = ADJUSTL(OldPrjName)
ENDIF

restart = .FALSE.
create  = .FALSE.
IF( string1(1:4) == 'RST:' )THEN
  restart = .TRUE.
ELSE IF( string1(1:4) == 'CRT:' )THEN
  create = .TRUE.
END IF

IF( restart .OR. create )THEN
  string1 = string1(5:LEN_TRIM(string1))
END IF

OldPrjName = string1
CALL SplitName( string1,string2,string3 )

file_sci = TRIM(string2)//'.sci'
CALL AddPath(file_sci,string3)

INQUIRE(file=file_sci,EXIST=lAerMod)
IF( lAerMod )THEN
  fname   = file_sci
  prjname = TRIM(string2)
  OPEN(FILE=TRIM(fname),UNIT=lun,STATUS='OLD',ACTION='READ',IOSTAT=ios)
  IF( ios /= 0 )THEN
    WRITE(*,'(A)') 'Error opening input file name'
    WRITE(*,'(A)') 'File name = '//TRIM(fname)
    GOTO 9999
  END IF
  CALL RunAERMODInp( ToolUserID,restart,error )
  IF( error%iParm /= 0 )GOTO 9999
ELSE

!==== Load project data

WRITE(6,*)
WRITE(6,*)'Loading input from '//TRIM(OldPrjName)

input%project%name = TRIM(string2)
input%project%path = TRIM(string3)

irv = SCIPSizeProjectMC( ToolUserID,input%project,nMtl,nRel,nMCrel )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPSizeProject'
    error%aString = 'Failed to get Project size'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = TRIM(OldPrjName)
  END IF
  GOTO 9999
END IF

ALLOCATE( mtlList(nMtl),STAT=ios )
IF( ios /= 0 )THEN
  error%iParm   = 999
  error%routine = 'runSCI'
  error%aString = 'Failed to allocate mtlList'
  GOTO 9999
END IF
DO i = 1,nMtl
  mtlList(i)%type          = NOT_SET_I
  mtlList(i)%puffIndex     = NOT_SET_I
  mtlList(i)%iNotUsed(1)   = NOT_SET_I
  mtlList(i)%iNotUsed(2)   = NOT_SET_I
  DO j = 1,HS_PADMTLGEN
    mtlList(i)%matData%padding(j) = NOT_SET_I
  END DO
  mtlList(i)%name          = ' '
  mtlList(i)%units         = ' '
  mtlList(i)%file          = ' '
  mtlList(i)%path          = ' '
END DO

input%input%mtlHead%max    = nMtl
input%input%mtlHead%number = 0
irv = SCIPDefaultInpF( ToolUserID,input,mtlList )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPDefaultInput'
    error%aString = 'Failed to load default Project input'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = TRIM(OldPrjName)
  END IF
  GOTO 9999
END IF

input%input%time%end%time%hour = NOT_SET_R
irv = SCIPLoadInpF( ToolUserID,input,mtlList )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPLoadInpF'
    error%aString = 'Failed to load Project input'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = TRIM(OldPrjName)
  END IF
  GOTO 9999
END IF

IF( BTEST(input%input%flags%mode,HFB_REVERSE) )THEN
  senfile = TRIM(string3)//TRIM(string2)//'.sen'
  INQUIRE(FILE = TRIM(senfile),EXIST = lsensor)
  IF( lsensor )THEN
    nRel = nMtl
    irv = LoadSen( nRel,nMtl,senfile,input%input%time )
    IF( irv == SCIPfailure )THEN
      error%iParm   = 999
      error%routine = 'LoadSen'
      error%aString = 'Failed to load sensor file'
      error%bString = 'Unknown error - SCIPGetLastError failure'
      error%cString = TRIM(OldPrjName)
      GOTO 9999
    END IF
    IF( ALLOCATED(mtlList) )DEALLOCATE( mtlList,STAT=ios )
    IF( ALLOCATED(relList) )DEALLOCATE( relList,STAT=ios )
    ALLOCATE( mtlList(nMtl),STAT=ios )
    IF( ios /= 0 )THEN
      error%iParm   = 999
      error%routine = 'runSCI'
      error%aString = 'Failed to allocate mtlList'
      GOTO 9999
    END IF
    ALLOCATE( relList(nRel),STAT=ios )
    IF( ios /= 0 )THEN
      error%iParm   = 999
      error%routine = 'runSCI'
      error%aString = 'Failed to allocate relList'
      GOTO 9999
    END IF
    DO i = 1,nMtl
      mtlList(i) = matList(i)
    END DO
    DO i = 1,nRel
      relList(i) = rlsList(i)
    END DO
    input%input%mtlHead%max    = nMtl
    input%input%mtlHead%number = nMtl
    DEALLOCATE( matList,STAT=ios )
    DEALLOCATE( rlsList,STAT=ios )
  END IF
  ! Get estimation type
  WRITE(6,'(/,"Continuous Source Estimation (Y/N)? ")',ADVANCE='NO')
  READ(lun_in,'(A)',IOSTAT=ios)string1
  IF( LEN_TRIM(string1) > 0 )THEN
    string1 = ADJUSTL(string1)
    CALL CUPPER(string1)
    Ans = string1(1:1)
  END IF
  IF( Ans == 'Y' )THEN
    DO i = 1,nMtl
      mtlData            = TRANSFER(mtlList(i)%matData,mtlData)
      mtlData%save       = IBSET(mtlData%save,HSB_GROUPDOS)
      mtlData%save       = IBSET(mtlData%save,HSB_TOTALDOS)
      mtlList(i)%matData = TRANSFER(mtlData,mtlList(i)%matData)
    END DO
  ELSE
    DO i = 1,nMtl
      mtlData            = TRANSFER(mtlList(i)%matData,mtlData)
      mtlData%save       = IBCLR(mtlData%save,HSB_GROUPDOS)
      mtlData%save       = IBCLR(mtlData%save,HSB_TOTALDOS)
      mtlList(i)%matData = TRANSFER(mtlData,mtlList(i)%matData)
    END DO
  END IF
  WRITE(6,'(" Continuous Source Estimation set to ",A,/)')Ans

  ! Approximate max number of hits for Adjoint Filter
  WRITE(6,'(/,"Total number of hits are ",I4," from a total of ",I4)')nRel - nNull, nRel
  !WRITE(6,'("Approximate maximum number of hits after filtering( will override value from inifile)? ")',ADVANCE='NO')
  !READ(lun_in,'(I4)',IOSTAT=ios)nhit_target

ELSE
  lsensor = .FALSE.
END IF

WRITE(6,*)
WRITE(6,*)'Loading weather   from '//TRIM(OldPrjName)

weather%project%name = TRIM(string2)
weather%project%path = TRIM(string3)

irv = SCIPDefaultWeatherF( ToolUserID,weather )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPDefaultWeatherF'
    error%aString = 'Failed to load default Project weather'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = TRIM(OldPrjName)
  END IF
  GOTO 9999
END IF

irv = SCIPLoadWeatherF( ToolUserID,weather )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPLoadWeatherF'
    error%aString = 'Failed to load Project weather'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = TRIM(OldPrjName)
  END IF
  GOTO 9999
END IF

scenario%project%name          = TRIM(string2)
scenario%project%path          = TRIM(string3)
scenario%scnHead%max           = nRel
scenario%scnHead%number        = 0
scenario%control%mode          = HC_APPEND
scenario%control%searchID      = ' '
scenario%control%fileExtension = ' '

IF( lsensor )THEN

  WRITE(6,*)
  WRITE(6,*)'Loading releases  from '//TRIM(senfile)
  scenario%scnHead%number = nRel

ELSE

WRITE(6,*)
WRITE(6,*)'Loading releases  from '//TRIM(OldPrjName)

ALLOCATE( relList(nRel),STAT=ios )
IF( ios == 0 )ALLOCATE( relMCList(nMCrel),STAT=ios )
IF( ios /= 0 )THEN
  error%iParm   = 999
  error%routine = 'runSCI'
  error%aString = 'Failed to allocate relList'
  GOTO 9999
END IF

DO i = 1,nRel
    relList(i)%padding   = NOT_SET_I
    relList(i)%type      = NOT_SET_I
    relList(i)%status    = HS_VALID
    relList(i)%tRel      = NOT_SET_R
    relList(i)%xRel      = NOT_SET_R
    relList(i)%yRel      = NOT_SET_R
    relList(i)%zRel      = NOT_SET_R
    relList(i)%notUsedA  = NOT_SET_R
    relList(i)%notUsedB  = NOT_SET_R
    relList(i)%notUsed   = NOT_SET_R
    DO j = 1,HS_PADRELGEN
      relList(i)%relData%padding(j) = NOT_SET_I
    END DO
    relList(i)%material   = ' '
    relList(i)%relName    = ' '
    relList(i)%relDisplay = ' '
END DO

DO i = 1,nMCrel
    relMCList(i)%relID   = NOT_SET_I
    relMCList(i)%MCname  = NOT_SET_C
    relMCList(i)%MCmass  = NOT_SET_R
END DO
irv = SCIPLoadReleaseMCF( ToolUserID,scenario,relList,relMCList )
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPLoadReleaseF'
    error%aString = 'Failed to load Project Release'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = TRIM(OldPrjName)
  END IF
  GOTO 9999
END IF

DO i = 1,nRel
      relList(i)%notUsedA  = NOT_SET_R
      relList(i)%notUsedB  = NOT_SET_R
      relList(i)%notUsed   = NOT_SET_R
  CONTINUE
END DO

ENDIF

!FirstUpdateRel%id   = NOT_SET_C
!FirstUpdateRel%rate = NOT_SET_R
!FirstUpdateRel%wmom = NOT_SET_R
!FirstUpdateRel%buoy = NOT_SET_R
!FirstUpdateRel%name = NOT_SET_C
NULLIFY(FirstUpdateRel%Rel)

CALL SplitName( OldPrjName,string2,string3 )

new%project%ID      = 0
new%project%version = 0
new%project%name    = TRIM(string2)
new%project%path    = TRIM(string3)
new%input%time      = input%input%time
new%input%flags     = input%input%flags
new%input%domain    = input%input%domain
new%input%option    = input%input%option
new%input%mtlHead   = input%input%mtlHead

new%weather = weather%weather
new%scnHead = scenario%scnHead

callbackProject = new%project

!**************************************************************
new%input%flags%mode = IBSET(new%input%flags%mode,HFB_DINCRMNT)
!**************************************************************

projectName%string = new%project%name
CALL InitToolMPI( useMPI,myid,numprocs,projectName,error )
IF( error%iParm /= 0 )GOTO 9999

IF ( .NOT.restart )THEN

!==== Prepare to Create new project

  WRITE(6,*)
  WRITE(6,*)'Creating '//TRIM(OldPrjName)

  irv = SCIPNewProjectMC( ToolUserID,new,mtlList,relList,nMCrel,relMCList )
  IF( irv == SCIPfailure )THEN
    irv = SCIPGetLastError( error )
    IF( irv == SCIPfailure )THEN
      error%iParm   = 999
      error%routine = 'SCIPNewProject'
      error%aString = 'Failed to create Project'
      error%bString = 'Unknown error - SCIPGetLastError failure'
      error%cString = TRIM(OldPrjName)
    END IF
   GOTO 9999
  END IF
  WRITE(6,*)'Done Creating '//TRIM(OldPrjName)

END IF

IF ( .NOT.create )THEN

!==== Run project

  run%project = new%project
  run%end     = new%input%time%end

  WRITE(6,*)
  WRITE(6,*)'Running  '//TRIM(OldPrjName)

  irv = SCIPRunProject( ToolUserID,run )
  IF( irv == SCIPfailure )THEN
    irv = SCIPGetLastError( error )
    IF( irv == SCIPfailure )THEN
      error%iParm   = 999
      error%routine = 'SCIPRunProject'
      error%aString = 'Failed to run Project'
      error%bString = 'Unknown error - SCIPGetLastError failure'
      error%cString = ' '
    END IF
    GOTO 9999
  END IF

END IF
END IF ! lAermod

ELSE ! myid /= 0

  CALL SetUpPrjMPI( error )
  IF( error%iParm /= 0 )GOTO 9999

  IF( useMPI )THEN

    ProjectName%string = NOT_SET_C

    CALL InitToolMPI( useMPI,myid,numprocs,ProjectName,error )
    IF( error%iParm /= 0 )GOTO 9999

    WRITE(6,'("Running Project",A," with MPI for myid = ",I4)')ProjectName%string,myid

    !WRITE(*,*)'Call RunChemSubMPI from myid',myid
    CALL RunChemSubMPI( projectName,error )
    IF( error%iParm /= 0 )GOTO 9999

  END IF

END IF

9997  CONTINUE
IF( myid == 0 )THEN

WRITE(6,*)
WRITE(6,*)'Exiting Scipuff'

!==== Exit SCIPtool

irv = SCIPExitTool()
IF( irv == SCIPfailure )THEN
  irv = SCIPGetLastError( error )
  IF( irv == SCIPfailure )THEN
    error%iParm   = 999
    error%routine = 'SCIPExitTool'
    error%aString = 'Failed to properly exit SCIPtool dll'
    error%bString = 'Unknown error - SCIPGetLastError failure'
    error%cString = 'Unable to continue'
  END IF
  GOTO 9999
END IF

end_time = MPI_Wtime()

!Write total runtime
WRITE(6,*)'Total runtime = ',end_time - start_time,' secs'

END IF ! myid == 0

9998 CONTINUE
IF( ALLOCATED(relList)   )DEALLOCATE( relList,  STAT=ios )
IF( ALLOCATED(relMCList) )DEALLOCATE( relMCList,STAT=ios )
IF( ALLOCATED(mtlList)   )DEALLOCATE( mtlList,  STAT=ios )
IF( myid == 0 )THEN
IF( lun_in /= 5 )CLOSE(UNIT=lun_in )
END IF
IF( useMPI )THEN
  CALL DeAllocMPI( irv )
  IF( error%iParm /= 0 )THEN
    WRITE(6,*)'Aborting all MPI processes'
    CALL MPI_ABORT( MPI_COMM_WORLD, irv, ierr )
  END IF
END IF
CALL MPI_FINALIZE( ierr )

STOP

9999  CONTINUE
IF( lProg )THEN
  WRITE(6,'(A)')REPEAT(' ',nProg)
  lProg = .FALSE.
ELSE
  WRITE(6,*)
END IF
IF( useMPI )THEN
  WRITE(6,*)'Error message from process id = ',myId
END IF
WRITE(6,*)'******* ERROR *******'
WRITE(6,*)'Routine  = '//TRIM(error%routine)
WRITE(6,*)'Error No.= ',error%iParm
WRITE(6,*)'Message  = '//TRIM(error%aString)
IF(LEN_TRIM(error%bString) > 0 .and. error%bString(1:1) /= CHAR(0)) &
  WRITE(6,*)'           '//TRIM(ERROR%BSTRING)
IF(LEN_TRIM(error%cString) > 0 .and. error%cString(1:1) /= CHAR(0)) &
  WRITE(6,*)'           '//TRIM(ERROR%CSTRING)
WRITE(6,*)'************************'

IF(Init)THEN
  Init = .false.
  GOTO 9997
ELSE
  GOTO 9998
END IF

END

!===============================================================================
!     SCIPtool CallBack Message Handler
!===============================================================================
RECURSIVE INTEGER FUNCTION ToolCallBack( arg1,arg2,iParm )
!DEC$ ATTRIBUTES REFERENCE :: arg1, arg2

USE tooluser_fd
USE prog_inc
USE basic_fd
USE SCIPtool
USE SCIPUFFdriver_fi, ONLY: SUCCESS, nMC, prjname

IMPLICIT NONE

INTEGER(LEN_ADDRESS) :: arg1,arg2
INTEGER,DIMENSION(*) :: iParm

INTEGER, PARAMETER :: NCH = 3
INTEGER, PARAMETER :: OVER_WRITE = 1

INTEGER iMessage
INTEGER(LEN_ADDRESS) jParm
INTEGER iCaller
INTEGER i
INTEGER irv
TYPE ( messageT ) message
TYPE( updateRelT ) update
INTEGER :: nMCup
TYPE( releaseMCT ), DIMENSION(:), ALLOCATABLE, TARGET :: upMCList
TYPE( updateRelMCT ) updateMC
TYPE( preleaseT ) prel
TYPE( releaseT  ), DIMENSION(1) :: upList
TYPE( releaseMCT ), DIMENSION(:), POINTER :: ptr_upMCList
CHARACTER(PATH_MAXLENGTH), EXTERNAL :: AddExtension

LOGICAL default
CHARACTER(128) string(3),StripNull,Routine

INTEGER(LEN_ADDRESS), EXTERNAL ::  ADDRESSOF
INTEGER, EXTERNAL :: UpdateContRel
INTERFACE
  INTEGER FUNCTION UpdateStackEmission( relMC,update,updateMC,nMCup )
    USE SCIPUFFdriver_fi
    USE update_fd
    TYPE( releaseMCT ),   DIMENSION(:),               POINTER         :: relMC
    TYPE( updateRelT ),   OPTIONAL,                   INTENT( INOUT ) :: update
    TYPE( updateRelMCT ), OPTIONAL,                   INTENT( INOUT ) :: updateMC
    INTEGER,              OPTIONAL,                   INTENT( IN    ) :: nMCup
  END FUNCTION UpdateStackEmission
END INTERFACE

CALL VALUE_REFERENCE( arg1, iCaller )
CALL VALUE_REFERENCE( arg2, iMessage )

Routine = 'ToolCallBack'

ToolCallBack = SCIPsuccess

SELECT CASE( iMessage )
  CASE( HM_MESSAGE,HM_INFO,HM_ERROR,HM_REPLY,HM_CAUTION  )
    jParm = ADDRESSOF( iParm )
    CALL ADDRESS_MESSAGE( jParm,message )
    string(1) = StripNull( message%aString )
    string(2) = StripNull( message%bString )
    string(3) = StripNull( message%cString )
  CASE( HM_CHECK ) !So we can abort
  CASE( HM_UPDATEREL )
    jParm = ADDRESSOF( iParm )
    CALL ADDRESS_UPDATE( jParm,update )

      NULLIFY(ptr_upMCList)
      irv = UpdateStackEmission( ptr_upMCList,update=update )
    IF( irv /= SUCCESS )THEN
      ToolCallBack = SCIPfailure
      GOTO 9999
    END IF

    update%release%status = HS_VALID
    CALL UPDATE_ADDRESS( update,jParm )

  CASE( HM_UPDATERELMC )
    jParm = ADDRESSOF( iParm )
    CALL ADDRESS_UPDATEMC( jParm,updateMC )

    IF( nMC > 0 )THEN
      nMCup = nMC
      ALLOCATE( upMCList(nMCup),STAT=irv )
      IF( irv /= 0 )THEN
        ToolCallBack = SCIPfailure
        GOTO 9999
      END IF
      ptr_upMCList => upMCList
      irv = UpdateStackEmission( ptr_upMCList,updateMC=updateMC,nMCup=nMCup )
      IF( irv /= SUCCESS )THEN
        ToolCallBack = SCIPfailure
        GOTO 9999
      END IF
    END IF
    updateMC%release%status = HS_VALID
    !Write updated release and MClist to a file
    prel%project = callbackProject
    prel%project%name = TRIM(prjname)//'_updateMC'
    prel%scnHead%max = 1
    prel%scnHead%number = 1
    prel%control%mode = HC_FILE
    prel%control%searchID = ' '
    prel%control%fileextension = 'scn'
    upList(1) = updateMC%release
    irv = SCIPWriteReleaseMCF( iCaller*10,prel,upList,nMCup,upMCList )
    IF( irv /= SCIPSuccess )THEN
      ToolCallBack = SCIPfailure
      GOTO 9999
    END IF

    !Update the update structure
    updateMC%updateSCN = TRIM(prel%project%name)
    updateMC%updateSCN = AddExtension(updateMC%updateSCN,TRIM(prel%control%fileextension))
    CALL AddPath(updateMC%updateSCN,TRIM(prel%project%path))
    CALL UPDATEMC_ADDRESS( updateMC,jParm )
  CASE( HM_STOP )
    CALL ClearRelList()

  CASE DEFAULT
    GOTO 9999
END SELECT
IF( iMessage > HM_MESSAGE )default = message%jParm /= FALSE

ToolCallBack = SCIPsuccess
SELECT CASE( iMessage )
CASE( HM_CHECK )
    i = SCIPCheckButtons( 99990 )
    IF( i /= SCIPsuccess )THEN
      WRITE(6,*) 'SCIPCheckButtons error',i
      GOTO 9999
    END IF
  CASE( HM_SETCLOCK )
  CASE( HM_STEPCLOCK )
  CASE( HM_STOPCLOCK )
  CASE( HM_SETWAIT )
  CASE( HM_RELEASEWAIT )
  CASE( HM_INFO )
    IF( lProg )THEN
      WRITE(6,200)REPEAT(' ',nProg)
      lProg = .FALSE.
    ELSE
      WRITE(6,*)
    END IF
    WRITE(6,*)'******* Message  *******'
    WRITE(6,*)'Routine  = '//TRIM(Routine)
    WRITE(6,*)'Message  = '//TRIM(string(1))
    IF(LEN_TRIM(string(2)) > 0 .and. string(2)(1:1) /= CHAR(0)) &
      WRITE(6,*)'           '//TRIM(string(2))
    IF(LEN_TRIM(string(3)) > 0 .and. string(3)(1:1) /= CHAR(0)) &
      WRITE(6,*)'           '//TRIM(string(3))
    WRITE(6,*)'************************'
  CASE( HM_ERROR )
    IF( lProg )THEN
      WRITE(6,200)REPEAT(' ',nProg)
      lProg = .FALSE.
    ELSE
      WRITE(6,*)
    END IF
    WRITE(6,*)'*******  Error   *******'
    WRITE(6,*)'Routine  = '//TRIM(Routine)
    WRITE(6,*)'Error    = '//TRIM(string(1))
    IF(LEN_TRIM(string(2)) > 0 .and. string(2)(1:1) /= CHAR(0)) &
      WRITE(6,*)'           '//TRIM(string(2))
    IF(LEN_TRIM(string(3)) > 0 .and. string(3)(1:1) /= CHAR(0)) &
       WRITE(6,*)'           '//TRIM(string(3))
    WRITE(6,*)'************************'
  CASE( HM_REPLY )
    IF( lProg )THEN
      WRITE(6,200)REPEAT(' ',nProg)
      lProg = .false.
    ELSE
      WRITE(6,*)
    END IF
    WRITE(6,*)'******* Question *******'
    WRITE(6,*)'Routine  = '//TRIM(Routine)
    WRITE(6,*)'Question = '//TRIM(string(1))
    IF(LEN_TRIM(string(2)) > 0 .and. string(2)(1:1) /= CHAR(0)) &
      WRITE(6,*)'           '//TRIM(string(2))
    IF(LEN_TRIM(string(3)) > 0 .and. string(3)(1:1) /= CHAR(0))THEN
      WRITE(6,*)'           '//TRIM(string(3))
    ELSE
      WRITE(6,*)'           Do you want to CONTINUE?'
    END IF
    WRITE(6,100)
100 FORMAT(' Reply (Y/N) : ',$)
!    read(5,*)string(1)
    string(1) = 'Y'
    CALL cupper( string(1) )
    IF( LEN_TRIM(string(1)) > 0 )default = string(1)(1:1) == 'Y'
    IF( default )THEN
      ToolCallBack = SCIPaffirmative
    ELSE
      ToolCallBack = SCIPnegative
    END IF
    WRITE(6,*)'************************'
  CASE( HM_CAUTION )
    IF( lProg )THEN
      WRITE(6,200)REPEAT(' ',nProg)
      lProg = .FALSE.
    ELSE
      WRITE(6,*)
    END IF
    WRITE(6,*)'******* Caution  *******'
    WRITE(6,*)'Routine  = '//TRIM(Routine)
    WRITE(6,*)'Message  = '//TRIM(string(1))
    IF(LEN_TRIM(string(2)) > 0 .and. string(2)(1:1) /= CHAR(0)) &
      WRITE(6,*)'           '//TRIM(string(2))
    IF(LEN_TRIM(string(3)) > 0 .and. string(3)(1:1) /= CHAR(0)) &
      WRITE(6,*)'           '//TRIM(string(3))
    WRITE(6,*)'************************'
  CASE( HM_PROGRESSMSG )
    IF( OVER_WRITE == 0 )THEN
      lProg = .TRUE.
      IF( LEN_TRIM(string(1)) > 0 .AND. string(1)(1:1) /= CHAR(0) )THEN
        nProg = MAX(nProg,LEN_TRIM(string(1))+NCH)
        WRITE(6,200)REPEAT(' ',NCH)//string(1)(1:nProg)//CHAR(13)
        nProg = LEN_TRIM(string(1))+NCH
      END IF
      IF( LEN_TRIM(string(2)) > 0 .AND. string(2)(1:1) /= CHAR(0) )THEN
        nProg = MAX(nProg,LEN_TRIM(string(2))+NCH)
        WRITE(6,200)REPEAT(' ',NCH)//string(2)(1:nProg)//CHAR(13)
        nProg = LEN_TRIM(string(2))+NCH
      END IF
      IF( LEN_TRIM(string(3)) > 0 .AND. string(3)(1:1) /= CHAR(0) )THEN
        nProg = MAX(nProg,LEN_TRIM(string(3)))+NCH
        WRITE(6,200)REPEAT(' ',NCH)//string(3)(1:nProg)//CHAR(13)
        nProg = LEN_TRIM(string(3))+NCH
      END IF
200   FORMAT(A,$)
    ELSE
      IF( LEN_TRIM(string(1)) > 0 .AND. string(1)(1:1) /= CHAR(0) )THEN
        WRITE(6,'(A)')REPEAT(' ',NCH)//TRIM(string(1))
      END IF
      IF( LEN_TRIM(string(2)) > 0 .AND. string(2)(1:1) /= CHAR(0) )THEN
        WRITE(6,'(A)')REPEAT(' ',NCH)//TRIM(string(2))
      END IF
      IF (LEN_TRIM(string(3)) > 0 .AND. string(3)(1:1) /= CHAR(0) )THEN
        WRITE(6,'(A)')REPEAT(' ',NCH)//TRIM(string(3))
      END IF
    END IF

  CASE( HM_PROGRESSBAR )
  CASE( HM_BUTTONTAG )
  CASE( HM_BUTTONSTATE )
  CASE( HM_START )
  CASE( HM_STOP )
    IF( OVER_WRITE == 0 )THEN
      WRITE(6,200)REPEAT(' ',nProg)
      lProg = .FALSE.
    END IF
    nProg = 0
  CASE DEFAULT
END SELECT

9999 CONTINUE

RETURN
END

!=======================================================================
! runSCIRdCmdLine
!=======================================================================

INTEGER FUNCTION runSCIRdCmdLine(script_file, ini_file, prjname, maxGrd)

USE tooluser_fd
USE SCIPversion_fd, ONLY: SCIPUFF_TAG

IMPLICIT NONE

CHARACTER(128)          :: script_file, prjname
INTEGER                 :: maxGrd

INTEGER                 :: numCommand, ios
INTEGER(2)              :: ios2
CHARACTER(256)          :: Command
CHARACTER(256)          :: Value
CHARACTER( 2)           :: Switch
CHARACTER(128)          :: ini_file

INTEGER                 :: i, irv, iArg
INTEGER                 :: nch

INTEGER, EXTERNAL       :: SYSCheckFile
INTEGER, EXTERNAL       :: sysNumArgs
INTEGER, EXTERNAL       :: sysGetArg

LOGICAL                 :: lExist

runSCIRdCmdLine = 0
maxGrd          = -1
numCommand      = sysNumArgs()

DO iArg = 1,numCommand

  ios2 = sysGetArg(iArg,Command)

  IF( ios2 > 0 )THEN

!------ Check for valid Command format

    IF( Command(1:1) /= '/' .AND. Command(1:1) /= '-' )THEN
      WRITE(6,*)'Invalid command line parameter'
      WRITE(6,*)'Parameter='//TRIM(Command)
      WRITE(6,'(" Valid parameter format is /SWITCH:Value or -SWITCH:Value ")')
      runSCIRdCmdLine = -2
      GO TO 9999
    END IF

!------ Get Command value

    nch = LEN_TRIM(Command)
    i   = INDEX(Command,':')
    IF( i <= 0 )THEN
      Value = ' '
    ELSE IF( i >= nch )THEN
      Value = ' '
    ELSE IF( i < 3 )THEN
      WRITE(6,*)'Invalid command line parameter'
      WRITE(6,*)'Parameter='//TRIM(Command)
      WRITE(6,'(" Valid parameter format is /SWITCH:Value or -SWITCH:Value ")')
      runSCIRdCmdLine = -3
      GO TO 9999
    ELSE
      Value = Command(i+1:nch)
    END IF

!-----  Determine Switch

    Switch = Command(2:2)
    CALL cupper(Switch)

    SELECT CASE (Switch)
      CASE ('I')
        IF( LEN_TRIM(Value) > 0 .AND. LEN_TRIM(Value) <= 128 )THEN
          INQUIRE(FILE=Value,EXIST=lExist)
          IF( .NOT.lExist )THEN
            WRITE(6,*)'Specified INI file not found'
            WRITE(6,*)'File='//TRIM(Value)
            WRITE(6,*)'Check Path/File name'
            runSCIRdCmdLine = -4
            GO TO 9999
          END IF
          ini_file = TRIM(Value)
        ELSE
          IF( LEN_TRIM(Value) > 128 )THEN
            WRITE(6,*)'INI filename exceeds 128 characters'
            WRITE(6,*)'File='//TRIM(Value)
            WRITE(6,*)'Using default inifile'
          END IF
          ini_file = "DEFAULT"
        END IF
      CASE ('P')
        IF( Value /= ' ' )THEN
          prjname = TRIM(Value)
        ELSE
          WRITE(6,*)'Project name not specified'
          WRITE(6,*)'Please specify the name of the project'
          GOTO 9999
        END IF
      CASE ('M')
        IF( Value /= ' ' )THEN
          READ(Value,*,IOSTAT=ios)i
          IF( ios /= 0 .OR. i <= 0 )THEN
            i = maxGrd
          END IF
          maxGrd = i
        END IF
      CASE( 'B' )
        IF( Value /= ' ' )THEN
          irv = sysCheckFile(Value)
          IF( irv /= SCIPsuccess )THEN
            WRITE(6,*)'Script file not found'
            WRITE(6,*)'File='//TRIM(Value)
            WRITE(6,*)'Check Path/File name'
            GOTO 9999
          END IF
          script_file = TRIM(Value)
        ELSE
          WRITE(6,*)'Script file not specified'
          WRITE(6,*)'Please specify the name of the desired script file'
          GOTO 9999
        END IF
      CASE( 'V','v')
        WRITE(6,'(A)')TRIM(SCIPUFF_TAG)
        runSCIRdCmdLine = -999
        GO TO 9999
      CASE DEFAULT
        WRITE(6,*)'Invalid command line switch : '//TRIM(Switch)
        WRITE(6,'(" Valid switches for ini file, project name, max grid ")',ADVANCE='NO')
        WRITE(6,'("and script file are I,P,M and B respt. ")')
        WRITE(6,'()')
        runSCIRdCmdLine = -5
        GO TO 9999
    END SELECT

  ELSE
    WRITE(6,*)'Error reading command line'
    WRITE(6,*)'Processing command number ',iArg
    runSCIRdCmdLine = -1
    GO TO 9999
  END IF

END DO

9999 CONTINUE

RETURN
END
!*******************************************************************************
CHARACTER(*) FUNCTION CopyCstring(string)

IMPLICIT NONE

CHARACTER(*) string

INTEGER nch

nch = INDEX(string,CHAR(0))
IF( nch <= 0 )THEN
  nch = LEN( TRIM(string) )
END IF

nch = MIN(nch,LEN(string),LEN(CopyCstring))

CopyCstring = ' '
IF( nch > 0 )THEN
  CopyCstring = string(1:nch)
END IF

RETURN
END
