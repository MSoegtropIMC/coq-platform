#!/bin/bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### CLOSING REMARKS #####################

cat <<EOH
============================== CLOSING REMARKS ===============================
The Coq Platform installation script finished successfully!

Use the following opam commands to switch to the Coq Platform opam switch:

    opam switch ${COQ_PLATFORM_SWITCH_NAME}
    eval \$(opam env)

Or to just use this opam switch in the current shell (not setting the default):

    eval \$(opam config env --switch ${COQ_PLATFORM_SWITCH_NAME})  

After switching you can list the installed packages with:

    opam list

You can install additionalpackages with:

    opam install <package>

There is a dedicated Zulip stream for the Coq Platform:

https://coq.zulipchat.com/#narrow/stream/250632-Coq-Platform.20devs.20.26.20users
============================== CLOSING REMARKS ===============================
EOH
