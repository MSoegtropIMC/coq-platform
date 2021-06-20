This README presents the two standard methods to install the platform on Linux:
- as a binary Snap package,
- from sources, using the platform scripts.

The first method is recommended for beginners and the second one is recommended for experienced users, who may want to use opam to install additional packages, beyond the standard set provided by the platform.

# Installation using Snap package

URL: https://snapcraft.io/coq-prover

Maintainer: Enrico Tassi

## Package name
The name of the package is `coq-prover` since `coq` was considered
unacceptable by the snap store admins (too short and non informative).

## Aliases
The snap package can install binaries in the path, but they are all called
`coq-prover.something` and `something` cannot contain `_`.

As per [request](https://forum.snapcraft.io/t/aliases-request-for-coq-prover/21925)
Coq is granted the `coqide -> coq-prover.coqide` and
`coq_makefile -> coq-prover.coq-makefile` aliases (shorthands generated
on the fly).

## Channels and updates
Each package is available on a channel, which is a combination of track and
risk level.
A track is something like `latest` (the default one) or, `major-version` (as
many packages do).
A risk level is something like `stable`, `beta`, `edge`.

By default users install from `latest/stable`.
The CI script uploads to `latest/edge`, then via a web ui the package
maintainer can promote a package from one level to another.

IMPORTANT: snap packages are *automatically* updated. This means that when *we*
make a new release the package installed by a user *silently* upgrades, no
questions asked!

A user can install from `latest/edge` to test the very last upload, but also,
and more interestingly, from `2021.02/stable` to *never* move to e.g. 2021.07 without
consent. This last option makes snap package also usable by developers (and
indeed one finds stuff like `node` or `go` distributed via snap).

CAVEAT: track's creation need to be explicitly requested. The store admins are
happy to grant quickly a new track if it follows the same schema of an existing
one.

## See also
- linux/snap/github_actions for a script to trigger a CI build for a platform
  branch also uploading to the snap store

## Snap doc

- [Channels](https://snapcraft.io/docs/channels)
- [Process for manual store actions (tracks, aliases)](https://forum.snapcraft.io/t/process-for-aliases-auto-connections-and-tracks/455)


# Installation by compiling from sources (using opam)

- Install buildtools
  - Debian, Ubuntu:       sudo apt-get install build-essential
  - CentOS, RHEL, Fedora: sudo dnf groupinstall "Development Tools"
  - OpenSuse:             sudo zypper in -t pattern devel_C_C++
- For CentOS and possibly RHEL some additional steps are required, see [CentOS](#centos) below.
- Get the coq platform scripts via either of these methods
  - `git clone --branch 2021.02 https://github.com/coq/platform.git`
  - download and extract `https://github.com/coq/platform/archive/2021.02.zip`
- Open a shell, navigate to the download folder and execute `coq_platform_make.sh`.
- The system will ask for sudo permissions to install prerequisites *several times* so the script is not fully unattended but all installations of dependencies are done directly after the initialization of the opam switch.
- In case the script aborts e.g. cause of internet issues, just rerun the script.
- The script creates a new opam switch named e.g. `__coq-platform.2021.02.1.8.13` - this means the script does not touch your existing opam setup unless you already have a switch of this name.
- Use the following commands to activate this switch after opening a new shell:
  - `opam switch __coq-platform.2021.02.1.8.13` (note: the switch name might vary if you choose a different version of Coq - please use `opam switch` to see a list of switch names)
  - `eval $(opam env)`
  - The second step can be automated by rerunning `opam init`
- The main opam repositories for Coq and OCaml developments are already added to the created opam switch, so it should be easy to install additional Coq (or OCaml) packages.
- CoqIDE can be started from the shell prompt with `coqide`.
- The full installation might require up to 5 GB of disk space.
- The setup script creates a folder `$HOME/coq-platform` where it stores a few files but this will likely be removed in future releases.

## CentOS: Enable sudo for current user

CentOS requires two additional steps. First sudo should be enabled, so that opam depext can work. opam depext automatically installs required system dependencies, which requires sudo rights. Since one cannot run the complete script as super user, there is no easy way around using sudo. The only method is to make sure that all prerequisites are installed upfront. One way to do this is to run the coq platform script until it asks for the sudo password and then see what it want's to do and do this as super user.

Sudo can be enabled for the current user as follows:
```
su
usermod -aG wheel username
exit
logout
login
```

## CentOS: Enable PowerTools repo

CentOS by default doesn't have things like the gtk-sourceview in its repo. Additional packages can be enabled with the following command:
```
sudo dnf config-manager --set-enabled PowerTools
```
This might not be required if you do not install CoqIDE, but this has not been tested. Possibly other opam packages also need packages from the CentOS PowerTools repo.
