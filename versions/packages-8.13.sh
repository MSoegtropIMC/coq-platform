#!/bin/bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### CONTROL VARIABLES #####################

# The two lines below are used by the package selection script
# DESCRIPTION Coq 8.13.2 04/2021 with package pick 02/2021
# SORTORDER 1

# The package list name is the final part of the opam switch name.
# It is usually either empty ot starts with ~.
# It might also be used for installer package names, but with ~ replaced by _
# It is also used for version specific file selections in the smoke test kit.
COQ_PLATFORM_PACKAGELIST_NAME=''

# This controls if opam repositories for development packages are selected
COQ_PLATFORM_USE_DEV_REPOSITORY='N'

###################### PACKAGE SELECTION #####################

# - Comment out packages you do not want.
# - Packages with system dependencies should be given first.
#   This avoids multiple sudo password requests
# - Packages which take a long time to build should be given last.
#   There is some evidence that they are built early then.

PACKAGES="coq.8.13.2"

# GTK based IDE for Coq - alternatives are VSCoq and Proofgeneral for Emacs
if  [[ "${COQ_PLATFORM_EXTENT}"  =~ ^[iIfF] ]]
then
PACKAGES="${PACKAGES} coqide.8.13.2 lablgtk3.3.1.1"
fi

if  [[ "${COQ_PLATFORM_EXTENT}"  =~ ^[fF] ]]
then

# Some generally useful packages
PACKAGES="${PACKAGES} coq-unicoq.1.5+8.13"
PACKAGES="${PACKAGES} coq-ext-lib.0.11.3"
PACKAGES="${PACKAGES} coq-equations.1.2.3+8.13"
PACKAGES="${PACKAGES} coq-bignums.8.13.0"
PACKAGES="${PACKAGES} coq-aac-tactics.8.13.0"
PACKAGES="${PACKAGES} coq-mtac2.1.4+8.13"
PACKAGES="${PACKAGES} coq-simple-io.1.5.0"
PACKAGES="${PACKAGES} coq-quickchick.1.5.0"

# Analysis and numerics
PACKAGES="${PACKAGES} coq-flocq.3.3.1"
PACKAGES="${PACKAGES} coq-coquelicot.3.1.0"
PACKAGES="${PACKAGES} coq-gappa.1.4.6 gappa.1.3.5"
PACKAGES="${PACKAGES} coq-interval.4.1.1"

# Elpi, Coq-elpi and hierarchy builder
PACKAGES="${PACKAGES} coq-elpi.1.8.1 elpi.1.12.0"
PACKAGES="${PACKAGES} coq-hierarchy-builder.1.0.0"

# The standard set of mathcomp modules
PACKAGES="${PACKAGES} coq-mathcomp-ssreflect.1.12.0"
PACKAGES="${PACKAGES} coq-mathcomp-fingroup.1.12.0"
PACKAGES="${PACKAGES} coq-mathcomp-algebra.1.12.0"
PACKAGES="${PACKAGES} coq-mathcomp-solvable.1.12.0"
PACKAGES="${PACKAGES} coq-mathcomp-field.1.12.0"
PACKAGES="${PACKAGES} coq-mathcomp-character.1.12.0"
# Plus a few extra mathcomp modules
PACKAGES="${PACKAGES} coq-mathcomp-bigenough.1.0.0"
PACKAGES="${PACKAGES} coq-mathcomp-finmap.1.5.1"
PACKAGES="${PACKAGES} coq-mathcomp-real-closed.1.1.2"

# Homotopy Type Theory (HoTT)
PACKAGES="${PACKAGES} coq-hott.8.13"

# Menhir, CompCert and Princeton VST - these take longer to compile !
PACKAGES="${PACKAGES} coq-menhirlib.20200624 menhir.20200624"
# Todo: there is no mutex between coq platform and coq platform open source
case "$COQ_PLATFORM_COMPCERT" in
  [fF]) PACKAGES="${PACKAGES} coq-compcert.3.8" ;;
  [oO]) echo "The open source variant of CompCert is not supported in 2021.02.1"; exit 1 ;;
  [nN]) true ;;
  *) echo "Illegal value for COQ_PLATFORM_COMPCERT - aborting"; false ;;
esac

case "$COQ_PLATFORM_VST" in
  [yY]) PACKAGES="${PACKAGES} coq-vst.2.7.1" ;;
  [nN]) true ;;
  *) echo "Illegal value for COQ_PLATFORM_VST - aborting"; false ;;
esac

fi
