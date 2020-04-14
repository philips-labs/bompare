import 'dart:io';

import 'package:bompare/domain/business_exception.dart';

class PersistenceException extends BusinessException {
  PersistenceException(File file, [String message = 'I/O error'])
      : super('$message in $file');
}
