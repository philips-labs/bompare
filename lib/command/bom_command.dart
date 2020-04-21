import 'dart:io';

import 'package:bompare/service/bom_service.dart';

import 'abstract_command.dart';

class BomCommand extends AbstractCommand {
  static const command = 'bom';

  BomCommand(BomService service) : super(service);

  @override
  String get name => command;

  @override
  String get description =>
      'Analyze the BOM differences between selected scanners';

  @override
  Future<void> execute() async {
    final file = (argResults[AbstractCommand.option_output] != null)
        ? File(argResults[AbstractCommand.option_output])
        : null;
    final diffOnly = argResults[AbstractCommand.option_diff_only];

    final results =
        await service.compareResults(bomFile: file, diffOnly: diffOnly);
    results.forEach((result) {
      stdout.writeln('BOM according to "${result.name}": '
          '${result.detected} detected, '
          '${result.common} in common, '
          '${result.additional} extra, '
          '${result.missing} missing');
    });
  }
}
