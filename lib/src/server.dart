import 'dart:async';

import 'package:alfred/alfred.dart';
import 'package:backend/src/clock_in_out/clock_in_out.dart';
import 'package:backend/src/invite/send_invite/send_invite.dart';
import 'package:backend/src/organization/organization.dart';
import 'package:backend/src/user/user.dart';
import 'package:backend/src/validators/validators.dart';

class Server {
  const Server();

  Future<void> init() async {
    // initialize alfred:
    final app = Alfred(
      onNotFound: (req, res) => throw AlfredException(
        404,
        {'message': '${req.requestedUri.path} not found'},
      ),
      onInternalError: errorHandler,
    )
      ..post(
        'user/register',
        const UserRegisterController(),
        middleware: [const UserRegisterMiddleware()],
      )
      ..put(
        'user/update',
        const UserUpdateController(),
        middleware: [const UserUpdateMiddleware()],
      )
      ..post(
        'user/login',
        const UserLoginController(),
        middleware: [
          const UserLoginMiddleware(),
        ],
      )
      ..get(
        'user',
        const UserCurrentController(),
        middleware: [
          const AuthenticationMiddleware(),
        ],
      )
      ..post(
        'organization',
        const CreateOrganizationController(),
        middleware: [const CreateOrganizationMiddleware()],
      )
      ..put(
        'organization/:id:[0-9a-z]+',
        const UpdateOrganizationController(),
        middleware: [const UpdateOrganizationMiddleware()],
      )
      ..post(
        'organization/join/:refId:uuid',
        const JoinOrganizationController(),
        middleware: [const JoinOrganizationMiddleware()],
      )
      ..delete(
        'user/logout',
        const UserLogoutController(),
        middleware: [const AuthenticationMiddleware()],
      )
      ..post(
        'clock/in/:id:[0-9a-z]+',
        const ClockInController(),
        middleware: [const ClockInMiddleware()],
      )
      ..post(
        'clock/out/:id:[0-9a-z]+',
        const ClockOutController(),
        middleware: [const ClockOutMiddleware()],
      )
      ..post(
        'invite/send/',
        const InviteCreateController(),
        middleware: [const InviteCreateMiddleware()],
      )
      ..printRoutes()
      ..registerOnDoneListener(errorPluginOnDoneHandler);

    // start the alfred server:
    await app.listen(8080);
  }
}

FutureOr<dynamic> errorHandler(HttpRequest req, HttpResponse res) {
  res.statusCode = 500;
  return {'message': 'error not handled'};
}
