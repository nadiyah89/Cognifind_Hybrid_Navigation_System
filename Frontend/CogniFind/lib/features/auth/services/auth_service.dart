import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

/// Service responsible for communicating with the .NET authentication API
class AuthService {

  /// Base URL of the backend API
  /// IMPORTANT:
  /// Android Emulator -> use 10.0.2.2 instead of localhost
  static const String baseUrl =  "https://cognifind-backend2.onrender.com/api/Auth";



  /// LOGIN API
  ///
  /// Sends email + password to backend
  /// Returns JSON response containing JWT token and user data
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data["message"] ?? "Login failed");
      }

    } on SocketException {
      throw Exception("Unable to connect to server. Check your internet.");
    } catch (e) {
      throw Exception("Something went wrong. Please try again.");
    }
  }



  /// REGISTER API
  ///
  /// Creates a new user account
  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      ) async {
    try {
      final url = Uri.parse("$baseUrl/register");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data["message"] ?? "Registration failed");
      }

    } on SocketException {
      throw Exception("Unable to connect to server. Check your internet.");
    } catch (e) {
      throw Exception("Something went wrong. Please try again.");
    }
  }
}