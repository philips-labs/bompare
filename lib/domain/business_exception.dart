class BusinessException implements Exception {
  final String message;

  BusinessException([this.message = '']);

  @override
  String toString() {
    final cause = message.isEmpty ? 'Oops, something went wrong' : message;
    return 'ERROR: $cause';
  }
}
