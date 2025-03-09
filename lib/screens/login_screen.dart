import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _fazerLogin() {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.fazerLogin(
        _usuarioController.text.trim(),
        _senhaController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo ou ícone
                    Icon(
                      Icons.menu_book_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    // Título
                    Text(
                      'Logística de Livros com IA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Formulário de login
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Campo de usuário
                          TextFormField(
                            controller: _usuarioController,
                            decoration: const InputDecoration(
                              labelText: 'Usuário',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, informe seu usuário';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Campo de senha
                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_mostrarSenha,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarSenha 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _mostrarSenha = !_mostrarSenha;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, informe sua senha';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Mensagem de erro
                          if (authService.erro != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                authService.erro!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // Botão de login
                          ElevatedButton(
                            onPressed: authService.estaCarregando 
                                ? null 
                                : _fazerLogin,
                            child: authService.estaCarregando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text('ENTRAR'),
                          ),
                          const SizedBox(height: 16),
                          // Link para cadastro
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Não tem uma conta? Cadastre-se'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 