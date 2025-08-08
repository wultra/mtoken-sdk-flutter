import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/src/core/logger.dart';

void main() {

  group("logTests", () {
    test('testListener', () {

      final listener = _TestListener();

      // Start listening with verbosity following

      listener.startListening(true);
      WMTLogger.verbosity = WMTLoggerVerbosity.none;
      Log.debug("Debug message");
      expect(listener.lastMessage, isNull);
      expect(listener.lastVerbosity, isNull);

      WMTLogger.verbosity = WMTLoggerVerbosity.debug;
      Log.debug("Debug message");
      expect(listener.lastMessage, "Debug message");
      expect(listener.lastVerbosity, WMTLoggerVerbosity.debug);

      WMTLogger.verbosity = WMTLoggerVerbosity.info;
      Log.debug("Debug message");
      expect(listener.lastMessage, isNull);
      expect(listener.lastVerbosity, isNull);

      WMTLogger.verbosity = WMTLoggerVerbosity.info;
      Log.info("Info message");
      expect(listener.lastMessage, "Info message");
      expect(listener.lastVerbosity, WMTLoggerVerbosity.info);

      Log.error("Error message");
      expect(listener.lastMessage, "Error message");
      expect(listener.lastVerbosity, WMTLoggerVerbosity.error);

      Log.debug("Debug message");
      expect(listener.lastMessage, isNull);
      expect(listener.lastVerbosity, isNull);

      // Stop listening
      listener.stopListening();

      // Start listening with verbosity not following
      listener.startListening(false);
      WMTLogger.verbosity = WMTLoggerVerbosity.none;
      Log.info("Info message");
      expect(listener.lastMessage, "Info message");
      expect(listener.lastVerbosity, WMTLoggerVerbosity.info);

      // Stop listening
      listener.stopListening();
      WMTLogger.verbosity = WMTLoggerVerbosity.none;
      Log.info("Info message");
      expect(listener.lastMessage, isNull);
      expect(listener.lastVerbosity, isNull);
    });
  });
}


class _TestListener {
  
  String? _lastMessage;
  WMTLoggerVerbosity? _lastVerbosity;

  String? get lastMessage { 
    final message = _lastMessage;
    _lastMessage = null; // Clear after reading
    return message;
  }
  WMTLoggerVerbosity? get lastVerbosity {
    final verbosity = _lastVerbosity;
    _lastVerbosity = null; // Clear after reading
    return verbosity;
  }

  void startListening(bool followVerbosity) {
    WMTLogger.setLogListener(
      listener: (message, verbosity) {
        _lastMessage = message;
        _lastVerbosity = verbosity;
      },
      followVerbosity: followVerbosity,
    );
  }

  void stopListening() {
    WMTLogger.setLogListener(listener: null);
  }
}
