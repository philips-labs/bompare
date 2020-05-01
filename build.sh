#!/bin/bash
set -e
pub get
dartanalyzer bin lib test
pub run test
dart2native bin/bompare.dart -o bompare
