import '../service/business_exception.dart';

class PersistenceException extends BusinessException {
  PersistenceException(dynamic entity, String message)
      : super('$message for "$entity"');
}
