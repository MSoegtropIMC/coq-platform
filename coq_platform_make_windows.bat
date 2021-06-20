@ECHO OFF

REM ========== COPYRIGHT/COPYLEFT ==========

REM (C) 2020 Michael Soegtrop

REM Released to the public under the
REM Creative Commons CC0 1.0 Universal License
REM See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

REM ========== NOTES ==========

REM For Cygwin setup command line options
REM see https://cygwin.com/faq/faq.html#faq.setup.cli

REM ========== DEFAULT VALUES FOR PARAMETERS ==========

REM For a description of all parameters, see ReadMe.txt

SET BATCHFILE=%~0
SET BATCHDIR=%~dp0

REM Values are x86_64 or i686 (not 64 or 32)
SET ARCH=x86_64
SET SETUP=setup-x86_64.exe
SET BITS=64
SET OTHER_BITS=32
SET OTHER_ARCH=i686

REM HTTP/HTTPS proxy (without http://)
IF DEFINED HTTP_PROXY (
  SET PROXY=%HTTP_PROXY:http://=%
) else (
  REM One can't set a variable to empty in DOS, but you can set it to a space this way.
  REM The quotes are just there to make the space visible and to protect from "remove trailing spaces".
  SET "PROXY= "
)

REM A Cygwin mirror - see https://cygwin.com/mirrors.html for choices
REM THIS MUST NOT INCLUDE THE TRAILING /
SET CYGWIN_REPOSITORY=https://mirrors.kernel.org/sourceware/cygwin

REM A local folder (in Windows path syntax) where cygwin packages are cached
IF EXIST %TEMP%\NUL (
  SET CYGWIN_LOCAL_CACHE_WFMT=%TEMP%\coq_platform_cygwin_cache
) ELSE IF EXIST %TMP%\NUL (
  SET CYGWIN_LOCAL_CACHE_WFMT=%TMP%\coq_platform_cygwin_cache
) ELSE (
  SET CYGWIN_LOCAL_CACHE_WFMT=%BATCHDIR%cygwin_cache
)

REM If y, install Cygwin as found in the cache - do not try to update from teh repo server
SET CYGWIN_FROM_CACHE=n

REM If y, do an unattended installation of Cygwin
SET CYGWIN_QUIET=y

REM If y, force run the cygwin setup - even if it appears to be installed already
SET CYGWIN_FORCE=n

REM If y, automatically run the coq-platform setup after cygwin setup
SET BUILD_COQ_PLATFORM=y

REM ========== PARSE COMMAND LINE PARAMETERS ==========

SHIFT

:Parse

IF "%~0" == "-help" (
  CALL :PrintUsage
  GOTO :EOF
)

IF "%~0" == "-h" (
  CALL :PrintUsage
  GOTO :EOF
)

IF "%~0" == "-arch" (
  IF "%~1" == "32" (
    SET ARCH=i686
    SET SETUP=setup-x86.exe
    SET BITS=32
    SET OTHER_BITS=64
    SET OTHER_ARCH=x86_64
  ) ELSE (
    IF "%~1" == "64" (
      SET ARCH=x86_64
      SET SETUP=setup-x86_64.exe
      SET BITS=64
      SET OTHER_BITS=32
      SET OTHER_ARCH=i686
    ) ELSE (
      ECHO "Invalid -arch, valid are 32 and 64"
      GOTO :EOF
    )
  )
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-destcyg" (
  SET DESTCYG=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-proxy" (
  SET PROXY=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-cygrepo" (
  SET CYGWIN_REPOSITORY=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-cygcache" (
  SET CYGWIN_LOCAL_CACHE_WFMT=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-cyglocal" (
  SET CYGWIN_FROM_CACHE=%~1
  CALL :CheckYN -cyglocal %~1 || GOTO ErrorExit
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-cygquiet" (
  SET CYGWIN_QUIET=%~1
  CALL :CheckYN -cygquiet %~1 || GOTO ErrorExit
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-cygforce" (
  SET CYGWIN_FORCE=%~1
  CALL :CheckYN -cygquiet %~1 || GOTO ErrorExit
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-build" (
  SET BUILD_COQ_PLATFORM=%~1
  CALL :CheckYN -build %~1 || GOTO ErrorExit
  SHIFT
  SHIFT
  GOTO Parse
)

REM The parameters passed to the final script are checked there

IF "%~0" == "-extent" (
  SET COQ_PLATFORM_EXTENT=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-packages" (
  SET COQ_PLATFORM_PACKAGELIST=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-parallel" (
  SET COQ_PLATFORM_PARALLEL=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-jobs" (
  SET COQ_PLATFORM_JOBS=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-compcert" (
  SET COQ_PLATFORM_COMPCERT=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-vst" (
  SET COQ_PLATFORM_VST=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-switch" (
  SET COQ_PLATFORM_SWITCH=%~1
  SHIFT
  SHIFT
  GOTO Parse
)

IF "%~0" == "-dumplogs" (
  SET COQ_PLATFORM_DUMP_LOGS=y
  SHIFT
  GOTO Parse
)

IF NOT "%~0" == "" (
  ECHO Install cygwin and download, compile and install OCaml and Coq for MinGW
  ECHO !!! Illegal parameter %~0
  ECHO(
  CALL :PrintUsage
  GOTO :EOF
)

REM ========== ASK FOR INSTALL LOCATION ==========

IF "%DESTCYG%" == "" (
  REM  01234567890123456789012345678901234567890123456789012345678901234567890123456789
  ECHO ======================== CYGWIN INSTALLATION LOCATION ========================
  ECHO The Coq Platform uses Cygwin, a light weight Posix emulator for Windows, as
  ECHO build environment for the Coq Platform. Please enter below the installation
  ECHO path for the Cygwin root folder.
  ECHO You can use one cygwin installation for several different variants of the Coq
  ECHO platform, so there is no need to give a version specific name. But the name
  ECHO should indicate that the cygwin is specialized for Coq platform builds.
  ECHO(
  ECHO The following recommended paths can be chosen by entering a number:
  ECHO 1  C:\cygwin%BITS%_coq.
  ECHO 2  C:\cygwin%BITS%_coq_platform.
  ECHO 3  C:\bin\cygwin%BITS%_coq_platform.
  ECHO Please enter a number 1...3 or a complete path
  ECHO ======================== CYGWIN INSTALLATION LOCATION ========================
  SET /P DESTCYG="Cygwin install folder: "
)

:REPEAT_LOCATION_ENTRY
IF "%DESTCYG%" == "" (
  ECHO Please enter a path or a number or Ctrl+C to abort
  SET /P DESTCYG="Cygwin install folder: "
)

IF "%DESTCYG%" == "" (
  GOTO REPEAT_LOCATION_ENTRY
)

IF "%DESTCYG%" == "1" (
  SET DESTCYG=C:\cygwin%BITS%_coq
) ELSE IF "%DESTCYG%" == "2" (
  SET DESTCYG=C:\cygwin%BITS%_coq_platform
) ELSE IF "%DESTCYG%" == "3" (
  SET DESTCYG=C:\bin\cygwin%BITS%_coq_platform
) ELSE (
  REM CHECK PATH
  IF EXIST %DESTCYG%\NUL (
    IF NOT EXIST %DESTCYG%\home\%USERNAME%\coq-platform\NUL (
      ECHO ERROR: The folder %DESTCYG% exists and is not a coq platform cygwin folder!
      EXIT 1
    )
  )
)

REM ========== CONFIRM PARAMETERS ==========

CALL :PrintPars
REM Note: DOS batch replaces variables on parsing, so one can't use a variable just set in an () block
IF "%COQREGTESTING%"=="y" (GOTO DontAsk)
  SET /p ANSWER="Is this correct? y/n "
  IF NOT "%ANSWER%"=="y" (GOTO :EOF)
:DontAsk

REM ========== DERIVED VARIABLES ==========

SET CYGWIN_INSTALLDIR_WFMT=%DESTCYG%
SET TARGET_ARCH=%ARCH%-w64-mingw32
SET BASH=%CYGWIN_INSTALLDIR_WFMT%\bin\bash

REM Convert paths to various formats
REM WFMT = windows format (C:\..)          Used in this batch file.
REM CFMT = cygwin format (\cygdrive\c\..)  Used for Cygwin PATH variable, which is : separated, so C: doesn't work.
REM MFMT = MinGW format (C:/...)           Used for the build, because \\ requires escaping. Mingw can handle \ and /.

SET CYGWIN_INSTALLDIR_MFMT=%CYGWIN_INSTALLDIR_WFMT:\=/%
SET CYGWIN_INSTALLDIR_CFMT=%CYGWIN_INSTALLDIR_MFMT:C:/=/cygdrive/c/%
SET CYGWIN_INSTALLDIR_CFMT=%CYGWIN_INSTALLDIR_CFMT:D:/=/cygdrive/d/%
SET CYGWIN_INSTALLDIR_CFMT=%CYGWIN_INSTALLDIR_CFMT:E:/=/cygdrive/e/%

ECHO CYGWIN INSTALL DIR (WIN)    = %CYGWIN_INSTALLDIR_WFMT%
ECHO CYGWIN INSTALL DIR (MINGW)  = %CYGWIN_INSTALLDIR_MFMT%
ECHO CYGWIN INSTALL DIR (CYGWIN) = %CYGWIN_INSTALLDIR_CFMT%

REM WARNING: Add a space after the = in case you want set this to empty, otherwise the variable will be unset
SET MAKE_OPT=-j %MAKE_THREADS%

REM ========== DERIVED CYGWIN SETUP OPTIONS ==========

REM One can't set a variable to empty in DOS, but you can set it to a space this way.
REM The quotes are just there to make the space visible and to protect from "remove trailing spaces".
SET "CYGWIN_OPT= "

IF "%CYGWIN_FROM_CACHE%" == "y" (
  SET CYGWIN_OPT= %CYGWIN_OPT% -L
)

IF "%CYGWIN_QUIET%" == "y" (
  SET CYGWIN_OPT= %CYGWIN_OPT% -q --no-admin
)

REM Cygwin setup sets proper ACLs (permissions) for folders it CREATES.
REM Otherwise chmod won't work and e.g. the ocaml build will fail.
REM Cygwin setup does not touch the ACLs of existing folders.

ECHO "========== DOWNLOAD CYGWIN SETUP =========="

mkdir %CYGWIN_LOCAL_CACHE_WFMT%

REM Delete Cygwin setup file if it is older than 1 day, so that it is downloaded again
FORFILES /P %CYGWIN_LOCAL_CACHE_WFMT% /M %SETUP% /D -1 /C "cmd /C del @file" 2> NUL

IF NOT EXIST "%CYGWIN_LOCAL_CACHE_WFMT%\%SETUP%" (
  powershell -Command "(New-Object Net.WebClient).DownloadFile('http://www.cygwin.com/%SETUP%', '%CYGWIN_LOCAL_CACHE_WFMT%/%SETUP%')"
)

ECHO "========== INSTALL CYGWIN =========="

SET RUNSETUP=y
IF EXIST "%CYGWIN_INSTALLDIR_WFMT%\etc\setup\installed.db" (
  SET RUNSETUP=n
)
IF NOT "%CYGWIN_QUIET%" == "y" (
  SET RUNSETUP=y
)

IF "%CYGWIN_FORCE%" == "y" (
  SET RUNSETUP=y
)

REM If you need to add packages, see https://cygwin.com/packages/package_list.html for package names
REM In the description of each package you also find the file list and maintainer there

IF "%RUNSETUP%"=="y" (
  "%CYGWIN_LOCAL_CACHE_WFMT%\%SETUP%" ^
    --proxy "%PROXY%" ^
    --site "%CYGWIN_REPOSITORY%" ^
    --root "%CYGWIN_INSTALLDIR_WFMT%" ^
    --local-package-dir "%CYGWIN_LOCAL_CACHE_WFMT%" ^
    --no-shortcuts ^
    %CYGWIN_OPT% ^
    -P cygwin-devel,gcc-core,gcc-g++, ^
    -P rsync,patch,diffutils,curl,make,unzip,git,m4,perl,wget ^
    -P gdb,liblzma5 ^
    -P automake,automake1.14 ^
    -P pkg-config ^
    -P mingw64-%ARCH%-binutils,mingw64-%ARCH%-gcc-core,mingw64-%ARCH%-gcc-g++,mingw64-%ARCH%-windows_default_manifest ^
    -P mingw64-%ARCH%-headers,mingw64-%ARCH%-runtime,mingw64-%ARCH%-pthreads,mingw64-%ARCH%-zlib ^
    -P mingw64-%ARCH%-gtk3,mingw64-%ARCH%-libxml2,mingw64-%ARCH%-cairo ^
    -P mingw64-%ARCH%-gmp,mingw64-%ARCH%-mpfr,mingw64-%ARCH%-boost ^
    -P libiconv-devel,libunistring-devel,libncurses-devel ^
    -P gettext-devel,libgettextpo-devel ^
    -P libglib2.0-devel,libgdk_pixbuf2.0-devel ^
    -P libtool,intltool ^
    -P gtk-update-icon-cache ^
    -P mingw64-%ARCH%-adwaita-icon-theme,mingw64-%ARCH%-adwaita-themes ^
    -P libfontconfig1 ^
    -P bison,flex ^
    -P cygwin%OTHER_BITS%-binutils,cygwin%OTHER_BITS%-gcc-core ^
    %EXTRAPACKAGES% ^
    || GOTO ErrorExit

  MKDIR "%CYGWIN_INSTALLDIR_WFMT%\build"
  MKDIR "%CYGWIN_INSTALLDIR_WFMT%\build\buildlogs"
)

IF NOT "%CYGWIN_QUIET%" == "y" (
  REM Like most setup programs, cygwin setup starts the real setup as a separate process, so wait for it.
  REM This is not required with the -cygquiet=y and the resulting --no-admin option.
  :waitsetup
  tasklist /fi "imagename eq %SETUP%" | find ":" > NUL
  IF ERRORLEVEL 1 GOTO waitsetup
)

ECHO ========== CONFIGURE CYGWIN USER ACCOUNT ==========

REM In case this batch file is called from a cygwin bash (e.g. a git repo) we need to clear
REM HOME (otherwise we get to the home directory of the other installation)
REM PROFILEREAD (this is set to true if the /etc/profile has been read, which creates user)
SET "HOME="
SET "PROFILEREAD="

copy "%BATCHDIR%\windows\configure_profile.sh" "%CYGWIN_INSTALLDIR_WFMT%\var\tmp" || GOTO ErrorExit
%BASH% --login "%CYGWIN_INSTALLDIR_CFMT%/var/tmp/configure_profile.sh" "%PROXY%" || GOTO ErrorExit

REM Get cygwin user home folder as windows path
REM Note: we don't write the full path from cygwin, because it is a bit dangerous if this fails.
REM We want to prepend USER_HOME_DIR_MFMT here to be sure we stay in this folder.
SET /p USER_HOME_DIR_CFMT=<"%CYGWIN_INSTALLDIR_WFMT%\var\tmp\main_user_folder.txt"
SET USER_HOME_DIR_MFMT=%CYGWIN_INSTALLDIR_MFMT%%USER_HOME_DIR_CFMT%
SET USER_HOME_DIR_WFMT=%USER_HOME_DIR_MFMT:/=\%

ECHO ========== BUILD COQ PLATFORM ==========

IF "%BUILD_COQ_PLATFORM%" == "y" (
  RMDIR /S /Q "%USER_HOME_DIR_MFMT%/coq-platform"
  MKDIR "%USER_HOME_DIR_MFMT%/coq-platform"
  XCOPY /S "%BATCHDIR%*.*" "%USER_HOME_DIR_WFMT%\coq-platform" || GOTO ErrorExit

  %BASH% --login "%CYGWIN_INSTALLDIR_CFMT%/%USER_HOME_DIR_CFMT%/coq-platform/coq_platform_make.sh" || GOTO ErrorExit

) ELSE (
  ECHO Note: Automatic Coq platform build has been disabled with -build=n
)

REM  01234567890123456789012345678901234567890123456789012345678901234567890123456789
ECHO(
ECHO ========== FINISHED ==========
ECHO(
ECHO You can now start your freshly created Coq platform Cygwin via:
ECHO(
ECHO   %CYGWIN_INSTALLDIR_WFMT%/cygwin.bat
ECHO(
ECHO This will start a bash with opam, coqc, coqide and other tools available.
ECHO Please note that coqc, ocamlc and many other tools are Windows executables,
ECHO not cygwin executables, so they do not understand Cygwin paths like /home.
ECHO As long as you use only relative paths - forward slashes are fine - there
ECHO is no issue with this. If you want to give an absolute path to one of the tools
ECHO you have to convert it with "$(cygpath -wa mypath)" for backward slashes or
ECHO "$(cygpath -ma mypath)" for forward slashes (easier in scripts and make files).

GOTO :EOF

ECHO ========== BATCH FUNCTIONS ==========

:PrintUsage
  REM  01234567890123456789012345678901234567890123456789012345678901234567890123456789
  ECHO Usage: coq_platform_make_windows [options]
  ECHO(
  ECHO First install a fresh Cygwin with all required prerequisites.
  ECHO Then run a script in this Cygwin which creates a new opam switch
  ECHO and makes and installs the Coq platform in this switch.
  ECHO(
  ECHO Cygwin setup parameters:
  ECHO(
  ECHO -h, -help  Print this help message and exit
  ECHO -arch      ^<32 or 64^> Set cygwin, ocaml and coq to 32 or 64 bit
  ECHO -build=y   Setup cygwin and build Coq platform
  ECHO -build=n   Just setup cygin - don't build Coq platform
  ECHO -destcyg   ^<path to cygwin destination folder^>
  ECHO -proxy     ^<internet proxy^>
  ECHO -cygrepo   ^<cygwin download repository^>
  ECHO -cygcache  ^<local cygwin repository/cache^>
  ECHO -cyglocal  ^<y or n^> install cygwin from cache
  ECHO -cygquiet  ^<y or n^> install cygwin without user interaction
  ECHO -cygforce  ^<y or n^> run cygwin setup even if destination is already installed
  ECHO(
  ECHO Coq platform setup parameters:
  ECHO(
  ECHO If an option is not given, the option is explained and asked for interactively.
  ECHO Except for expert users this is the recommended way to run this script.
  ECHO(
  ECHO -extent=f    Setup opam and build full Coq platform
  ECHO -extent=b    Just setup opam and build Coq (basic)
  ECHO -extent=i    Just setup opam and build Coq + CoqIDE
  ECHO -parallel=p  Build several opam packages in parallel
  ECHO -parallel=s  Build opam packages sequentially
  ECHO -jobs=1..16  Number of make threads per package
  ECHO -compcert=f  Build full non-free version of CompCert
  ECHO -compcert=o  Build only open source part of CompCert
  ECHO -compcert=n  Do not build CompCert and VST
  ECHO -vst=y       Build Verified Software Toolchain (takes a while)
  ECHO -vst=n       Do not build Verified Software Toolchain
  ECHO -switch=k    In case the opam switch already exists, keep it
  ECHO -switch=d    In case the opam switch already exists, delete it
  REM  01234567890123456789012345678901234567890123456789012345678901234567890123456789
  GOTO :EOF

:PrintPars
  ECHO Parameter values (default or currently set):
  ECHO (Run "coq_platform_make_windows -h" for details)
  ECHO -arch     = %ARCH%
  ECHO -build    = %BUILD_COQ_PLATFORM%
  ECHO -destcyg  = %DESTCYG%
  ECHO -proxy    = %PROXY%
  ECHO -cygrepo  = %CYGWIN_REPOSITORY%
  ECHO -cygcache = %CYGWIN_LOCAL_CACHE_WFMT%
  ECHO -cyglocal = %CYGWIN_FROM_CACHE%
  ECHO -cygquiet = %CYGWIN_QUIET%
  ECHO -cygforce = %CYGWIN_FORCE%
  ECHO -extent   = %COQ_PLATFORM_EXTENT%
  ECHO -packages = %COQ_PLATFORM_PACKAGES%
  ECHO -parallel = %COQ_PLATFORM_PARALLEL%
  ECHO -jobs     = %COQ_PLATFORM_JOBS%
  ECHO -compcert = %COQ_PLATFORM_COMPCERT%
  ECHO -vst      = %COQ_PLATFORM_VST%
  ECHO -switch   = %COQ_PLATFORM_SWITCH%
  ECHO -dumplogs = %COQ_PLATFORM_DUMP_LOGS%
  GOTO :EOF

:CheckYN
  REM Reset errorlevel to 0
  CMD /c "EXIT /b 0"
  IF "%2" == "y" (
    REM OK y
  ) ELSE IF "%2" == "n" (
    REM OK n
  ) ELSE (
    ECHO ERROR Parameter %1 must be y or n, but is %2
    GOTO ErrorExit
  )
  GOTO :EOF

:ErrorExit
  ECHO ERROR coq_platform_make_windows.bat failed
  EXIT /b 1
