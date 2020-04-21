import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';

/// CSV report output.
class CsvResultWriter {
  static StreamTransformer<List<dynamic>, String> csvTransformer =
      StreamTransformer.fromHandlers(handleData: (line, sink) {
    sink.add(line
        .map((obj) => obj.toString().replaceAll('"', r'\"'))
        .map((obj) => '"$obj"')
        .join(','));
    sink.add('\r\n');
  });

  final File file;
  final List<ScanResult> scans;

  CsvResultWriter(this.file, this.scans);

  /// Writes a bill-of-materials based on the provided [ids].
  Future<void> writeBomComparison(Iterable<ItemId> ids) async {
    final list = ids.toList()..sort((l, r) => l.compareTo(r));

    try {
      final out = file.openWrite();
      await out.addStream(Stream.value(_bomHeadline())
          .transform<String>(csvTransformer)
          .transform(utf8.encoder));
      await out.addStream(Stream.fromIterable(list)
          .map(_toBomLine)
          .transform<String>(csvTransformer)
          .transform(utf8.encoder));
    } on FileSystemException {
      throw PersistenceException(file, 'can not write to file');
    }
  }

  List<dynamic> _bomHeadline() =>
      ['package', 'version', for (final s in scans) s.name];

  List<dynamic> _toBomLine(ItemId id) => [
        id.package,
        id.version,
        for (final s in scans) s.items.contains(id) ? 'yes' : '',
      ];
}
