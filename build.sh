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
dart run test test --coverage coverage

if hash format_coverage >/dev/null && hash genhtml >/dev/null; then
  format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib
  genhtml -o coverage coverage/lcov.info
  echo "Coverage report is found in /coverage/index.html"

  if hash flutter_coverage_badge >/dev/null; then
    flutter_coverage_badge
    echo "Coverage badge generated."
  else
    echo "(Install dart package:flutter_coverage_badge globally to generate coverage badge.)"
  fi
else
  echo "(Install dart package:coverage globally and genhtml to generate a full coverage overview.)"
fi

# Build command line executable
dart compile exe bin/bompare.dart -o bompare
