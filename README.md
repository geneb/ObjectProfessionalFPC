# TurboPower Object Professional v1.30

This repository is for ongoing work to port the Object Professional development library to Free Pascal so it can be used with Windows and Linux.

It is a wholly separate project from the MS-DOS version as all "MS-DOSisms" will be stubbed out if there's no useful equivalent.

## Original README:

22 years ago, TurboPower Software closed their doors as a retail software company and released all of their development libraries the for Borland/CodeGear/Embarcadero Delphi compiler.  These items were released under a Mozilla 1.1 license.

Here's their original announcement: http://www.turbopower.com/

Unfortunately, nobody seems to have been able to get their attention about making their fantastic MS-DOS libraries for Turbo Pascal available online.

Their website clearly states, "TurboPower libraries released as open source".  Their MS-DOS libraries would appear to fall under that statement.  Maybe they figured, "Hey, it's 2003. Nobody's going to be interested in this ancient DOS stuff!"

Well dammit, **I'm** interested!  I'm sure I'm not the only one.

The original product description for Object Professional can be found [here](https://web.archive.org/web/20000919042436/http://www.turbopower.com/products/opro/).

I owned a copy of Object Professional that I used back in the mid 90's and after chasing down some patch updates, this repository is the result.  At some point, I'll be adding photos and binary images of my original diskettes.

From what I can determine, v1.30 is the last version of Object Professional that was released by TurboPower.

## Building
This port builds with Free Pascal 3.2.2 (`fpc`) on Windows and Linux; no assembler is needed (the .ASM routines were ported to Pascal).  Everything is compiled with `-Mtp -Sg`.

From the SRC directory run `build.cmd` (Windows) or `./build.sh` (Linux; `make` also works).  An optional output directory may be given as an argument; the default is `out\win64` / `out/x86_64-<os>`, with units in `units` and the demo programs in `bin`.  Builds are **64-bit (x86_64) by default**; set `CPU=i386` for a 32-bit build (output `out\win32`). Set the `FPC` environment variable to use a specific compiler. (`MemOpLibrary` is not available in this port.)

The file SRC\OPDEFINE.INC has settings that can be changed in order to affect how Object Professional is built and functions.  It would be worth your time to peruse that file - note that unless you know **why** you're going to change something, you probably should leave it the default.

Features that cannot exist in a 32-bit portable build are stubbed and marked with `{ FPC port: ... }` comments: EMS, XMS, DPMI, TSR/pop-up support and interrupt hooks, direct BIOS data area access, and direct UART/video hardware access.  The TSR demos (SMACS, DESKPOP, PHMAIN/POPHELP, PTIME, PSMAIN, ...) build and run only as normal foreground programs, or print a message that they need MS-DOS TSR facilities.  The old DOS Makefile (SRC\OPRO.MAK) is kept for reference only.
## Documentation

The Object Professional documentation is spread across three volumes:
* Vol. 1 - Screen Management
* Vol. 2 - Data Input/Output
* Vol. 3 - TSRs and More

I've scanned and uploaded the versions (v1.20) of the manuals that I have.  If anyone has a set of the v1.30 manuals, please reach out!

Since the manuals are too large for github, I've uploaded them to the Internet Archive.
[https://archive.org/editxml/object-professional-v-1.20-volume-2-data-input-output](https://archive.org/details/object-professional-v-1.20-volume-2-data-input-output-set)

Hopefully more people than just me will find this repository useful.

 


