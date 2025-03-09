import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'livros_screen.dart';
import 'analise_livro_screen.dart';
// Removendo importações que causam erros
// import 'camera_screen.dart';
// import 'relatorios_screen.dart';
// import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceAtual = 0;
  late List<Widget> _telas;
  
  @override
  void initState() {
    super.initState();
    _telas = [
      const LivrosScreen(),
      const Placeholder(), // Placeholder para a tela da câmera
      const RelatoriosScreen(),
      const PerfilScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final ehAdmin = authService.ehAdmin;
    
    return Scaffold(
      body: Stack(
        children: [
          _telas[_indiceAtual],
          if (_indiceAtual == 0) // Mostrar botão destacado apenas na tela de livros
            Positioned(
              right: 24,
              bottom: 80,
              child: FloatingActionButton(
                heroTag: 'camBtn',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnaliseLivroScreen(),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.camera_alt, size: 28),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (indice) {
          if (indice == 1) {
            // Abrir diretamente a tela de análise de livro em vez de mudar o índice
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnaliseLivroScreen(),
              ),
            );
          } else {
            setState(() {
              _indiceAtual = indice;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Livros',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scanner',
          ),
          if (ehAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Relatórios',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// Implementações temporárias para as telas que ainda não foram criadas
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Livro'),
      ),
      body: const Center(
        child: Text('Tela da Câmera - Implementação em andamento'),
      ),
    );
  }
}

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: const Center(
        child: Text('Tela de Relatórios - Em desenvolvimento'),
      ),
    );
  }
}

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              authService.fazerLogout();
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            if (authService.usuarioAtual != null) ...[
              Text(
                authService.usuarioAtual!.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authService.usuarioAtual!.email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Função: ${authService.usuarioAtual!.role == 'admin' ? 'Administrador' : 'Funcionário'}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                authService.fazerLogout();
              },
              child: const Text('SAIR'),
            ),
          ],
        ),
      ),
    );
  }
} 