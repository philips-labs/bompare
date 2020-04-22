import 'dart:io';

import '../service/bom_service.dart';
import 'abstract_command.dart';

class LicensesCommand extends AbstractCommand {
  static const command = 'licenses';

  LicensesCommand(BomService service) : super(service);

  @override
  String get name => command;

  @override
  String get description =>
      'Analyze the detected license differences between selected scanners';

  @override
  Future<void> execute() async {
    final result =
        await service.compareLicenses(licensesFile: file, diffOnly: diffOnly);
    stdout.writeln('Shared BOM size: ${result.bom}');
    stdout.writeln('Matching licenses: ${result.common}');
    stdout.writeln('Different licenses: ${result.bom - result.common}');
  }
}
