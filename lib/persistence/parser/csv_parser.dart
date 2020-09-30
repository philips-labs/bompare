/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

/// Base CSV parser for scanning the rows of columns.
abstract class CsvParser {
  static final _columnQuotes = RegExp(r'(^")|("$)');

  /// Enables scanning of a header row.
  final bool hasHeader;

  CsvParser({this.hasHeader = true});

  /// Converts lines to columns, calling abstract methods for both.
  Future<void> parse(Stream<String> lineStream) async {
    var foundHeaders = false;

    await for (final line in lineStream) {
      if (line.isEmpty) continue;

      const tempComma = '\n';
      final columns = _escapeCommas(line, tempComma)
          .split(',')
          .map((c) => c
              .replaceAll(_columnQuotes, '')
              .replaceAll(tempComma, ',')
              .replaceAll(r'""', '"'))
          .toList();

      if (hasHeader && !foundHeaders) {
        headerRow(columns);
        foundHeaders = true;
      } else {
        dataRow(columns);
      }
    }
  }

  String _escapeCommas(String line, String replacement) {
    if (!line.contains('"')) return line;

    final buf = StringBuffer();
    final comma = ','.codeUnitAt(0);
    final quote = '"'.codeUnitAt(0);
    var inQuotes = false;
    for (var ch in line.codeUnits) {
      if (ch == quote) {
        inQuotes = !inQuotes;
      }

      if (inQuotes && (ch == comma)) {
        buf.write(replacement);
      } else {
        buf.writeCharCode(ch);
      }
    }
    return buf.toString();
  }

  /// Notifies the [columns] in the header of the CSV.
  void headerRow(List<String> columns);

  /// Notifies a single row of [columns] in the CSV.
  void dataRow(List<String> columns);

  /// Returns index of [name] in [columns] or else throws a FormatException.
  int columnIndexOf(String name, List<String> columns) {
    final pos = columns.indexOf(name);
    if (pos < 0) {
      throw FormatException('Header does not defined column "$name"');
    }
    return pos;
  }
}
