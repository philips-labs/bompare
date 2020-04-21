import 'dart:io';

/// Bill-of-material service layer interface.
abstract class BomService {
  /// Loads a scanner result of [type] from [file].
  Future<void> loadResult(ScannerType type, File file);

  /// Returns bill-of-material summary, and optionally writes the content
  /// to [bomFile] as a full index or [diffOnly].
  Future<List<BomResult>> compareResults({File bomFile, bool diffOnly = false});
}

enum ScannerType { reference, black_duck, white_source }

class BomResult {
  String name;
  int detected;
  int common;
  int additional;
  int missing;

  BomResult(
      this.name, this.detected, this.common, this.additional, this.missing);
}
