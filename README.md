# Andronix-Termux-Proot-Chrome-Fix-XFCE-Ubuntu-22.04
A simple script aimed at modifying ubuntu XFCE .desktop files so that Chromium can properly start and operate in a proot environment such as Andronix (tested on Ubuntu 22.04) on Android. This repairs startup issues associated with default apps settings and Chromium.

## License & acknowledgements

This project is released under the [MIT License](LICENSE) — Copyright (c) 2026 Talbot Simons (mr-tbot).

Everything in this repository is original work: one bash script and this README. No other project's code is bundled, vendored, submoduled, or redistributed here. The script only rearranges files that are already on your own system, and with `--with-atspi` it asks your own `apt-get` to fetch `at-spi2-core` from the Ubuntu archive. Because nothing third-party ships in this repo, there is no third-party license for it to carry.

Chromium is a [BSD-3-Clause](https://chromium.googlesource.com/chromium/src/+/main/LICENSE) project, `at-spi2-core` is LGPL-2.1+, and `xdg-utils` is MIT. All three are installed by you or by your base image, and are wrapped or invoked as separate programs — never copied into this repository. Invoking or wrapping a GPL/LGPL program as a subprocess does not make this script a derivative work of it.

"Andronix" and "Termux" are the names of their respective projects and are used here only to describe the environment this script targets. This is an independent third-party fix, not endorsed by, affiliated with, or supported by either project.

**Heads up:** this script replaces `/usr/bin/chromium` on the machine you run it on and edits system `.desktop` and XDG defaults. It is provided "as is", without warranty of any kind, as stated in the MIT License. Run it inside the proot/container guest it was written for — not on a desktop you care about.
