#!/bin/bash

# This script creates a Linux installer based on snap
cd "$(dirname "$0")/.."
source shell_scripts/init_safety_debug.sh
source shell_scripts/init_paths.sh
source shell_scripts/init_utilities.sh
source versions/coq_platform_switch_name.sh
source shell_scripts/parse_cmdline_arguments.sh
source shell_scripts/ask_introduction.sh
source coq_platform_packages.sh

# Snap versions cannot contain . nor +
COQ_VERSION=${COQ_PLATFORM_VERSION//[.+]/-}

COQ_CORE_VERSION=$(coqc --print-version | cut -d ' ' -f 1)

# Description of the snap
COQ_DESCRIPTION=`mktemp`
cat > $COQ_DESCRIPTION <<EOT
  The Coq interactive prover provides a formal language to write
  mathematical definitions, executable algorithms, and theorems, together
  with an environment for semi-interactive development of machine-checked
  proofs.
  
  This snap contains the Coq prover version $COQ_CORE_VERSION
  along with CoqIDE and the following packages:
EOT

for p in $(echo ${PACKAGES} | sed -e 's/ /\n/g' | sort); do
  pname=`echo $p | sed 's/\..*//'`
  if [ "${pname##coq-}" == "$pname" ]; then continue; fi
  pversion="$(opam show $p -f version: | tr -d \")"
  plicense="$(opam show $p -f license: | tr -d \")"
  pdescr="$(opam show $p -f synopsis: | tr -d \")"
  printf "  * **%s**: %s (version: %s, license: %s)\n" ${pname##coq-} "$pdescr" "$pversion" "$plicense" >> $COQ_DESCRIPTION
done

mkdir -p snap/

sed \
   -e "s/@@COQ_VERSION@@/$COQ_VERSION/g" \
   -e "s/@@PLATFORM_ARGS@@/$*/g" \
   -e "/@@COQ_DESCRIPTION@@/r $COQ_DESCRIPTION" -e "/@@COQ_DESCRIPTION@@/d" \
   linux/snap/snapcraft.yaml.in > snap/snapcraft.yaml

echo "INFO: filled in snap/snapcraft.yaml"

mkdir -p snap/gui/

sed \
   -e "s/@@COQ_VERSION@@/$COQ_VERSION/g" \
   linux/snap/coq-prover.desktop.in > snap/gui/coq-prover.desktop

echo "INFO: filled in snap/gui/coqide.desktop"

echo -e "Done, now run:\n\tsnapcraft snap"

rm -f $COQ_DESCRIPTION
