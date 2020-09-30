/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:io';

import 'package:glob/glob.dart';

/// Bill-of-material service layer interface.
abstract class BomService {
  /// Prints output on console if enabled.
  set verbose(bool enabled);

  /// Loads a license mapping for normalization of license names to SPDX.
  Future<void> loadSpdxMapping(File file);

  /// Loads a scanner result of [type] from [glob].
  Future<void> loadResult(ScannerType type, Glob glob);

  /// Returns bill-of-material summary, and optionally writes the content
  /// to [bomFile] as a full index or [diffOnly].
  Future<List<BomResult>> compareBom({File bomFile, bool diffOnly = false});

  /// Returns licenses summary, and optionally writes the content
  /// to [licensesFile] as a full index or [diffOnly].
  Future<LicenseResult> compareLicenses(
      {File licensesFile, bool diffOnly = false});
}

enum ScannerType {
  reference,
  npm_license_checker,
  jk1,
  maven,
  tern,
  spdx,
  black_duck,
  white_source
}

/// Return value for bill-or-materials comparison.
class BomResult {
  /// Scanner identification
  final String name;

  /// Total items found by scanner
  final int detected;

  /// Agreed by all scanners
  final int common;

  /// Extra found by this scanner
  final int additional;

  /// Missed by this scanner
  final int missing;

  BomResult(this.name, this.detected,
      {int common = 0, int additional = 0, int missing = 0})
      : common = common,
        additional = additional,
        missing = missing;
}

/// Return value for license comparison.
class LicenseResult {
  /// Shared bill-of-materials between scanners
  final int bom;

  /// Agreed by all scanners
  final int common;

  LicenseResult(this.bom, this.common);
}
