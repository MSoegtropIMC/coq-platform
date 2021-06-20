#!/usr/bin/env bash

###################### COPYRIGHT/COPYLEFT ######################

# Released to the public under the
# Creative Commons CC0 1.0 Universal License
# See https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

###################### CREATE MAC DMG INSTALLER ######################

# Options:
# -quick|-q   : disable BZIP compression of DMG + disable opam link check
# -install|-i : install package to /Application after creating it
# -otooldump  : provide the output of otool -L for all executables

###################### PRELIMINARIES ######################

echo "##### Building Mac DMG installer #####"

###### Script safety ######

set -o nounset
set -o errexit

###### Parse command line ######

ZIPCOMPR='-format UDBZ' # bzip
CHECKOPAMLINKS='Y'
INSTALL='N'
OTOOLDUMP='N'

for arg in "$@"
do
  case "${arg}" in
    -quick|-q) ZIPCOMPR='-format UDRO'; CHECKOPAMLINKS='N' ;;
    -install|-i) INSTALL='Y' ;;
    -otooldump) OTOOLDUMP='Y' ;;
    *) echo "ERROR: Unknown command line argument ${arg}!"; false;;
  esac
done

###### Check if required system utilities are installed #####

command -v gfind &> /dev/null || ( echo "Please install gfind (eg. sudo port install findutils)" ; exit 1)
command -v grealpath &> /dev/null || ( echo "Please install gfind (eg. sudo port install coreutils)" ; exit 1)
command -v macpack  &> /dev/null || ( echo "Please install macpack (eg. sudo port install py38-pip; port select --set pip3 pip38; pip3 install macpack)" ; exit 1)

##### Get the version of the Coq Platform #####

source shell_scripts/get_names_from_switch.sh

echo "##### Coq platform version = ${COQ_PLATFORM_VERSION}${COQ_PLATFORM_PACKAGELIST_NAME} #####" 

###### Create working folder and cd #####

rm -rf macos_installer/
mkdir macos_installer/
cd macos_installer/
mkdir logs

###### Get the Coq sourcees from opam #####

# Get installed version of coq (otherwise opam source gives the latest)
coqpackagefull=$(opam list --installed-roots --short --columns=name,version coq | sed 's/ /./')
opam source --dir=coq/ ${coqpackagefull}

##### Get the version of Coq #####

COQ_VERSION=$(coqc --print-version | cut -d ' ' -f 1)

# The MacOS version needs to be purely numeric (no +beta) and is set separately in configure.ml
COQ_VERSION_MACOS=$(egrep -o 'coq_macos_version *= *"[0-9.]+"' coq/configure.ml | cut -d '=' -f 2 | tr -d ' "')

echo "##### Coq version = ${COQ_VERSION} (Mac app version=${COQ_VERSION_MACOS}) #####"

##### Create DMG package folder structure #####

# Folder and image names

APP_NAME="Coq_Platform_${COQ_PLATFORM_VERSION}.app"
DMG_NAME="coq-platform-${COQ_PLATFORM_VERSION}-installer-macos"
APP_ABSDIR="_dmg/${APP_NAME}"
RSRC_ABSDIR="${APP_ABSDIR}/Contents/Resources"
BIN_ABSDIR="$RSRC_ABSDIR/bin"
DYNLIB_ABSDIR="$RSRC_ABSDIR/lib/dylib"

# Sub folders

mkdir -p ${APP_ABSDIR}
mkdir ${APP_ABSDIR}/Contents/
mkdir ${APP_ABSDIR}/Contents/MacOS  # The top level executable shown in launcher
mkdir -p ${RSRC_ABSDIR}             # Most files go here
mkdir -p ${DYNLIB_ABSDIR}           # System shared libraries

##### Opam folder variables #####

# The opam prefix - stripped from absolute paths to create relative paths
OPAM_PREFIX="$(opam conf var prefix)"

##### MacPorts/Brew folder variables #####

set +e
PORTCMD="$(which port)"
set -e

if [ -z "${PORTCMD}" ]; then
  PKG_MANAGER=brew
  PKG_MANAGER_ROOT="/usr/local/"
  PKG_MANAGER_ROOT_STRIP="/usr/local/Cellar/*/*/" # one * for the package name and one for its version
