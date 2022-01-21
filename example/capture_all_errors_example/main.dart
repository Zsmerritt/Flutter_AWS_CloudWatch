// import 'dart:async';
// import 'app.dart';
//
// import 'errorLog.dart';
//
// void main() {
//   runZonedGuarded<Future<void>>(() async {
//     final Function originalOnError = FlutterError.onError;
//     FlutterError.onError = (FlutterErrorDetails errorDetails) async {
//       Zone.current
//           .handleUncaughtError(errorDetails.exception, errorDetails.stack);
//       originalOnError(errorDetails);
//     };
//     runApp(MyApp());
//   }, (dynamic error, stackTrace) async {
//     logFlutterSystemError(error, stackTrace);
//     print(error.toString());
//     throw error;
//   });
// }