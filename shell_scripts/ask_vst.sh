#!/bin/bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### USER CHOICES #####################

# VST yes / no

if [ -z "${COQ_PLATFORM_VST:+x}" ]
then
  if  [[ "${COQ_PLATFORM_COMPCERT}"  =~ ^[fFoO] ]]
  then
cat <<EOH
======================= VERIFIED SOFTWARE TOOLCHAIN VST =======================
The Coq platform installs the Verified Software Toolchain VST.

Unfortunately VST takes a while to compile - on a fast machine with 32GB RAM it
may be just 20 minutes, but on a slow machine with 4GB RAM it is more likely
2 hours.

In case you do not plan to formally verify C code with VST, you might want
to select no (n) below. You can install VST at any time later with:

  opam install coq-vst
======================= VERIFIED SOFTWARE TOOLCHAIN VST =======================
EOH
    ask_user_opt2_cancel "Install VST (y) or do not install VST (n)?" yY "install VST" nN "do not install VST"
    COQ_PLATFORM_VST=$ANSWER
  else
    COQ_PLATFORM_VST=n
  fi
fi
