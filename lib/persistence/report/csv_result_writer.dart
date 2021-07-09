/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../service/domain/bom_item.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';

/// CSV report output.
class CsvResultWriter {
  static StreamTransformer<List<String>, String> csvTransformer =
      StreamTransformer.fromHandlers(handleData: (line, sink) {
    sink.add(line
        .map((str) => str.replaceAll('"', r'""'))
        .map((str) => '"$str"')
        .join(','));
    sink.add('\r\n');
  });

  final File file;
  final Iterable<ScanResult> scans;

  CsvResultWriter(this.file, this.scans);

  /// Writes a bill-of-materials based on the provided [items].
  Future<void> writeBomComparison(Iterable<BomItem> items) =>
      _writeCsvFile(_bomHeadline(), items, _toBomLine);

  /// Writes a licenses overview based on the provided [items].
  Future<void> writeLicensesComparison(Iterable<BomItem> items) =>
      _writeCsvFile(_bomHeadline(), items, _toLicenseLine);

  Future<void> _writeCsvFile(List<String> headLine, Iterable<BomItem> items,
      List<String> Function(BomItem item) formatter) async {
    final list = items.toList()..sort((l, r) => l.compareTo(r));

    IOSink sink;
    try {
      sink = file.openWrite();
      await sink.addStream(Stream<List<String>>.value(headLine)
          .transform<String>(csvTransformer)
          .transform(utf8.encoder));
      await sink.addStream(
          Stream<List<String>>.fromIterable(list.map(formatter))
              .transform<String>(csvTransformer)
              .transform(utf8.encoder));
    } on FileSystemException {
      throw PersistenceException(file, 'can not write to file');
    }
  }

  List<String> _bomHeadline() => ['package', for (final s in scans) s.name];

  List<String> _toBomLine(BomItem item) => [
        item.purl.toString(),
        for (final s in scans) (s[item] != null) ? 'yes' : '',
      ];

  List<String> _toLicenseLine(BomItem item) {
    final licenses = scans.map((s) {
      return s[item]?.licenses.join(' OR ') ?? '';
    }).toList();

    return <String>[
      item.purl.toString(),
      for (final lic in licenses) lic,
    ];
  }
}
