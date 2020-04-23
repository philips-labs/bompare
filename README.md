# Bompare, a tool compare a Software Bill-of-Materials

## Usage
The `bompare` tool can be used to compare the generated bill-of-materials
and license outputs to identify differences.

It currently supports:

- [x] (Internal) reference format (BOM only)
- [x] WhiteSource inventory JSON export format
- [x] BlackDuck report export ZIP and directory format
- [ ] Tern format

It automatically transforms Black Duck license names to SPDX identifiers, and
allows the use of an external CSV file to do the same to WhiteSource license names.

The executable is a multi-platform command line executable with built-in usage help.
It should compile and run on OSX/Linux/Windows, but has been developed on OSX.

## Building the executable
1. Install Dart 2.7 (or newer) SDK according to the [instructions](https://dart.dev/get-dart).
E.g.:
    - OSX (Mac) using brew: `brew tap dart-lang/dart` and then `brew install dart`
    - Windows using [Chocolatey](https://chocolatey.org): `choco install dart-sdk`
2. Run `build.sh` to run all tests and build a native executable
called `bompare`.

