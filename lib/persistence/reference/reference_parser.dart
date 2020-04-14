import 'dart:convert';
import 'dart:io';

import 'package:bompare/domain/inventory_item.dart';
import 'package:bompare/persistence/persistence_exception.dart';

class ReferenceParser {
  List<InventoryItem> parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Reference file not found');
    }

    try {
      final str = file.readAsStringSync();

      return (jsonDecode(str) as Iterable)
          .map((obj) => InventoryItem(obj['name'], obj['version']))
          .toList();
    } on FormatException {
      throw PersistenceException(file, 'Unexpected format');
    }
  }
}
