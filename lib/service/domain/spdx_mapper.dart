import '../business_exception.dart';
import 'spdx_licenses.dart' as spdx;

/// Dictionary to map license names to SPDX identifiers.
class SpdxMapper {
  final _mapping = <String, String>{};

  SpdxMapper() {
    spdx.dictionary.forEach((key, value) {
      _mapping[key.toLowerCase()] = value;
      _mapping[value.toLowerCase()] = value;
    });
  }

  /// Maps the [key] to an SPDX identifier.
  String operator [](String key) => _mapping[key.toLowerCase()] ?? '"$key"';

  /// Adds a new mapping from [key] to an SPDX identifier.
  void operator []=(String key, String value) {
    if (!_mapping.values.contains(value)) {
      throw BusinessException('"$value" is not a valid SPDX identifier');
    }
    _mapping[key.toLowerCase()] = value;
  }
}
