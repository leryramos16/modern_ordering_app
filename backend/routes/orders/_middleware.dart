import 'package:backend/auth/auth_middleware.dart';
import 'package:dart_frog/dart_frog.dart';

/// Every route in routes/orders/ requires a logged-in user (any role).
Handler middleware(Handler handler) => handler.use(requireUser());
