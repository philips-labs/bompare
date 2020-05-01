# Bompare, a tool compare a Software Bill-of-Materials

## Usage
The `bompare` tool can be used to compare generated bill-of-materials files
to identify differences between sources. Comparison is either between the 
libraries identified by various sources, or on the licenses for the
libraries identified by all sources in the comparison. Outputs are CSV 
files with a column per source.

It currently reads:

- [x] (Internal) reference format (BOM only)
- [x] [WhiteSource](https://www.whitesourcesoftware.com) inventory JSON export format
- [x] [BlackDuck](https://www.synopsys.com/software-integrity/security-testing/software-composition-analysis.html) report export ZIP and directory format
- [x] [JK1 Gradle license report](https://github.com/jk1/Gradle-License-Report) format
- [x] [Tern](https://github.com/tern-tools/tern) format

To allow license comparison, it automatically transforms official license titles 
to SPDX identifiers, and allows customized translations using an external CSV file.

The executable is a multi-platform command line executable with built-in usage help.
It should compile and run on OSX/Linux/Windows, but has been developed on OSX.

## Building the executable
1. Install Dart 2.7 (or newer) SDK according to the [instructions](https://dart.dev/get-dart).
E.g.:
    - OSX (Mac) using brew: `brew tap dart-lang/dart` and then `brew install dart`
    - Windows using [Chocolatey](https://chocolatey.org): `choco install dart-sdk`
    - With docker ` docker run -it --rm -v $(pwd):/work -w /work google/dart ./build.sh`
2. Run `build.sh` to run all tests and build a native executable
called `bompare`.

