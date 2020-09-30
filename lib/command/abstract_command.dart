/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';

import '../service/bom_service.dart';

/// Base command to act upon provided scan result files.
abstract class AbstractCommand extends Command {
  static const option_reference = 'reference';
  static const option_npm_license_checker = 'npm';
  static const option_jk1 = 'jk1';
  static const option_maven = 'maven';
  static const option_tern = 'tern';
  static const option_spdx = 'spdx-tag-value';
  static const option_white_source = 'whitesource';
  static const option_black_duck = 'blackduck';
  static const option_output = 'out';
  static const option_diff_only = 'diffOnly';
  static const option_verbose = 'verbose';
  static const option_spdx_mapping = 'spdx';
  static const glob_help = 'file glob pattern';

  final BomService service;

  AbstractCommand(this.service) {
    argParser
      ..addMultiOption(option_reference,
          abbr: 'r',
          help: 'Scan result in "reference" (JSON) format',
          valueHelp: 'filename')
      ..addMultiOption(option_npm_license_checker,
          help: 'Scan result in NPM license-checker (CSV) format',
          valueHelp: 'filename')
      ..addMultiOption(option_jk1,
          help: 'Scan result in JK1 (JSON) format', valueHelp: glob_help)
      ..addMultiOption(option_maven,
          help: 'Scan result in Maven license (txt) format',
          valueHelp: 'filename')
      ..addMultiOption(option_tern,
          help: 'Scan result in Tern (JSON) format', valueHelp: glob_help)
      ..addMultiOption(option_spdx,
          abbr: 'x',
          help: 'Scan result in SPDX (tag-value) format',
          valueHelp: glob_help)
      ..addMultiOption(option_white_source,
          abbr: 'w',
          help: 'Scan result in WhiteSource "inventory" (JSON) format',
          valueHelp: glob_help)
      ..addMultiOption(option_black_duck,
          abbr: 'b',
          help: 'Scan result in Black Duck "report" (ZIP/directory) format',
          valueHelp: 'filename or directory glob pattern')
      ..addOption(option_spdx_mapping,
          help: 'Convert license texts using SPDX mapping CSV file, '
              'formatted as: "<license text>","<SPDX identifier>"',
          valueHelp: 'filename')
      ..addOption(option_output,
          abbr: 'o',
          help: 'Write detail report to (CSV) file',
          valueHelp: 'filename')
      ..addFlag(option_diff_only, help: 'Only output diff lines in output file')
      ..addFlag(option_verbose, abbr: 'v', help: 'Verbose output');
  }

  @override
  bool get takesArguments => false;

  /// Returns the file indicated by the [option_output] parameter.
  File get file => (argResults[AbstractCommand.option_output] != null)
      ? File(argResults[AbstractCommand.option_output])
      : null;

  /// Returns the state of the [option_diff_only] parameter.
  bool get diffOnly => argResults[AbstractCommand.option_diff_only];

  @override
  Future<void> run() async {
    if (argResults[option_verbose]) service.verbose = true;

    await _loadScanResults();

    return execute();
  }

  Future<void> _loadScanResults() async {
    final spdxMapping = argResults[option_spdx_mapping];
    if (spdxMapping != null) {
      await service.loadSpdxMapping(File(spdxMapping));
    }

    await Future.wait([
      _loadTypedResults(option_reference, ScannerType.reference),
      _loadTypedResults(
          option_npm_license_checker, ScannerType.npm_license_checker),
      _loadTypedResults(option_jk1, ScannerType.jk1),
      _loadTypedResults(option_maven, ScannerType.maven),
      _loadTypedResults(option_tern, ScannerType.tern),
      _loadTypedResults(option_spdx, ScannerType.spdx),
      _loadTypedResults(option_white_source, ScannerType.white_source),
      _loadTypedResults(option_black_duck, ScannerType.black_duck),
    ]);
  }

  Future<void> _loadTypedResults(String option, ScannerType type) =>
      Future.forEach(
          argResults[option], (glob) => service.loadResult(type, Glob(glob)));

  Future<void> execute();
}
