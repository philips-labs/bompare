#!/bin/bash
set -e
dartanalyzer bin test
pub run test
dart2native bin/bompare.dart -o bompare

