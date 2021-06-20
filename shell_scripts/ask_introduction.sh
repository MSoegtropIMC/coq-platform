#!/bin/bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### USER CHOICES #####################

# introduction / extent

if [ -z "${COQ_PLATFORM_EXTENT:+x}" ]
then
cat <<EOH
====================== JUST COQ OR COMPLETE PLATFORM ? =======================
This script installs the Coq Platform version $COQ_PLATFORM_VERSION, that is:

- the Coq compiler and Coq's standard library
- CoqIDE, a GTK3 based graphical user interface
- various widely used libraries and plugins

The script uses opam, the OCaml package manager, to do all the work.
In case opam is not yet installed, it will install opam.
A new opam switch will be created unless a Coq Platform switch already exists.

This script is tested on Windows 10, macOS Catalina and many Linux variants.

The script compiles everything from sources, which might takes less than one
hour on a fast machine with lot's of RAM, or up to 6 hours with little RAM.

Instead of installing the full Coq platform now, you can just install Coq or
Coq + CoqIDE and install additional packages via opam later as needed.
You should install CoqIDE unless you know what VSCoq or Proof General is.
====================== JUST COQ OR COMPLETE PLATFORM ? =======================
EOH
  ask_user_opt3_cancel "Install full platform (f), Coq base (b) or Coq+CoqIDE (i)?" fF "full platform" bB "Coq" iI "Coq+CoqIDE"
  COQ_PLATFORM_EXTENT=$ANSWER
fi
