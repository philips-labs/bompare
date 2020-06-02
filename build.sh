#!/bin/bash
set -e

# Update or download libraries
pub get

# Analyse code
libs="bin lib test"
dartanalyzer $libs
dartfmt -w $libs

# Calculate coverage by unit tests
pub run test_coverage
if hash genhtml >/dev/null; then
  genhtml -o coverage coverage/lcov.info
  echo "Coverage report is found in /coverage/index.html"
else
  echo "(Install lcov to generate a full coverage overview.)"
fi

# Build command line executable
dart2native bin/bompare.dart -o bompare
