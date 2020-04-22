import 'dart:io';

/// Bill-of-material service layer interface.
abstract class BomService {
  /// Loads a scanner result of [type] from [file].
  Future<void> loadResult(ScannerType type, File file);

  /// Returns bill-of-material summary, and optionally writes the content
  /// to [bomFile] as a full index or [diffOnly].
  Future<List<BomResult>> compareBom({File bomFile, bool diffOnly = false});

  /// Returns licenses summary, and optionally writes the content
  /// to [licensesFile] as a full index or [diffOnly].
  Future<LicenseResult> compareLicenses(
      {File licensesFile, bool diffOnly = false});
}

enum ScannerType { reference, black_duck, white_source }

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
