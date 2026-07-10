import 'package:dio/dio.dart';

import '../models/signup_response.dart';
import '../exceptions/auth_exceptions.dart';
import '../utils/api_constants.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.timeout,
        receiveTimeout: ApiConstants.timeout,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  Future<SignUpResponse> registerUser({
    required String name,
    required String email,
    required String cpf,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {"name": name, "email": email, "cpf": cpf, "password": password},
      );

      return SignUpResponse.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 400:
          throw const ValidationException("Dados inválidos");

        case 409:
          throw const EmailAlreadyExistsException("Email já cadastrado");
      }

      if (e.type == DioExceptionType.connectionTimeout) {
        throw const ApiTimeoutException("Tempo de conexão esgotado");
      }

      throw ServerException(e.message ?? "Erro interno");
    }
  }
}
