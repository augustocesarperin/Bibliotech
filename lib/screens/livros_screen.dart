import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/livro_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'detalhes_livro_screen.dart';
import 'adicionar_livro_screen.dart';
import 'analise_livro_screen.dart';

class LivrosScreen extends StatefulWidget {
  const LivrosScreen({super.key});

  @override
  State<LivrosScreen> createState() => _LivrosScreenState();
}

class _LivrosScreenState extends State<LivrosScreen> {
  var _livros = <Livro>[];
  var _livrosFiltrados = <Livro>[];
  var _isLoading = true;
  String? _erro;
  var _termoBusca = '';
  final _buscaController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _carregarLivros();
  }
  
  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }
  
  void _filtrarLivros() {
    if (_termoBusca.isEmpty) {
      setState(() => _livrosFiltrados = List.from(_livros));
      return;
    }
    
    final termo = _termoBusca.toLowerCase();
    setState(() {
      _livrosFiltrados = _livros.where((l) => 
        l.title.toLowerCase().contains(termo) ||
        l.author.toLowerCase().contains(termo) ||
        (l.genre?.toLowerCase().contains(termo) ?? false) ||
        (l.description?.toLowerCase().contains(termo) ?? false)
      ).toList();
    });
  }
  
  Future<void> _carregarLivros() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final novaLista = await api.getLivros();
      
      if (!mounted) return;
      
      setState(() {
        _livros = novaLista;
        _livrosFiltrados = List.from(novaLista);
        _isLoading = false;
      });
      
      if (_termoBusca.isNotEmpty) _filtrarLivros();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _erro = 'Erro ao carregar livros: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final ehAdmin = auth.ehAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Livros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarLivros,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: 'Buscar livros...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() {
                            _termoBusca = '';
                          });
                          _filtrarLivros();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _termoBusca = value;
                });
                _filtrarLivros();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _livrosFiltrados.isEmpty
                ? const Center(child: Text('Nenhum livro encontrado'))
                : ListView.builder(
                    itemCount: _livrosFiltrados.length,
                    itemBuilder: (context, index) {
                      final livro = _livrosFiltrados[index];
                      return _buildLivroCard(livro);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (ehAdmin)
            FloatingActionButton(
              heroTag: 'camBtn',
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnaliseLivroScreen(),
                  ),
                );
                
                if (resultado == true) {
                  _carregarLivros();
                }
              },
              tooltip: 'Escanear livro',
              child: const Icon(Icons.camera_alt),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'addBtn',
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdicionarLivroScreen(),
                ),
              );
              
              if (resultado == true) {
                _carregarLivros();
              }
            },
            tooltip: 'Adicionar livro',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLivroCard(Livro livro) {
    final corStatus = _getCorStatus(livro.status);
    final iconStatus = _getIconStatus(livro.status);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: corStatus.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            iconStatus,
            color: corStatus,
            size: 24,
          ),
        ),
        title: Text(
          livro.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${livro.author}${livro.genre != null ? ' • ${livro.genre}' : ''}',
        ),
        trailing: Text(
          livro.getStatusText(),
          style: TextStyle(
            color: _getCorStatus(livro.status),
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesLivroScreen(livro: livro),
            ),
          ).then((atualizado) {
            if (atualizado == true) {
              _carregarLivros();
            }
          });
        },
      ),
    );
  }
  
  Color _getCorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'disponível':
      case 'disponivel':
        return Colors.green;
      case 'vendido':
        return Colors.blue;
      case 'reservado':
        return Colors.orange;
      case 'indisponível':
      case 'indisponivel':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getIconStatus(String status) {
    switch (status.toLowerCase()) {
      case 'disponível':
      case 'disponivel':
        return Icons.check_circle;
      case 'vendido':
        return Icons.monetization_on;
      case 'reservado':
        return Icons.access_time;
      case 'indisponível':
      case 'indisponivel':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
} 