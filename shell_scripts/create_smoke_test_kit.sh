#!/usr/bin/env bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### CREATE SMOKE TEST KIT ######################

# This script extracts from each installed coq opam package one or more test
# files and creates a shell and DOS script to coqc all these files.

###################### Script safety and debugging settings ######################

case $BASH_VERSION in
  1*|2*|3*)
    echo "Bash version 4 or greater required"
    exit 1
  ;;
esac

set -o nounset
set -o errexit

###### Clear and create smoke test folder #####

rm -rf smoke-test-kit
mkdir smoke-test-kit

###### Get package list name #####

source "$(dirname "$0")/get_names_from_switch.sh"

###### Get filtered list of explicitly installed packages #####

echo "Create package list"

packages="$(opam list --installed-roots --short --columns=name | grep '^coq-' | cat)"

##### Associate package name with test/example file(s) #####

declare -A TEST_FILES
declare -A COQ_OPTION

TEST_FILES[coq-aac-tactics]='theories/Tutorial.v'
TEST_FILES[coq-bignums]='tests/success/bigQ.v tests/success/NumberScopes.v'
TEST_FILES[coq-compcert]='lib/Coqlib.v'
TEST_FILES[coq-compcert-32]='lib/Coqlib.v'
COQ_OPTION[coq-compcert-32]='-Q $COQLIB/../coq-variant/compcert32/compcert compcert'
TEST_FILES[coq-coquelicot]='examples/BacS2013.v'
TEST_FILES[coq-elpi]='examples/tutorial_coq_elpi.v examples/tutorial_elpi_lang.v'
TEST_FILES[coq-elpi~8.12]='theories/examples/example_reflexive_tactic.v'
TEST_FILES[coq-equations]='examples/Fin.v examples/STLC.v'
TEST_FILES[coq-ext-lib]='examples/MonadReasoning.v examples/Printing.v'
TEST_FILES[coq-flocq]='examples/Average.v' # In fixing: examples/Cody_Waite.v
TEST_FILES[coq-gappa]='testsuite/example-20101018.v testsuite/example-20090706.v testsuite/example-20080417.v'
TEST_FILES[coq-hierarchy-builder]='demo2/classical.v demo2/stage10.v demo2/stage11.v'
TEST_FILES[coq-hierarchy-builder~8.12]='demo2/classical.v demo2/stage10.v demo2/stage11.v'
TEST_FILES[coq-hierarchy-builder~dev]='examples/demo2/classical.v examples/demo2/stage10.v examples/demo2/stage11.v'
TEST_FILES[coq-interval]='testsuite/example-20071016.v testsuite/example-20120205.v testsuite/example-20140221.v'
TEST_FILES[coq-mathcomp-algebra]='mathcomp/algebra/finalg.v'
TEST_FILES[coq-mathcomp-bigenough]='bigenough.v'
TEST_FILES[coq-mathcomp-character]='mathcomp/character/all_character.v'
TEST_FILES[coq-mathcomp-field]='mathcomp/field/finfield.v'
TEST_FILES[coq-mathcomp-fingroup]='mathcomp/fingroup/fingroup.v'
TEST_FILES[coq-mathcomp-finmap]='finmap.v'
TEST_FILES[coq-mathcomp-real-closed]='theories/complex.v'
TEST_FILES[coq-mathcomp-solvable]='mathcomp/solvable/abelian.v'
TEST_FILES[coq-mathcomp-ssreflect]='mathcomp/ssreflect/ssrbool.v'
TEST_FILES[coq-menhirlib]='coq-menhirlib/src/Alphabet.v'
TEST_FILES[coq-mtac2]='examples/basics_tutorial.v examples/tauto.v'
TEST_FILES[coq-mtac2~8.12]='examples/tactics.v examples/tauto.v'
TEST_FILES[coq-quickchick]='examples/PluginTest.v' # Check: BSTTest.v
TEST_FILES[coq-simple-io]='test/Example.v test/TestExtraction.v'
TEST_FILES[coq-unicoq]='test-suite/microtests.v'
TEST_FILES[coq-vst]='progs64/reverse.v progs64/verif_reverse2.v'
TEST_FILES[coq-vst~8.12]='progs/reverse.v progs/verif_reverse2.v'
TEST_FILES[coq-vst-32]='progs/reverse.v progs/verif_reverse2.v'
COQ_OPTION[coq-vst-32]='-Q $COQLIB/../coq-variant/VST32/VST VST -Q $COQLIB/../coq-variant/compcert32/compcert compcert'
TEST_FILES[coq-hott]='theories/Analysis/Locator.v'
COQ_OPTION[coq-hott]='-noinit -indices-matter'

##### Hacks for files #####

function patch_file() {
  awk '
    /^Require Import Gappa_tactic.$/ {print "From Gappa "$0; next}
    /^Require Import .*Rcomplements.*.$/ {print "From Coquelicot "$0; next}
    /^From HB.demo2 / {sub("From HB.demo2 ", "", $0); print $0; next}
    {print $0}
    ' $1 > $1.tmp
  mv -f $1.tmp $1
}

