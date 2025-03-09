import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _mostrarSenha = false;
  bool _mostrarConfirmacaoSenha = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _registrar() {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.cadastrarUsuario(
        _usuarioController.text.trim(),
        _emailController.text.trim(),
        _senhaController.text,
      ).then((sucesso) {
        if (sucesso) {
          // Registro bem-sucedido, o login já foi feito automaticamente
          // Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastre-se'),
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campos de formulário
                      TextFormField(
                        controller: _usuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Nome de usuário',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe um nome de usuário';
                          }
                          if (value.length < 3) {
                            return 'O nome de usuário deve ter pelo menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe seu e-mail';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Por favor, informe um e-mail válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                            return 'Por favor, informe uma senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmarSenhaController,
                        obscureText: !_mostrarConfirmacaoSenha,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarConfirmacaoSenha 
                                ? Icons.visibility_off 
                                : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _mostrarConfirmacaoSenha = !_mostrarConfirmacaoSenha;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua senha';
                          }
                          if (value != _senhaController.text) {
                            return 'As senhas não coincidem';
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
                      // Botão de registro
                      ElevatedButton(
                        onPressed: authService.estaCarregando 
                            ? null 
                            : _registrar,
                        child: authService.estaCarregando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('CADASTRAR'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 