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
dart run test --coverage coverage

if type format_coverage && type genhtml &> /dev/null ; then
  dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib
  genhtml -o coverage coverage/lcov.info
  echo "Coverage report is found in ./coverage/index.html"
else
  echo "(Install dart package:coverage globally and lcov (genhtml) to generate a full coverage overview.)"
fi

# Build command line executable
dart compile exe bin/bompare.dart -o bompare
