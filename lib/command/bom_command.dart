import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/service/bom_service.dart';

class BomCommand extends Command {
  static const option_reference = 'reference';
  static const option_white_source = 'whitesource';
  static const option_output = 'out';
  static const option_diff_only = 'diffOnly';
  static const command = 'bom';

  final BomService service;

  BomCommand(this.service) {
    argParser
      ..addMultiOption(option_reference,
          abbr: 'r',
          help: 'Scan result in "reference" (JSON) format',
          valueHelp: 'filename')
      ..addMultiOption(option_white_source,
          abbr: 'w',
          help: 'Scan result in WhiteSource "inventory" (JSON) format',
          valueHelp: 'filename')
      ..addOption(option_output,
          abbr: 'o',
          help: 'Write detail report to (CSV) file',
          valueHelp: 'filename')
      ..addFlag(option_diff_only,
          help: 'Only output diff lines in output file');
  }

  @override
  String get name => command;

  @override
  String get description =>
      'Analyze the BOM differences between selected scanners';

  @override
  void run() {
    _loadTypedResults(option_reference, ScannerType.reference);
    _loadTypedResults(option_white_source, ScannerType.white_source);

    final file = (argResults[option_output] != null)
        ? File(argResults[option_output])
        : null;
    final diffOnly = argResults[option_diff_only];

    service.compareResults(bomFile: file, diffOnly: diffOnly).forEach((result) {
      stdout.writeln('BOM according to "${result.name}": '
          '${result.common} in common, '
          '${result.additional} extra, '
          '${result.missing} missing');
    });
  }

  void _loadTypedResults(String option, ScannerType type) {
    argResults[option]
        .forEach((filename) => service.loadResult(type, File(filename)));
  }
}
