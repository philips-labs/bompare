import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/service/bom_service.dart';

class BomCommand extends Command {
  static const option_reference = 'reference';
  static const command = 'bom';

  final BomService service;

  BomCommand(this.service) {
    argParser.addMultiOption(option_reference,
        abbr: 'r',
        help: 'Scan result in "reference" (JSON) format',
        valueHelp: 'filename');
  }

  @override
  String get name => command;

  @override
  String get description =>
      'Analyze the BOM differences between selected scanners';

  @override
  void run() {
    argResults[option_reference].forEach((filename) =>
        service.loadResult(ScannerType.reference, File(filename)));

    service.compareResults().forEach((result) {
      stdout.writeln('BOM according to "${result.name}": '
          '${result.common} in common, '
          '${result.additional} extra, '
          '${result.missing} missing');
    });
  }
}
