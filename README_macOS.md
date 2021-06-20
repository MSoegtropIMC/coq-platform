# Installation

## Using the macOS DMG package

This method is intended for beginners.
For advanced users it is recommended to compile Coq from sources via opam (see next section).

In case you want to use the fast path:

- Download the DMG package from https://github.com/coq/platform/releases (click on "Assets" at the end of a release section).
- Open the downloaded DMG package with a double click.
- Drag and drop the "Coq_Platform_2021.02.1.app" icon on the link to the "Applications" folder.
- CoqIDE appears under `/Applications` in Finder and in Launcher.
- Beta releases of Coq Platform might contain unsigned packages, which macOS does not start by default. In case you get an error message
stating "Coq_Platform.app cannot be opened because the developer cannot be verified" either download a release package, or alternatively
right click the `Coq_Platform` app in `/Applications` in Finder and select `open`. You will see the same error message as before, but it will have an `Open` button now.
- In case you want to use the installed `coqc` from the command line, please add the folder `/Applications/Coq_Platform_2021.02.1.app/Contents/Resources/bin` to your `PATH`.
- If you want to inspect the installed content, right click the `Coq_Platform` app in `/Applications` in Finder and select `Show Package Contents`.

A note to lecturers: it is easy to create a customized Windows installer from an opam switch - see [Customized Installers](#customized-installers)

## Compiling from Sources via opam

This method is intended for advanced users who need additional flexibility and/or an advanced working environment.
For beginners it is recommended to use the macOS DMG installer (see previous section).

- Install XCode command line tools
  - On macOS Catalina & BigSur: open a console and enter `xcode-select --install` (takes about 5 minutes)
  - Earlier OS variants: Try if `xcode-select --install` works.
    In case this does not work, first install "XCode Developer Tools" from the App store (might take 1 hour) and try again.
- If you have neither Homebrew nor MacPorts installed, read the section [Homebrew and MacPorts](#homebrew-and-macports) below.
- If you have Homebrew installed, read the section [Homebrew issues and workarounds](#homebrew-issues-and-workarounds) below.
- Get the coq platform scripts via either of these methods
  - `git clone --branch 2021.02 https://github.com/coq/platform.git`
  - download and extract `https://github.com/coq/platform/archive/2021.02.zip`
- Open a shell, navigate to the download folder and execute `coq_platform_make.sh`.
- If you are using MacPorts, the system will ask for sudo permissions to install prerequisites *several times* so the script is not fully unattended but all installations of dependencies are done directly after the initialization of the opam switch.
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

# Homebrew and MacPorts

## Homebrew or MacPorts?

You need one or the other to install all the prerequisites required by the opam packages which make up the Coq platform. Installing all these packages manually is quite a bit of work - unless you are happy with a subset of the command line tools. Especially heavy in terms of dependencies are CoqIDE - alternatives are VSCoq for visual studio code and Emacs with Proof General - and the numerical proof tool GAPPA. The CoqPlatform installation does not require Homebrew or MacPorts - it just calls these to install dependencies. An important dependency is opam itself. In case you have all dependencies already installed (including opam) there is no need for either.

If you already have MacPorts or Homebrew installed, we recommend to keep what you have. If you have neither installed, below are a few differences which might help you decide.

### Differences between MacPorts and Homebrew

- MacPorts uses rsync transport - this is fast but can be an issue if you are behind a proxy. Using different transports is a bit complicated - e.g. one can use git or https zip download to get the package repository manually and point MacPorts to it, but then it won't update automatically. Homebrew uses git over https transport, which should work behind a proxy (if this doesn't work, not much else will work either).
- MacPorts requires sudo rights to install software while Homebrew makes its target folder (`/usr/local`) writable to the current user. Some people say there are security issues with the Homebrew approach. See [Is Homebrew safe?](#is-homebrew-safe) below for a short presentation of the arguments.
- Homebrew seems to be a bit more widely used with a bit broader package support than MacPorts, but for the Coq platform both work equally well.
- MacPorts uses /opt/local as default installation folder, while Homebrew uses /usr/local as default folder. On a plain fresh macOS, /usr/local is typically empty, but other software seems to use the same folder. Since Homebrew requires that /usr/local is writable to the current user this can result in issues. You might have to make /usr/local recursively writable by the current user and possibly even reinstall all Homebrew packages to solve such issues. See [Homebrew issues and workarounds](#homebrew-issues-and-workarounds) below. The folder used by MacPorts seems to be exclusively used by MacPorts, so it does not have similar issues. Definitely when you decide to install Homebrew fresh, you should check if `/usr/local` is empty, and if not run `sudo chown -R ${USER}:admin /usr/local/*` before you install Homebrew.
- MacPorts ports use a dedicated text format for port description files - similar to opam. Homebrew by contrast uses arbitrary Ruby programs as package description. So MacPorts is possibly more structured while Homebrew is more flexible.

## Installing

- For MacPorts installation follow the instructions at (https://www.macports.org/install.php) - that is download the installer package matching our OS version and double click on the downloaded package.

- For homebrew installation instructions see (https://brew.sh/index) - we followed the recommended approach
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` using the default location - see the next section on a discussion if this is safe.

## Is Homebrew safe?

There is an ongoing dispute if Homebrew's strategy of making the `/usr/local` folder writable to the current user is a good idea.
See e.g. (https://discourse.brew.sh/t/security-issues-using-Homebrew-malicious-insertion/3379) or various comments in (https://gist.github.com/irazasyed/7732946).

A short summary of the dispute:
- The Homebrew authors say that it is safer to make `/usr/local` writable to the current user and run installers without elevated rights, because this way an installer can only mess up `/usr/local` - which is not part of the core system - while an installer run with sudo rights can mess up any file in the system. This is a valid argument.
- The Homebrew critics say that making especially `/usr/local/bin` writable to the current user is dangerous, because it is the first folder in the default PATH. So an adversary could say put a version of `sudo` there which steals your admin password. The bad thing is that any program run by the user - even without elevated rights - could do this, since with Homebrew installed `/usr/local/bin` is writable for the current user. This is also a valid argument.

It is a dangerous thing to make `/usr/local/bin` writable to the current user, but the alternative - running `sudo make install` for 100 software packages - is also not free of danger. Also installing opam and putting `~/.opam/<switch>/bin` at the begin of the PATH opens the door to sneaking in adversarial programs in a similar way - with the big difference that opam by default doesn't do this in a fresh shell but only after you called `eval $(opam env)`.

The bottom line is: there is no entirely safe way to install 100s of open source packages. If you trust the community reviews of open source software, you might be better off with MacPorts. If you more trust Murphy's law you might be better of with following Homebrew's path to limit potential damage to `/user/local`.

## Homebrew issues and workarounds

- Homebrew makes part of `/usr/local` writable for the current user, but if `/usr/local` is also used by other software this might result in issues. Homebrew requires that `/usr/local` is writable to the current user, or at least these folders are:
  - `/usr/local/bin`
  - `/usr/local/etc`
  - `/usr/local/include`
  - `/usr/local/lib`
  - `/usr/local/sbin`
  - `/usr/local/share`
  - `/usr/local/var`
  - `/usr/local/opt`
  - `/usr/local/share/zsh`
  - `/usr/local/share/zsh/site-functions`
  - `/usr/local/var/homebrew`
  - `/usr/local/var/homebrew/linked`
  - `/usr/local/Cellar`
  - `/usr/local/Caskroom`
  - `/usr/local/Homebrew`
  - `/usr/local/Frameworks`

- In case any of the above folders exists and is not recursively writable by the current user, you need to run `sudo chown -R ${USER}:admin /usr/local/*` or alternatively the same for each of the above folders **before you install Homebrew**. See e.g. (https://github.com/Homebrew/brew/issues/2098) or (https://gist.github.com/irazasyed/7732946). Please read [Is Homebrew safe?](#is-homebrew-safe) above before you do this.

- In case you didn't issue the above command before installing Homebrew it might happen that you ended up with a broken pkg-config - a tool used to find libraries - so that installed libraries are not registered with pkg-config and not found. Fixing pkg-config after installing libraries doesn't help - the libraries won't register again with pkg-config. The only easy fix for this is to issue `brew uninstall $(brew list)`. Of cause this will uninstall all packages you might have installed. You can create a list with `brew list` before and then reinstall this list with `brew install paste mylist here`. If your main interest is the Coq platform there is no issue - the setup script will install everything it needs.

- During some tests on Homebrew, it was required to run `coq_platform_make.sh` at least twice. The first time some package installs failed cause of missing dependencies - the second time it worked. Some tests even needed 3 runs. If it doesn't work after 3 runs, try the above two procedures and try another 3 runs. Please note that in a installation of Homebrew on a fresh new Mac, there was no such issue - such issues where only observed if other software shares the `/usr/local` folder with Homebrew.
