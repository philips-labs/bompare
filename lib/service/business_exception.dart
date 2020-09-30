/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

class BusinessException implements Exception {
  final String message;

  BusinessException([this.message = '']);

  @override
  String toString() {
    final cause = message.isEmpty ? 'Oops, something went wrong' : message;
    return 'ERROR: $cause';
  }
}
