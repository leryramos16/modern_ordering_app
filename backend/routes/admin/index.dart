import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

Response onRequest(RequestContext context) {
  final user = context.read<User>(); // provided by requireUser()
  return Response.json(body: {'message': 'Hello admin ${user.name}'});
}
