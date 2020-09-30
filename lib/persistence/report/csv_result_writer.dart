/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';

/// CSV report output.
class CsvResultWriter {
  static StreamTransformer<List<String>, String> csvTransformer =
      StreamTransformer.fromHandlers(handleData: (line, sink) {
    sink.add(line
        .map((str) => str?.replaceAll('"', r'""') ?? '')
        .map((str) => '"$str"')
        .join(','));
    sink.add('\r\n');
  });

  final File file;
  final Iterable<ScanResult> scans;

  CsvResultWriter(this.file, this.scans);

  /// Writes a bill-of-materials based on the provided [ids].
  Future<void> writeBomComparison(Set<ItemId> ids) =>
      _writeCsvFile(_bomHeadline(), ids, _toBomLine);

  /// Writes a licenses overview based on the provided [ids].
  Future<void> writeLicensesComparison(Set<ItemId> ids) =>
      _writeCsvFile(_bomHeadline(), ids, _toLicenseLine);

  Future<void> _writeCsvFile(List<String> headLine, Set<ItemId> ids,
      List<String> Function(ItemId id) formatter) async {
    final list = ids.toList()..sort((l, r) => l.compareTo(r));

    IOSink sink;
    try {
      sink = file.openWrite();
      await sink.addStream(Stream.value(headLine)
          .transform<String>(csvTransformer)
          .transform(utf8.encoder));
      await sink.addStream(Stream.fromIterable(list.map(formatter))
          .transform<String>(csvTransformer)
          .transform(utf8.encoder));
    } on FileSystemException {
      throw PersistenceException(file, 'can not write to file');
    }
  }

  List<String> _bomHeadline() =>
      ['package', 'version', for (final s in scans) s.name];

  List<String> _toBomLine(ItemId id) => [
        id.package,
        id.version,
        for (final s in scans) (s[id] != null) ? 'yes' : '',
      ];

  List<String> _toLicenseLine(ItemId id) {
    final licenses = scans.map((s) {
      return s[id]?.licenses?.join(' OR ') ?? '';
    }).toList();

    return <String>[
      id.package,
      id.version,
      for (final lic in licenses) lic,
    ];
  }
}
