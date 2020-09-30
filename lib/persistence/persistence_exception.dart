/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import '../service/business_exception.dart';

class PersistenceException extends BusinessException {
  PersistenceException(dynamic entity, String message)
      : super('$message for "$entity"');
}
