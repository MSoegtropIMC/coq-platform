#!/usr/bin/env bash

###################### COPYRIGHT/COPYLEFT ######################

# (C) 2020 Michael Soegtrop

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### SCRIPT INITIALIZATION #####################

cd "$(dirname "$0")"
source shell_scripts/init_safety_debug.sh
source shell_scripts/init_paths.sh
source shell_scripts/init_utilities.sh
source shell_scripts/init_machine_type.sh
source shell_scripts/init_cygwin_fixes.sh

###################### SETTINGS #####################

export OPAMYES=yes
export OPAMCOLOR=never

###################### PARAMETERS #####################

source shell_scripts/parse_cmdline_arguments.sh

###################### SYSTEM SANITY CHECKS #####################

source shell_scripts/check_system.sh
source shell_scripts/check_compiler.sh
source shell_scripts/sanitize_environment.sh

###################### USER CHOICES #####################

# NOTE: These choices can be skipped by setting the environment variables
#       tested in the scripts.

# NOTE: If you comment some questions for a custom setup, please assign
#       the variable set in the script a default value.

source versions/coq_platform_version.sh
source shell_scripts/ask_introduction.sh
source shell_scripts/ask_packagelist.sh
source shell_scripts/ask_parallel_build.sh
source shell_scripts/ask_compcert_open_source.sh
source shell_scripts/ask_vst.sh

###################### PACKAGE SELECTION #####################

source ${COQ_PLATFORM_PACKAGELIST}
source versions/coq_platform_switch_name.sh

###################### INSTALL/INIT OPAM #####################

source shell_scripts/ask_delete_opam_switch.sh
source shell_scripts/install_opam.sh
source shell_scripts/check_opam_sandbox.sh
source shell_scripts/install_opam_depext.sh

###################### INSTALL PREREQUISITES #####################

echo "===== INSTALL PREREQUISITES ====="

source shell_scripts/install_pkg-config.sh
source shell_scripts/install_prerequisites_coqide.sh
source shell_scripts/install_prerequisites_gappa.sh

###################### BUILD ALL PACKAGES #####################

source shell_scripts/build.sh

###################### CLOSING #####################

source shell_scripts/closing_remarks.sh