else
  PKG_MANAGER=port
  # If someone knows a better way to find out where port is installed, please let me know!
  PKG_MANAGER_ROOT="${PORTCMD%bin/port}"
  PKG_MANAGER_ROOT_STRIP="${PORTCMD%bin/port}"
fi

###################### UTILITY FUNCTIONS ######################

# Check if a space separated list contains an item
# $1 = list
# $2 = item

function list_contains {
    [[ " $1 " == *" $2 "* ]]
}

# Check if a list contains an item with prefix
# $1 = list
# $2 = prefix

function list_contains_prefix {
    [[ " $1 " == *" $2"* ]]
}

# Find shared library dependencies and patch one binary using macpack
# $1 full path to binary
# $3 relative path from binary to "${RSRC_ABSDIR}" filder

> logs/macpack.log

function add_dylibs_using_macpack {
  type="$(file -b $1)"
  if [ "${type}" == 'Mach-O 64-bit executable x86_64' ] || [ "${type}" == 'Mach-O 64-bit bundle x86_64' ]
  then
    echo "Copying shared libraries for $1 ..."
    macpack -v -d "$2"/lib/dylib $1 >> logs/macpack.log
  else
    echo "INFO: File '$1' with type '${type}' ignored in shared library analysis."
  fi
}

# Add files from a Brew package using package name and grp filter
# $1 = Package name
# $2 = regexp filter (grep)
# Note:
# This function strips the install path of the "port" command

function add_files_of_package {
  case $PKG_MANAGER in
  port)
    LIST_PKG_CONTENTS="port contents"
  ;;
  brew)
    LIST_PKG_CONTENTS="brew ls -v"
  ;;
  esac
  echo "Copying files from package $1 ..."
  for file in $($LIST_PKG_CONTENTS "$1" | grep "$2" | sort -u)
  do
    relpath="${file#${PKG_MANAGER_ROOT_STRIP}}"
    reldir="${relpath%/*}"
    mkdir -p "$RSRC_ABSDIR/$reldir"
    cp "$file" "$RSRC_ABSDIR/$reldir/"
  done
}

# Add a folder recursively
# $1 = path prefix (absolute)
# $2 = relative path to $1 and ${RSRC_ABSDIR} (must not start with /)

function add_folder_recursively {
  echo "Copying files from folder $1/$2 ..."
  mkdir -p "${RSRC_ABSDIR}/$2/"
  cp -R "$1/$2/" "${RSRC_ABSDIR}/$2/"
}

# Add a single file
# $1 = path prefix (absolute)
# $2 = relative path to $1 and ${RSRC_ABSDIR}
# $3 = file name

function add_single_file {
  echo "Copying single file $1/$2/$3"
  mkdir -p "${RSRC_ABSDIR}/$2"
  cp "$1/$2/$3" "${RSRC_ABSDIR}/$2/"
}

# Taken from Adwanita's Makefile
# $1 = root of the icon theme

function make_theme_index {
pushd "$1"

cat> index.theme <<'EOT'
[Icon Theme]
Name=Adwaita
Comment=The Only One
Example=folder

EOT
echo "Directories=$(find */* -type d | tr -s "\n" ,)" >> index.theme
echo "" >> index.theme

(
for dir in `find */* -type d`; do
    sizefull="`dirname $dir`"
    if test "$sizefull" = "scalable"; then
        size="16"
    elif test "$sizefull" = "scalable-up-to-32"; then
        size="16"
    else
        size="`echo $sizefull | sed -e 's/x.*$//g'`"
    fi
    context="`basename $dir`"
    echo "[$dir]"
    if test "$context" = "actions"; then
        echo "Context=Actions"
    fi
    if test "$context" = "animations"; then
        echo "Context=Animations"
    fi
    if test "$context" = "apps"; then
        echo "Context=Applications"
    fi
    if test "$context" = "categories"; then
        echo "Context=Categories"
    fi
    if test "$context" = "devices"; then
        echo "Context=Devices"
    fi
    if test "$context" = "emblems"; then
        echo "Context=Emblems"
    fi
    if test "$context" = "emotes"; then
        echo "Context=Emotes"
    fi
    if test "$context" = "intl"; then
        echo "Context=International"
    fi
    if test "$context" = "mimetypes"; then
        echo "Context=MimeTypes"
    fi
    if test "$context" = "places"; then
        echo "Context=Places"
    fi
    if test "$context" = "status"; then
        echo "Context=Status"
    fi
    if test "$context" = "ui"; then
        echo "Context=UI"
    fi
    if test "$context" = "legacy"; then
        echo "Context=Legacy"
    fi
    echo "Size=$size"
    if test "$sizefull" = "scalable"; then
        echo "MinSize=8"
        echo "MaxSize=512"
        echo "Type=Scalable"
    elif test "$sizefull" = "scalable-up-to-32"; then
        echo "MinSize=16"
        echo "MaxSize=32"
        echo "Type=Scalable"
    elif test "$size" = "256"; then
        echo "MinSize=56"
        echo "MaxSize=256"
        echo "Type=Scalable"
    elif test "$size" = "512"; then
        echo "MinSize=56"
        echo "MaxSize=512"
        echo "Type=Scalable"
    else
        echo "Type=Fixed"
    fi
    echo ""
done
) >> index.theme

popd
}