##### Write header of bash runner script #####

smoke_script=smoke-test-kit/run-smoke-test.sh

cat <<-'EOH' > $smoke_script
	#/bin/bash
	# This script runs a small "smoke-test" for all Coq platform components

	# Exit on all errors
	set -o nounset
	set -o errexit

	# Check if coqc is available
	if ! command -v coqc &> /dev/null
	then
	  echo "This script expects that coqc is in the PATH"
	  exit 1
	fi

	# set COQLIB variable
	COQLIB="$(coqc -where | tr -d '\r')"

	# cd to smoke test folder
	HERE="$(pwd)"
	cd "$(dirname $0)"

	# Run one test
	# $1: relative path of file to run
	# $2: coqc options
	function run_test {
	    echo "====================== Running test file $1 ======================"
	      here="$(pwd)"
	      cd "${1%/*}"
	      echo "coqc ${2:-} ${1##*/}"
	      coqc ${2:-} "${1##*/}"
	      cd "$here"
	    echo $'\n\n'
	}

	# Run coqc for all smoke test files
	EOH

##### Write header of DOS batch runner script #####

smoke_batch=smoke-test-kit/run-smoke-test.bat

cat <<-'EOH' | sed 's/$/\r/' > $smoke_batch
	@ECHO OFF
	REM This script runs a small "smoke-test" for all Coq platform components
	
	REM Check if coqc is in the path
	WHERE coqc
	IF ERRORLEVEL 1 (
	    ECHO "This script expects that coqc is in the PATH"
	    EXIT 1
	)
	
	REM set COQLIB variable
	FOR /F "tokens=* USEBACKQ" %%F IN (`coqc -where`) DO SET COQLIB=%%F
	
	REM cd to smoke test folder
	SET HERE=%CD%
	CD "%~dp0%"
	
	GOTO :run_all_tests
	
	REM Run one test
	REM $1: relative path of file to run
	REM $2: coqc options
	
	:run_test
	  ECHO "====================== Running test file %1 ======================"
	  SET HERESUB=%CD%
	  CD "%~dp1"
	  ECHO "coqc %~2 %~nx1"
	  coqc %~2 %~nx1
	  IF ERRORLEVEL 1 (
	    CD "%HERESUB%"
	    ECHO "Compilation with coqc failed"
	    EXIT 1
	  )
	  CD "%HERESUB%"
	  ECHO(
	  ECHO(
	GOTO :EOF
	
	:run_all_tests
	
	REM Run coqc for all smoke test files
	EOH

##### Get the test/example file(s) for each package #####

for package in ${packages}
do
  # First check if a version sepcific entry exists
  if [ -n "${TEST_FILES[${package}${COQ_PLATFORM_PACKAGELIST_NAME}]+_undef_}" ]
  then
    files="${TEST_FILES[${package}${COQ_PLATFORM_PACKAGELIST_NAME}]}"
  # If not check if a generic entry exists
  elif [ -n "${TEST_FILES[${package}]+_undef_}" ]
  then
    files="${TEST_FILES[${package}]}"
  else
    echo "No file list defined for package ${package}"
    exit 1
  fi

  if [ -n "${COQ_OPTION[${package}]+_undef_}" ]
  then
    options='"'"${COQ_OPTION[${package}]}"'"'
  else
    options=""
  fi

  if [ -n "$files" ]
  then
    # get installed version of package (otherwise opam source gives the latest)
    packagefull=$(opam list --installed-roots --short --columns=name,version ${package} | sed 's/ /./')
    echo "Extracting from ${packagefull} the files $files"
    opam source --dir=smoke-test-kit/${package}-src ${packagefull}
    mkdir smoke-test-kit/${package}
    for file in $files
    do
      filename=${file##*/}
      # coqc does not accept file names with -
      filename=${filename/-/_}
      cp "smoke-test-kit/${package}-src/$file" "smoke-test-kit/${package}/${filename}"
      patch_file "smoke-test-kit/${package}/${filename}"
      echo "run_test ${package}/${filename} $options" >> $smoke_script
      echo "CALL :run_test ${package}/${filename} ${options//\$COQLIB/%COQLIB%}"$'\r' >> $smoke_batch
    done
    rm -rf smoke-test-kit/${package}-src
  else
    echo "File list for ${package} is set empty"
  fi
done

##### Write footer of bash runner script #####

echo '' >> $smoke_script
echo 'cd $HERE' >> $smoke_script
echo 'echo "====================== SMOKE TEST SUCCESS ======================"' >> $smoke_script

##### Write footer of DOS batch runner script #####

echo $'\r' >> $smoke_batch
echo 'CD %HERE%'$'\r' >> $smoke_batch
echo 'ECHO "====================== SMOKE TEST SUCCESS ======================"'$'\r' >> $smoke_batch

##### Run bash runner script #####

chmod u+x $smoke_script
echo "On unix you can now run " $smoke_script

##### Run batch runner script #####

chmod u+x $smoke_batch
echo "On windows you can now run " $smoke_batch