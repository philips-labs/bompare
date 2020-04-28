import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/bom_command.dart';
import 'package:bompare/command/licenses_command.dart';
import 'package:bompare/persistence/parser/blackduck_result_parser.dart';
import 'package:bompare/persistence/parser/jk1_result_parser.dart';
import 'package:bompare/persistence/parser/reference_result_parser.dart';
import 'package:bompare/persistence/parser/wss_inventory_result_parser.dart';
import 'package:bompare/persistence/report_writer.dart';
import 'package:bompare/persistence/scan_result_loader.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/business_exception.dart';
import 'package:bompare/service/domain/bom_interactor.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';

void main(List<String> arguments) async {
  final spdxMapping = SpdxMapper();
  final loader = ScanResultLoader({
    ScannerType.reference: ReferenceResultParser(),
    ScannerType.jk1: Jk1ResultParser(spdxMapping),
    ScannerType.white_source: WhiteSourceInventoryResultParser(spdxMapping),
    ScannerType.black_duck: BlackDuckResultParser(spdxMapping),
  }, spdxMapping);
  final reporter = ReportWriter();
  final service = BomInteractor(loader, reporter);

  try {
    final command = CommandRunner('bompare', 'Bill-Of-Material scan comparator')
      ..addCommand(BomCommand(service))
      ..addCommand(LicensesCommand(service));
    await command.run(arguments);
  } on UsageException catch (error) {
    print(error);
    exitCode = 64;
  } on BusinessException catch (error) {
    print(error);
    exitCode = 1;
  }
}