# Check if a URL exists
# $1 url

function check_url {
  curl --head --silent --fail "$1" >/dev/null
}

# Check if an (opam) license name has an SPDX record
# $1 = name of license
# $2 = name of package (for warnings)

declare -A SPDX_LICENSE

function check_spdx_license {
  if [ -z ${SPDX_LICENSE[$1]+_} ]
  then
    if check_url "https://spdx.org/licenses/$1.html"
    then
      SPDX_LICENSE[$1]=yes
    else
      SPDX_LICENSE[$1]=no
    fi
  fi

  if [ "${SPDX_LICENSE[$1]}" == "yes" ]
  then
      return 0
  else
    echo "License for package '$2' with name '$1' has no SPDX record" >> WARNINGS.log
    return 1
  fi
}

###### Get filtered list of explicitly installed packages #####

# Note: since both positive and negative filtering makes sense, we do both and require that the result is identical.
# This ensures people get what they expect.

echo "Create primary package list"

packages_pos="$(opam list --installed-roots --short --columns=name | grep '^coq\|^menhir\|^gappa' | tr -s '\n' ' ')"
packages_neg="$(opam list --installed-roots --short --columns=name | grep -v '^ocaml\|^opam\|^depext\|^conf\|^lablgtk\|^elpi' | tr -s '\n' ' ')"

if [ "$packages_pos" != "$packages_neg" ]
then
  echo "The positive and negative list of opam packages differs. Please adjust the package filters!"
  echo "Positive list = $packages_pos"
  echo "Negative list = $packages_neg"
  exit 1
fi

PRIMARY_PACKAGES="$packages_pos"

###### Associative array with package name -> file filter (regexp pattern) #####

# If no white list regexp is given it is "."
# If no black list list regexp is given it is "\.byte\.exe$"

declare -A OPAM_FILE_WHITELIST
declare -A OPAM_FILE_BLACKLIST

OPAM_FILE_WHITELIST[lablgtk3]="stubs.dll$" # we keep only the stublib DLL, the rest is linked in coqide
OPAM_FILE_WHITELIST[lablgtk3-sourceview3]="stubs.dll$" # we keep only the stublib DLL, the rest is linked in coqide
OPAM_FILE_WHITELIST[cairo2]="stubs.dll$" # we keep only the stublib DLL, the rest is linked in coqide

###### Lits of packages to ignore #####

# Note: it is more efficient to ignore a package than to blacklist / not whitelist all files in it

# OCaml compiler and tools

IGNORED_PACKAGES="ocaml-variants ocaml-base-compiler base ocaml-compiler-libs ocaml-secondary-compiler ocamlfind-secondary"
IGNORED_PACKAGES="${IGNORED_PACKAGES} dune configurator sexplib0 csexp ocamlbuild result cppo"

# Packages linked into elpi

IGNORED_PACKAGES="${IGNORED_PACKAGES} elpi camlp5 ppxlib ppx_deriving ocaml-migrate-parsetree re"

# Regexp for packages to ignore

IGNORED_PACKAGES_RE="^conf-"

###### Function for analyzing one package

# Analyze one package
# - retrieve list of files and copy to ${RSRC_ABSDIR}
# - retrieve dependencies and add to list of dependent packages
# $1 = package name
# $2 = dependency level

