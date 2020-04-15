# Bompare, a tool compare a Software Bill-of-Materials

## Usage
The `bompare` tool can be used to compare the generated bill-of-materials
outputs to identify differences.

It currently supports:

- [x] (Internal) reference format
- [x] WhiteSource inventory JSON export format
- [ ] BlackDuck report export format
- [ ] Tern format

## Building
1. Install Dart 2.7 (or newer) SDK according to the instructions on 
https://dart.dev/get-dart.
2. Run `build.sh` to run all tests and build a native executable
called `bompare`.

