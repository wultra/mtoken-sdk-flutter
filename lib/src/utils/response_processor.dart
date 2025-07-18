
import '../core/logger.dart';

typedef Resolver<T> = T Function();

T processResponse<T>(String text, Resolver<T> resolver) {
  try {
    return resolver();
  } catch (e) {
    throw WMTLogger.errorAndException("Failed to deserialize ${text}", additionalData: e);
  }
}