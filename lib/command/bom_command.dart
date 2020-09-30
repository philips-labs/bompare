/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import '../service/bom_service.dart';
import 'abstract_command.dart';

/// Bill-of-Materials comparison command.
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
    final results = await service.compareBom(bomFile: file, diffOnly: diffOnly);
    results.forEach((result) {
      print('BOM according to "${result.name}": '
          '${result.detected} detected, '
          '${result.common} in common, '
          '${result.additional} extra, '
          '${result.missing} missing');
    });
  }
}
