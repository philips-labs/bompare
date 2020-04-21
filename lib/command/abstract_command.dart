import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/domain/bom_interactor.dart';

/// Base command to act upon provided scan result files.
abstract class AbstractCommand extends Command {
  static const option_reference = 'reference';
  static const option_white_source = 'whitesource';
  static const option_black_duck = 'blackduck';
  static const option_output = 'out';
  static const option_diff_only = 'diffOnly';

  final BomInteractor service;

  AbstractCommand(this.service) {
    argParser
      ..addMultiOption(option_reference,
          abbr: 'r',
          help: 'Scan result in "reference" (JSON) format',
          valueHelp: 'filename')
      ..addMultiOption(option_white_source,
          abbr: 'w',
          help: 'Scan result in WhiteSource "inventory" (JSON) format',
          valueHelp: 'filename')
      ..addMultiOption(option_black_duck,
          abbr: 'b',
          help: 'Scan result in Black Duck "report" (ZIP/directory) format',
          valueHelp: 'filename or directory')
      ..addOption(option_output,
          abbr: 'o',
          help: 'Write detail report to (CSV) file',
          valueHelp: 'filename')
      ..addFlag(option_diff_only,
          help: 'Only output diff lines in output file');
  }

  @override
  Future<void> run() async {
    await _loadScanResults();

    return execute();
  }

  Future<void> _loadScanResults() async => await Future.wait([
        _loadTypedResults(option_reference, ScannerType.reference),
        _loadTypedResults(option_white_source, ScannerType.white_source),
        _loadTypedResults(option_black_duck, ScannerType.black_duck),
      ]);

  Future<void> _loadTypedResults(String option, ScannerType type) =>
      Future.forEach(argResults[option],
          (filename) => service.loadResult(type, File(filename)));

  Future<void> execute();
}
