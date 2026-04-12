import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/organization.dart';
import '../utils/constants.dart';

class OrganizationService {
  // Aqui geteamos las organizaciones del backend
  Future<List<Organization>> getOrganizations() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/organizaciones'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((json) => Organization.fromJson(json)).toList();
      } else {
        throw Exception('Error al conectar con el backend: ${response.statusCode}');
      }
    } catch (e) {

      throw Exception('No se pudo conectar al backend. ¿Está corriendo en el puerto 1337? Error: $e');
    }
  }
}
