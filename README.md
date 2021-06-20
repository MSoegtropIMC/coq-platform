# Coq platform

The Coq platform is a distribution of the Coq proof assistant together with a selection of Coq libraries.
It provides a set of scripts to compile and install OPAM, Coq, Coq libraries and Coq plugins on MacOS,
Windows and many Linux distributions in a reliable way with consistent results.

See [Charter](charter.md) for the coq platform concept.

# Note on Licenses

The Coq platform setup scripts and the selection of packages and patches are licensed Creative Commons CC0.
This license does **not** apply to the packages installed by the Coq platform.
You can get an overview over the licenses of the installed software (after installing it)
with the command:
```
opam list --columns=name,license:
```
In case no license is given please clarify on the homepage of the software:
```
opam list --columns=name,homepage:
```
Please note that some opam packages require and install system packages with many dependencies (e.g GTK3).
These dependencies might have various licenses. You need to refer to your system package manager to
inspect the licenses of such packages.

# Features of the 2021.02.1 release

- fully opam based, also on Windows
- single script call to install system dependencies, opam (if not there), a fresh opam switch and the coq platform
- interactive (well script based) guidance of the user through the few parameters
- The list of included packages is:
```
coq                      8.13.2      Formal proof management system
coqide                   8.13.2      IDE of the Coq formal proof management system
coq-aac-tactics          8.13.0      Coq plugin providing tactics for rewriting universally quantified equations, modulo associative (and possibly commutative) operators
coq-bignums              8.13.0      Bignums, the Coq library of arbitrary large numbers
coq-compcert             3.8         The CompCert C compiler (64 bit)
coq-coquelicot           3.1.0       A Coq formalization of real analysis compatible with the standard library
coq-elpi                 1.8.1       Elpi extension language for Coq
coq-equations            1.2.3+8.13  A function definition package for Coq
coq-ext-lib              0.11.3      A library of Coq definitions, theorems, and tactics
coq-flocq                3.3.1       A formalization of floating-point arithmetic for the Coq system
coq-gappa                1.4.6       A Coq tactic for discharging goals about floating-point arithmetic and round-off errors using the Gappa prover
coq-hierarchy-builder    1.0.0       High level commands to declare and evolve a hierarchy based on packed classes
coq-hott                 8.13        The Homotopy Type Theory library
coq-interval             4.1.1       A Coq tactic for proving bounds on real-valued expressions automatically
coq-mathcomp-algebra     1.12.0      Mathematical Components Library on Algebra
coq-mathcomp-bigenough   1.0.0       A small library to do epsilon - N reasonning
coq-mathcomp-character   1.12.0      Mathematical Components Library on character theory
coq-mathcomp-field       1.12.0      Mathematical Components Library on Fields
coq-mathcomp-fingroup    1.12.0      Mathematical Components Library on finite groups
coq-mathcomp-finmap      1.5.1       Finite sets, finite maps, finitely supported functions
coq-mathcomp-real-closed 1.1.2       Mathematical Components Library on real closed fields
coq-mathcomp-solvable    1.12.0      Mathematical Components Library on finite groups (II)
coq-mathcomp-ssreflect   1.12.0      Small Scale Reflection
coq-menhirlib            20200624    A support library for verified Coq parsers produced by Menhir
coq-mtac2                1.4+8.13    Mtac2: Typed Tactics for Coq
coq-quickchick           1.5.0       Randomized Property-Based Testing Plugin for Coq
coq-simple-io            1.5.0       IO monad for Coq
coq-unicoq               1.5+8.13    An enhanced unification algorithm for Coq
coq-vst                  2.7.1       Verified Software Toolchain
gappa                    1.3.5       Tool intended for formally proving properties on numerical programs dealing with floating-point or fixed-point arithmetic
menhir                   20200624    An LR(1) parser generator
```
- one unified setup script for Windows, macOS and Linux with few OS dependent sections only
- on Windows there is an additional wrapper batch script to setup Cygwin as build and working environment
- on Windows there is in addition a classic Windows installer mostly intended for quick installation by beginners
- it is easy to build variants of the Windows installer with modified content from an existing opam switch
- system prerequisites are installed using opam depext in a system independent manner
- the script should be fairly robust and safe - it will immediately abort an all errors not explicitly handled
- the script can be restarted if it fails - e.g cause of internet issues - it will not redo things it already did
- the scripts are modular and easy to configure for specific needs, e.g. a reduced or extended setup for a lecture - see [`variants.md`](/variants.md)

## Changes from 2021.02.0 to 2021.02.1

- Added DMG package / installer for macOS
- Coq and CoqIDE update to version 8.13.2 (bugfix release)
- VST updated to version 2.7.1 (bugfix release)
- New package `coq-hott` *The Homotopy Type Theory library*

# Usage of the 2021.02.1 release

Please refer to the ReadMe file for your OS.

- macOS: see [README_macOS](README_macOS.md).
- Windows: see [README_Windows](README_Windows.md)
- Linux: see [README_Linux](README_Linux.md).

## Installation of additional packages or package variants

### CompCert and VST variants

For some packages, notably CompCert and VST (the Princeton tool-chain for verification of C code), exist various variants.
By default the 64 bit variant of CompCert and the 64 bit variant of VST are installed.

CompCert is **not** free / open source software, but may be used for research and
evaluation purposes. Please clarify the license at [CompCert License](https://github.com/AbsInt/CompCert/blob/master/LICENSE).

Parts of CompCert are required for the Princeton C verification tool VST.
Some parts of CompCert are open source and for exploring or learning VST
using the supplied example programs, this open source part is sufficient.
If you want to use VST with your own C code, you need the non open source
variant of CompCert. Before you install the full non-free version of CompCert,
please make sure that your intended usage conforms to the above license.

The script will ask which variant of CompCert you want to install.

The compilation of VST takes quite a while on slow / small RAM PCs. For this reason the script also asks if you want to install VST.

You can change the selection of packages any time later by issuing `opam install` commands, e.g.
```
opam install coq-compcert.3.8~open_source (not yet supported by 2021.02.1)
opam install coq-compcert.3.8
opam install coq-vst.2.7.1
```

Besides the open source and non open source variant of CompCert, there is also a 32 bit variant of CompCert and VST, which can
be installed by running these commands:
```
opam install coq-compcert-64.3.8
opam install coq-vst-64.2.7.1
```
or by adjusting [`coq_platform_packages.sh`](/coq_platform_packages.sh) accordingly.
Please note that since both variants can be installed in parallel, only one, the 32 bit variant, is immediately available to Coq
without -Q and -R options. If you want to work with the 64 bit variants, please use these options in your Coq project:
```
-Q $(coqc -where)/../coq-variant/compcert64/compcert compcert
-Q $(coqc -where)/../coq-variant/VST64/VST VST
```

### Installation of other packages

- On Windows open a shell with `C:\<your_coq_platform_cygwin_path>\cygwin.bat`.
- On Linux or macOS open a shell in the usual way.
- Run these commands:
    ```
    opam switch __coq-platform.2021.02.1.8.13
    eval $(opam env)
    ```
    (note: the switch name might vary if you choose a different version of Coq - please use `opam switch` to see a list of switch names)
- Install additional packages with `opam install "package"`
- You can find packages with `opam list --all | grep "some keyword"`
