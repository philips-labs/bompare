/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:io';

import 'package:glob/glob.dart';

import 'bom_service.dart';
import 'domain/scan_result.dart';

abstract class ResultPersistence {
  /// Returns the key-value mapping stored in [file].
  Future<void> loadMapping(File file);

  /// Returns the [type] scanning result for the [glob].
  Future<ScanResult> load(ScannerType type, Glob glob);
}
