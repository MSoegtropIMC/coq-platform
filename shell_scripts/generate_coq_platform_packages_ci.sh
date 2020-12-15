#!/usr/bin/env bash

set -e

# This script generates opam/packages/*/*.dev/opam files using Coq's CI
# project tracking info and generates $OUTPUT mentioning
# them
OUTPUT=${OUTPUT:=coq_platform_packages_ci.sh}

TMP=`mktemp -d`
trap "rm -rf $TMP" EXIT

function log {
  echo $1
}

function git_clone {
  test -d $TMP/git/$1 || (log "DBG: Cloning $1 ..."; git clone $2 -b $3 --depth=1 $TMP/git/$1 >/dev/null 2>&1)
}

function test_package {
   printf "%-52s # %s\n" "PACKAGES=\"\${PACKAGES} $1.dev\"" "$2" >> $OUTPUT
}

function skip_package {
   printf "#%-51s # %s\n" "PACKAGES=\"\${PACKAGES} $1.dev\"" "$2" >> $OUTPUT
}

function create_opam_pinned_package {
  local cip="$1"
  local package="$2"
  local REPO_VAR="${cip}_CI_GITURL"
  local REPO=${!REPO_VAR}
  local BRANCH_VAR="${cip}_CI_REF"
  local BRANCH=${!BRANCH_VAR}
  git_clone $cip ${REPO} ${BRANCH}
  mkdir -p opam/packages/$package/$package.dev/
  if [ -e $TMP/git/$cip/$package.opam ]; then
    cp $TMP/git/$cip/$package.opam opam/packages/$package/$package.dev/opam
  elif [ -e $TMP/git/$cip/*.opam ]; then
    cp $TMP/git/$cip/*.opam opam/packages/$package/$package.dev/opam
  elif [ -e $TMP/git/$cip/opam ]; then
    cp $TMP/git/$cip/opam opam/packages/$package/$package.dev/opam
  else
   log "WARNING: No opam file for $cip $package"
   skip_package $package "since no opam package found"
   return
  fi
  local HASH=$(cd $TMP/git/$cip/ && git log --oneline | cut -f 1 -d ' ')
  printf "\nsrc { url : \"%s\" }" "git+${REPO}#${HASH}" >> opam/packages/$package/$package.dev/opam
  log "INFO: Testing $package at hash $HASH (on branch $BRANCH from $REPO)"
  test_package $package "${REPO}#${HASH} (on branch $BRANCH)"
}

# fetch ci info for Coq
git_clone coq https://github.com/coq/coq.git master
. git/coq/dev/ci/ci-basic-overlay.sh
# fake ci project for Coq itself
project coq "https://github.com/coq/coq.git" "master"
COQ_CI_PROJECTS="${projects[*]}"

# fetch package list from the current platform
COQ_PLATFORM_EXTENT=f
COQ_PLATFORM_COMPCERT=f
COQ_PLATFORM_VST=y
. coq_platform_packages.sh

# create the .dev package and their list
> $OUTPUT
for pv in $PACKAGES; do
  package=`echo $pv | sed -e 's/\..*//'`
  case $package in
    coqide)
      create_opam_pinned_package coq $package
    ;;
    coq-mathcomp-ssreflect|coq-mathcomp-fingroup|coq-mathcomp-algebra|coq-mathcomp-solvable|coq-mathcomp-field|coq-mathcomp-character)
      create_opam_pinned_package mathcomp $package
    ;;
    coq-hierarchy-builder)  # https://github.com/coq/coq/pull/13633
      create_opam_pinned_package elpi_hb $package
    ;;
    coq-gappa)  # https://github.com/coq/coq/pull/13633
      create_opam_pinned_package gappa_plugin $package
    ;;
    lablgtk3|gappa|menhir) # why are these in the platform?
      continue
    ;;
    *)
      found=f
      for cip in $COQ_CI_PROJECTS; do
          if [ "$found" = "f" -a "${cip/_/-}" = "${package#coq-}" ]; then
            found=t
            create_opam_pinned_package ${cip} $package
          fi
      done
      if [ "$found" = "f" ]; then
          log "WARNING: platform package $package has no corresponding entry in Coq's ci"
          skip_package $package "no corresponding entry in Coq's ci"
      fi
    ;;
  esac
done

echo "========================== platform version CI =================="
cat $OUTPUT
