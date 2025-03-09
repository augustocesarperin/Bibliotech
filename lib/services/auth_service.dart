import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService;
  User? _usuarioAtual;
  bool _carregando = false;
  String? _erro;

  AuthService(this._apiService) {
    _inicializar();
  }

  // Getters
  User? get usuarioAtual => _usuarioAtual;
  bool get estaAutenticado => _usuarioAtual != null;
  bool get estaCarregando => _carregando;
  String? get erro => _erro;
  bool get ehAdmin => _usuarioAtual?.isAdmin() ?? false;

  Future<void> _inicializar() async {
    _setLoading(true);

    try {
      _usuarioAtual = await _apiService.getCurrentUser();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _carregando = loading;
    notifyListeners();
  }

  // Login
  Future<bool> fazerLogin(String username, String password) async {
    _setLoading(true);
    _erro = null;

    try {
      var resposta = await _apiService.login(username, password);
      _usuarioAtual = User.fromJson(resposta['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _erro = 'Falha no login: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cadastro
  Future<bool> cadastrarUsuario(String username, String email, String password) async {
    _setLoading(true);
    _erro = null;

    try {
      await _apiService.register(username, email, password);
      // Após o cadastro, faz o login automaticamente
      return await fazerLogin(username, password);
    } catch (e) {
      _erro = 'Falha no cadastro: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> fazerLogout() async {
    _setLoading(true);

    try {
      await _apiService.logout();
      _usuarioAtual = null;
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Limpar mensagens de erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }
} 