function process_package {
  echo "Copying package $1 ($2) ..."

  # Copy files

  if [ ${OPAM_FILE_WHITELIST[$1]+_} ]
  then
    whitelist="${OPAM_FILE_WHITELIST[$1]}"
  else
    whitelist="." # take everything
  fi

  if [ ${OPAM_FILE_BLACKLIST[$1]+_} ]
  then
    blacklist="${OPAM_FILE_BLACKLIST[$1]}"
  else
    blacklist="(\.byte|\.cm[aiox]|\.cmxa|\.o|\.a|\.glob)$" # exclude byte code and library stuff
  fi

  files="$(opam show --list-files $1 | grep -E "$whitelist" | grep -E -v "$blacklist" )" || true
  if echo "$files" | grep '(modified since)' > /dev/null
  then
    echo "The package '$1' contains files which have been modified since opam installed them." >> WARNINGS.log
    files=${files//(modified since)/}
  fi
  for file in $files
  do
    if [ -d "$file" ]
    then
      true # ignore directories
    elif [ -f "$file" ]
    then
      relpath="${file#$OPAM_PREFIX}"
      reldir="${relpath%/*}"
      mkdir -p "$RSRC_ABSDIR/$reldir"
      cp "$file" "$RSRC_ABSDIR/$reldir/"
    else
      echo "In package '$1' the file '$file' does not exist"
      exit 1
    fi
  done

  # handle dependencies
  # Note: the --installed is required cause of an opam bug.
  # See https://github.com/ocaml/opam/issues/4461
  dependencies="$(opam list --required-by=$1 --short --installed)"
  for dependency in $dependencies
  do
    # Check if dependency is already in the list of known packages
    if ! list_contains "$PACKAGES_DONE" "$dependency"
    then
      # Even if teh package is excluded by IGNORED_PACKAGES_RE, we still want it in the list
      # so that we can produce an accurate dependency list
      PACKAGES_DONE="$PACKAGES_DONE $dependency"
      if [[ ! "$dependency" =~ ${IGNORED_PACKAGES_RE} ]]
      then
        process_package "$dependency" $(($2 + 1))
      fi
    fi
  done
}

###################### TOP LEVEL FILE GATHERING ######################

###### Go through selected packages and recursively analyze dependencies #####

echo '##### Copy Opam packages #####'

# The initial list of already processed, otherwise processed or ignored packages
PACKAGES_DONE="$PRIMARY_PACKAGES $IGNORED_PACKAGES"

for package in $PRIMARY_PACKAGES
do
  process_package "$package" 0
done

##### Find system shared libraries the installed binaries depend on #####

echo '##### Copy system shared libraries #####'

# Copy dynamically loaded (invisible for 'otool') shared libraries for GDK and GTK

PIXBUF_LOADER_ABSDIR="$RSRC_ABSDIR/lib/gdk-pixbuf-2.0/2.10.0/loaders"
mkdir -p "$PIXBUF_LOADER_ABSDIR"
PIXBUF_LOADER_RELDIR="$(grealpath --relative-to="$PIXBUF_LOADER_ABSDIR" "$RSRC_ABSDIR")"
for file in $(gdk-pixbuf-query-loaders | grep pixbufloader | sed s/\"//g); do
  cp ${file} "$PIXBUF_LOADER_ABSDIR/"
done
# the paths are absolue and need to be adjustes to APP_NAME
(cd "$PIXBUF_LOADER_ABSDIR/"; \
 GDK_PIXBUF_MODULEDIR=. gdk-pixbuf-query-loaders | \
   sed "s|^\"\\./|\"/Applications/${APP_NAME}/Contents/Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders/|" > loaders.cache)


IMMODULES_ABSDIR="$RSRC_ABSDIR/lib/gtk-3.0/3.0.0/immodules"
mkdir -p "$IMMODULES_ABSDIR"
IMMODULES_RELDIR="$(grealpath --relative-to="$IMMODULES_ABSDIR" "$RSRC_ABSDIR")"
for file in $(gtk-query-immodules-3.0 | grep /im- | sed s/\"//g); do
  cp ${file} "$IMMODULES_ABSDIR"
done
# the paths are absolue and need to be adjustes to APP_NAME
(cd "$IMMODULES_ABSDIR/"; \
 gtk-query-immodules-3.0 | \
   sed "s|^\".*/immodules/|\"/Applications/${APP_NAME}/Contents/Resources/lib/gtk-3.0/3.0.0/immodules/|" > immodules.cache)

for file in $(find "${BIN_ABSDIR}" -type f)
do
  add_dylibs_using_macpack "${file}" ".."
done

for file in $(find "$PIXBUF_LOADER_ABSDIR" -type f)
do
  add_dylibs_using_macpack "${file}" "$PIXBUF_LOADER_RELDIR"
done

for file in $(find "$IMMODULES_ABSDIR" -type f)
do
  add_dylibs_using_macpack "${file}" "$IMMODULES_RELDIR"
done

# Dynamic library debug output

if [ "$OTOOLDUMP" == 'Y' ]
then
  > logs/otool.log
  for file in $BIN_ABSDIR/* $DYNLIB_ABSDIR/* $PIXBUF_LOADER_ABSDIR/* $IMMODULES_ABSDIR/*
  do
    otool -L $file >> logs/otool.log
  done
fi

##### Add files from additional macports packages #####

### Adwaita icon theme

add_files_of_package "adwaita-icon-theme"  \
"/\(16x16\|22x22\|32x32\|48x48\)/.*\("\
"actions/bookmark\|actions/document\|devices/drive\|actions/format-text\|actions/go\|actions/list\|"\
"actions/media\|actions/pan\|actions/process\|actions/system\|actions/window\|"\
"mimetypes/text\|mimetypes/inode\|mimetypes/application\|"\
"places/folder\|places/user\|status/dialog\|ui/pan\|"\
"legacy/document\|legacy/go\|legacy/process\|legacy/window\|legacy/system\)"

make_theme_index "${RSRC_ABSDIR}/share/icons/Adwaita/"


### GTK compiled schemas

add_single_file "${PKG_MANAGER_ROOT}" "share/glib-2.0/schemas" "gschemas.compiled"

### GTK sourceview languag specs and styles (except coq itself)

# Not really everything is needed from this. These might suffice:
# language-specs/dev.lang
# language-specs/language.dtd
# language-specs/language.rng
# language-specs/language2.rng
# styles/classic.xml
# But since the complete set is compressed not that large, we add the complete set

add_folder_recursively "${PKG_MANAGER_ROOT}" "share/gtksourceview-3.0"

##### MacOS DMG installer specific files #####

# Find CoqIDE folder

if [ -d coq/ide/coqide ]
then 
  coqidefolder=coq/ide/coqide
elif [ -d coq/ide  ]
then
  coqidefolder=coq/ide
else
  echo "ERROR: cannot find CoqIDE folder"
fi

# Create Info.plist file

sed -e "s/VERSION/${COQ_VERSION_MACOS}/g" ../macos/Info.plist.template > \
    ${APP_ABSDIR}/Contents/Info.plist

# Rename coqide to coqide.exe

mv ${BIN_ABSDIR}/coqide ${BIN_ABSDIR}/coqide.exe

# Create a shell script to start CoqIDE with correct environmant

cat> ${BIN_ABSDIR}/coqide <<'EOT'
#!/bin/sh

# Check if $0 is a link
if [ -L "$0" ]
then
  LINKTARGET="$(readlink "$0")"
  # Check if $0 is a an absolute or relative link
  if [[ "$LINKTARGET" == '/'* ]]
  then
    BINDIR="$(dirname "$LINKTARGET")"
  else  
    BINDIR="$(dirname "$0")/$(dirname "$LINKTARGET")"
  fi
else
  BINDIR="$(dirname "$0")"
fi

# Normalize path
BINDIR="$(cd "$BINDIR" ; pwd)"
ROOTDIR="$(cd "$BINDIR/.." ; pwd)"
  
export PATH="${BINDIR}:${PATH}"

# This setting is required to find the image file format handlers
# Note: these docs are contradicting on the default path for the "loaders.cache" file
# https://developer.gnome.org/gdk-pixbuf/stable/gdk-pixbuf-query-loaders.html
# https://developer.gnome.org/gtk3/stable/gtk-running.html
# Setting GTK_EXE_PREFIX to ROOTDIR and putting the file into lib/gtk-3.0/3.0.0/loaders.cache doesn't work.
export GDK_PIXBUF_MODULE_FILE="${ROOTDIR}/lib/gdk-pixbuf-2.0/2.10.0/loaders/loaders.cache"

# This setting is required to find the "Input Method" handlers
# ToDo: the cache file links to locales, but we don't install locales
# ToDo: the selection of input methods seems questionable (with MacPorts)
# ToDo: not sure if this is needed at all on Mac (which should have its own IME)
export GTK_IM_MODULE_FILE="${ROOTDIR}/lib/3.0/3.0.0/immodules.cache"

# This setting is required to find the adwaita icon theme
export XDG_DATA_HOME="${ROOTDIR}/share"

exec ${BINDIR}/coqide.exe
EOT
chmod a+x ${BIN_ABSDIR}/coqide

# Create a symlink in Contents/MacOS

ln -sf ../Resources/bin/coqide ${APP_ABSDIR}/Contents/MacOS/coqide

# Icons

cp ${coqidefolder}/MacOS/*.icns ${RSRC_ABSDIR}

# Create a link to the 'Applications' folder, so that one can drag and drop the application there

ln -sf /Applications _dmg/Applications

##### Create README.html #####

echo '##### Create README.html #####'

cat > _dmg/README.html <<EOT
<html>
<head>
<title>The Coq platform - $COQ_PLATFORM_VERSION</title>
<style>
body {
   width : 50em;
   margin-left : auto;   
   margin-right : auto;   
}
h1,h2 {
  text-align : center;
  font-family : sans-serif;
}
dt {
  font-family : sans-serif;
  font-weight : bold;
}
dd { 
  margin-bottom : 1em;
}
</style>
</head>
<body>
<h1>The Coq Platform $COQ_PLATFORM_VERSION</h1>
<p>
  The <a href="https://coq.inria.fr">Coq interactive prover</a> provides
  a formal language to write
  mathematical definitions, executable algorithms, and theorems, together
  with an environment for semi-interactive development of machine-checked
  proofs.
</p>
<p>
  The <a href="https://github.com/coq/platform">Coq Platform</a>
  is a distribution of the Coq interactive prover together
  with a selection of Coq libraries.
</p>
EOT

if list_contains_prefix "$PRIMARY_PACKAGES" 'coq-compcert'
then
echo "Added license note for CompCert"
cat >> _dmg/README.html <<EOT
<p>
  Please note that this release of the Coq Platform contains software with
  <b>non-free licenses which do not allow commercial use</b>, notably the
  <b>coq-compcert</b> package. Please study the package licenses given
  below and verify that they are compatible with your intended use.
</p>
EOT
fi

cat >> _dmg/README.html <<EOT
<h2>Coq Platform $COQ_PLATFORM_VERSION packages</h2>
<p>
  The Coq platform version $COQ_PLATFORM_VERSION
  contains the following packages:
</p>
<dl>
EOT

# Create an readme entry for an opam package
# $1 = opam package name
# $2 = true for primary, false for secondary packages

function html_package_opam {
  echo "Create README for $1"

  # Get package informatop from opam
  # Example output (with 2 license fields ...)
  # opam show "conf-adwaita-icon-theme" -f version:,license:,synopsis:,homepage:
  # version:  "1"
  # license:  "LGPL-3.0-only" "CC-BY-SA-3.0"
  # synopsis: "Virtual package relying on adwaita-icon-theme"
  # homepage: "https://github.com/GNOME/adwaita-icon-theme"
  # Note: the process substition (rather than pipe) avoids a subshell, so that variables can be set.
  # Note: the declare -a var="(list)" makes it possible to convert a list of quoted strings to an array
  unset pversion plicense psynopsis phomepage
  while read var value
  do
    case "${var}" in
      version:)  pversion="${value//\"}" ;;
      license:)  declare -a plicense="(${value})" ;;
      synopsis:) psynopsis="${value//\"}" ;;
      homepage:) phomepage="${value//\"}" ;;
      *) echo "Unexpected result from opam show: $var $value"; exit 1 ;;
    esac
  done < <(opam show "$1" -f version:,license:,synopsis:,homepage:)
  
  # Remove conf- prefix for printing of package name
  package_pretty=${package/conf-}

  # Do basic HTML escaping for synposis
  # I used 'recode' for this, but it is rather fragile, and this should be good enough
  psynopsis="${psynopsis//&/&amp;}"
  psynopsis="${psynopsis//</&lt;}"
  psynopsis="${psynopsis//>/&gt;}"
  psynopsis="${psynopsis//\"/&quot;}"
  psynopsis="${psynopsis//\'/&apos;}"

  # Elaborate license information
  if [ ${#plicense[@]} -eq 0 ]
  then
    echo "License for package '${package}' is unspecified" >> WARNINGS.log
    licensehtml="unknown - please clarify with <a href=\"${phomepage}\" target=\"_blank\">homepage</a>"
  else
    licensehtml=""
    for license in "${plicense[@]}"
    do
      license="${license//\"}"
      license=${license/CeCILL/CECILL}
      if [[ "${license}" == 'https://'* ]] || [[ "${license}" == 'http://'* ]]
      then
        licensehtml="${licensehtml} <a href=\"${license}\" target=\"_blank\">link</a>"
      elif check_spdx_license "${license}" "${package}"
      then
        licensehtml="${licensehtml} <a href=\"https://spdx.org/licenses/${license}.html\" target=\"_blank\">${license}</a>"
      else
        licensehtml="${licensehtml} ${license} - see <a href=\"${phomepage}\" target=\"_blank\">homepage</a> for details"
      fi
    done
  fi

  # Look up the opam package
  if [[ "$1" == "coq-"* ]]
  then
    popam_url="https://github.com/coq/opam-coq-archive/tree/master/released/packages/${package}/${package}.${pversion}/opam"
  else
    popam_url="https://github.com/ocaml/opam-repository/tree/master/packages/${package}/${package}.${pversion}/opam"
  fi
  if [ "${CHECKOPAMLINKS}" == 'Y' ] && ! check_url "${popam_url}"
  then
    echo "Opam url '${popam_url}' for package '${package}' does not exist!" >> WARNINGS.log
  fi

  # Create final HTML text for package
  if $2
  then
    printf "<dt><a href='%s'>%s</a> (%s)</dt><dd>%s (license: %s, package: <a href='%s'>opam</a>)</dd>\n" \
      "${phomepage}" "${package_pretty}" "${pversion}" "${psynopsis}" "${licensehtml}" "${popam_url}" \
      >> _dmg/README.html
  else
    printf "<p><a href='%s'>%s</a> (opam-version: %s, license: %s, package: <a href='%s'>opam</a>)</p>\n" \
      "${phomepage}" "${package_pretty}" "${pversion}" "${licensehtml}" "${popam_url}" \
      >> _dmg/README.html
  fi
}

for package in $(echo ${PRIMARY_PACKAGES} | tr -s ' ' '\n' | sort)
do
  html_package_opam "${package}" true
done

cat >> _dmg/README.html <<EOT
</dl>
<h2>Dependecy packages</h2>
<p>
  In addition the dependencies listed below are partially or fully included.
  Please note, that the version numbers given are the versions of opam packages,
  which do not always match with the version of the supplied packages.
  E.g. some opam packages just refer to packages e.g. installed by MacPorts or Homebrew.
  Please refer to the linked opam package for details on what software is used.
</p>
<dl>
EOT

# sort packages by name, but ignore a "conf-" prefix
for package in $(echo $PACKAGES_DONE | tr -s ' ' '\n' | sed -E 's/(.*)/\1 \1/' | sed 's/^conf-//' | sort | cut -d ' ' -f2)
do
  # Note: we do not ignore "IGNORED_PACKAGES" here, because they might still be linked in
  if ! list_contains "${PRIMARY_PACKAGES}" "${package}"
  then
    html_package_opam "${package}" false
  fi
done

cat >> _dmg/README.html <<'EOT'
</dl>
</body>
</html>
EOT


###################### CREATE INSTALLER ######################

##### Create DMG image from folder #####

echo '##### Create DMG image #####'

hdi_opts=(-volname "${DMG_NAME}"
          -srcfolder _dmg
          -ov # overwrite existing file
          ${ZIPCOMPR}
          # needed for backward compat since macOS 10.14 which uses APFS by default
          # see discussion in #11803
          -fs hfs+
         )
hdiutil create "${hdi_opts[@]}" "${DMG_NAME}.dmg"

echo "##### Finished installer '${DMG_NAME}.dmg' #####"

##### Show wanrings #####

if [ -f WARNINGS.log ]
then
  echo "##### WARNINGS for '${DMG_NAME}.dmg' #####"
  cat WARNINGS.log
  echo "##### END OF WARNINGS for '${DMG_NAME}.dmg' #####"
fi

##### Simply copy the folder over to the Applications folder #####

if [ "${INSTALL}" == 'Y' ]
then
  echo '##### Copying to /Applications folder #####'
  rm -rf "/Applications/${APP_NAME}"
  cp -R "${APP_ABSDIR}" '/Applications/'
fi
