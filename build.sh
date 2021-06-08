#!/bin/bash
set -e

# Update or download libraries
dart pub get

# Analyse code
dart analyze "bin"
dart analyze "lib"
dart analyze "test"
dart format "bin" "lib" "test"

# Calculate coverage by unit tests
dart run test test/ --coverage coverage
if hash genhtml >/dev/null; then
  genhtml -o coverage coverage/lcov.info
  echo "Coverage report is found in /coverage/index.html"
else
  echo "(Install lcov to generate a full coverage overview.)"
fi

# Build command line executable
dart compile exe bin/bompare.dart -o bompare
