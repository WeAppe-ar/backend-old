part of 'login.dart';

class UserLoginController {
  const UserLoginController();

  Future<dynamic> call(HttpRequest req, HttpResponse res) async {
    final email = req.store.get<String>('email');
    final password = req.store.get<String>('password');

    final user = await services.users.findUserByEmail(
      email: email,
    );

    if (user == null || user.password.isEmpty) {
      throw AlfredException(401, {
        'message': 'combination of email and password is invalid',
      });
    }

    try {
      final isCorrect = DBCrypt().checkpw(
        password,
        user.password,
      );

      if (isCorrect == false) {
        throw AlfredException(401, {
          'message': 'Invalid password',
        });
      }

      final jwt = JWT(
        {'userId': user.id?.$oid},
        issuer: 'https://weappe.ar',
      );

      final accessToken = jwt.sign(
        services.jwtAccessSigner,
        expiresIn: const Duration(days: 7),
      );

      final refreshToken = jwt.sign(
        services.jwtRefreshSigner,
        expiresIn: const Duration(days: 90),
      );

      // save the refresh token in the database:
      await services.tokens.addToDatabase(user.id, refreshToken);

      return {
        'user': user.toJson(showPassword: false),
        'refreshToken': refreshToken,
        'accessToken': accessToken,
      };
    } catch (e) {
      throw AlfredException(500, {
        'message': 'an unknown error occurred',
      });
    }
  }
}
