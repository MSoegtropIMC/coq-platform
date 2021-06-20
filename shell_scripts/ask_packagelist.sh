#!/bin/bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### USER CHOICES #####################

# package list

if [ -z "${COQ_PLATFORM_PACKAGELIST:+x}" ]
then
cat <<EOH
========================= SELECT PACKAGELIST VERSION ==========================
The Coq Platform allows to install the latest release version of Coq and
packages, but also older versions or development versions of Coq. You can
install several versions of Coq in parallel, which simplifies porting of
developments. You can use "opam switch" to switch between Coq versions.

The follwoing versions / package lists are supported:
EOH

  packagefile_list="$( (for file in versions/packages-*.sh; do echo "$(grep "# SORTORDER" $file) $file"; done) | sed 's/  */ /g' | sort -n | cut -d ' ' -f 4)"

  packageindex=0
  for packagefile in ${packagefile_list}
  do
      if ! grep -q "# SORTORDER" "$packagefile"; then echo "ERROR: package file '$packagefile' does not contain 'SORTORDER' field."; fail; fi
      if ! grep -q "# DESCRIPTION" "$packagefile"; then echo "ERROR: package file '$packagefile' does not contain 'DESCRIPTION' field."; fail; fi
      packageindex=$((${packageindex} + 1))
      notes="$(grep '# DESCRIPTION'  "${packagefile}" | sed 's/  */ /g' | cut -d ' ' -f 3-)"
      echo "(${packageindex}): $notes"
  done

cat <<EOH

Pleas select a version by entering the number shown at the begin of a line.
========================= SELECT PACKAGELIST VERSION ==========================
EOH
  ask_user_mumber "Select package list" 1 "${packageindex}"
  packageindex=0
  for packagefile in ${packagefile_list}
  do
    packageindex=$((${packageindex} + 1))
    if [ "${packageindex}" -eq "${ANSWER}" ] 
    then
      COQ_PLATFORM_PACKAGELIST="${packagefile}"
    fi
  done
  if [ -z "${COQ_PLATFORM_PACKAGELIST:+x}" ]
  then
    echo "INTERNAL ERROR: not package list file selected!"
    false
  fi
fi
