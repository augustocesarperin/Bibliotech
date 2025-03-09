import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/livro_model.dart';
import '../models/transacao_model.dart';

// TODO: Implementar cache para reduzir chamadas de API
// TODO: Migrar para DIO em vez de HTTP para melhor tratamento de erros

class ApiService {
  // Endereço do servidor backend
  final String baseUrl = 'http://10.0.2.2:5000/api'; 
  final _storage = const FlutterSecureStorage();
  
  Future<Map<String, String>> _getHeaders() async {
    var token = await _storage.read(key: 'jwt_token');
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Autenticação
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      var loginData = {
        'username': username,
        'password': password,
      };
      
      var response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: await _getHeaders(),
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await _storage.write(key: 'jwt_token', value: data['access_token']);
        await _storage.write(key: 'user_info', value: jsonEncode(data['user']));
        return data;
      } 
      throw Exception('Falha no login: ${response.body}');
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha no registro: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_info');
  }

  Future<User?> getCurrentUser() async {
    final userInfo = await _storage.read(key: 'user_info');
    if (userInfo != null) {
      return User.fromJson(jsonDecode(userInfo));
    }
    return null;
  }

  // Gerenciamento de livros
  Future<List<Livro>> getLivros({String? status, String? genero, String? secao}) async {
    var queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (genero != null) queryParams['genre'] = genero;
    if (secao != null) queryParams['section'] = secao;

    final uri = Uri.parse('$baseUrl/inventory/books').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        var livrosJson = jsonDecode(response.body) as List;
        return livrosJson.map((json) => Livro.fromJson(json)).toList();
      }
      throw Exception('Falha ao buscar livros: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao carregar livros: $e');
    }
  }

  // FIXME: Melhorar tratamento de erro quando livro não existe
  Future<Livro> getLivro(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/books/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Livro.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao buscar livro: ${response.body}');
    }
  }

  Future<Livro> adicionarLivro(Map<String, dynamic> livroData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/books'),
      headers: await _getHeaders(),
      body: jsonEncode(livroData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Livro.fromJson(data['book']);
    } else {
      throw Exception('Falha ao adicionar livro: ${response.body}');
    }
  }

  Future<Livro> atualizarLivro(Livro livro) async {
    final response = await http.put(
      Uri.parse('$baseUrl/inventory/books/${livro.id}'),
      headers: await _getHeaders(),
      body: jsonEncode(livro.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Livro.fromJson(data['book']);
    } else {
      throw Exception('Falha ao atualizar livro: ${response.body}');
    }
  }

  Future<Livro> venderLivro(int livroId, {String? observacoes}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/books/$livroId/sell'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'notes': observacoes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Livro.fromJson(data['book']);
    } else {
      throw Exception('Falha ao vender livro: ${response.body}');
    }
  }

  // Processamento de imagens
  // TODO: Melhorar tratamento de arquivos grandes
  Future<Map<String, dynamic>> analisarImagemLivro(File imagem, {Map<String, String>? dadosAdicionais}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/images/analyze'),
    );

    final headers = await _getHeaders();
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', imagem.path));
    
    if (dadosAdicionais != null) {
      request.fields.addAll(dadosAdicionais);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Erro: ${response.statusCode}');
    } catch (e) {
      throw Exception('Falha ao analisar imagem: $e');
    }
  }

  Future<List<Transacao>> getTransacoes({int? livroId, String? tipo}) async {
    Map<String, String> queryParams = {};
    if (livroId != null) queryParams['book_id'] = livroId.toString();
    if (tipo != null) queryParams['type'] = Transacao.traduzirParaIngles(tipo);

    final uri = Uri.parse('$baseUrl/inventory/transactions').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> transacoesJson = jsonDecode(response.body);
      return transacoesJson.map((json) => Transacao.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao buscar transações: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getSecoes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/logistics/sections'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao buscar seções: ${response.body}');
    }
  }

  Future<List<Livro>> getLivrosPorSecao(String secaoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/logistics/sections/$secaoId/books'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> livrosJson = jsonDecode(response.body);
      return livrosJson.map((json) => Livro.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao buscar livros da seção: ${response.body}');
    }
  }

  Future<Livro> moverLivro(int livroId, String secaoDestino, {String? observacoes}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logistics/move'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'book_id': livroId,
        'to_section': secaoDestino,
        'notes': observacoes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Livro.fromJson(data['book']);
    } else {
      throw Exception('Falha ao mover livro: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRelatorioInventario({String? status, String? genero, String? secao}) async {
    var queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (genero != null) queryParams['genre'] = genero;
    if (secao != null) queryParams['section'] = secao;

    final uri = Uri.parse('$baseUrl/reports/inventario').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } 
    throw Exception('Falha ao buscar relatório de inventário: ${response.body}');
  }

  Future<Map<String, dynamic>> getRelatorioVendas({String? dataInicio, String? dataFim}) async {
    var params = <String, String>{};
    if (dataInicio != null) params['data_inicio'] = dataInicio;
    if (dataFim != null) params['data_fim'] = dataFim;

    final uri = Uri.parse('$baseUrl/reports/vendas').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao buscar relatório de vendas: ${response.body}');
  }
} 