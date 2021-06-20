# Creating variants of the Coq platform

The script is modular and should be easy to adopt to specific needs, e.g. a special setup for a lecture.

The main points of modifications are:

- the package list [`coq_platform_packages.sh`](/coq_platform_packages.sh)
  - add or remove packages according to your requirements
  - you should include specific versions to get a reproducible result - the opam database changes daily and unless you specify a
    version you get different results and quite possibly the build will fail
  - **please always change the opam switch name** to some specific to your application by changing [`versions/coq_platform_switch_name.sh`](/versions/coq_platform_switch_name.sh) in case you modify the package list or other features

- the main script [`coq_platform_make.sh`](/coq_platform_make.sh)
  - replace interactive questions with predefined settings
  - you should not remove the question on parallelism and RAM size unless you prepare a script e.g. for severs with a known configuration
  - add new questions and / or command line options
  - command line options should also be added to [`coq_platform_make_windows.bat`](/coq_platform_make_windows.bat)

If you have specific needs, please contact us on zulip chat [`Coq-Platform & users`](https://coq.zulipchat.com/#narrow/stream/250632-Coq-Platform.20devs.20.26.20users)