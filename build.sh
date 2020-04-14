#!/bin/bash
set -e
dartanalyzer bin lib test
pub run test
dart2native bin/bompare.dart -o bompare

