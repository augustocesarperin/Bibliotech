import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/livro_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'editar_livro_screen.dart';

class DetalhesLivroScreen extends StatefulWidget {
  final Livro livro;

  const DetalhesLivroScreen({super.key, required this.livro});

  @override
  State<DetalhesLivroScreen> createState() => _DetalhesLivroScreenState();
}

class _DetalhesLivroScreenState extends State<DetalhesLivroScreen> {
  bool _isLoading = false;
  String? _erro;
  Livro? _livroAtualizado;

  Livro get livro => _livroAtualizado ?? widget.livro;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final ehAdmin = authService.ehAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(livro.title),
        actions: [
          if (ehAdmin && livro.isAvailable())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarLivroScreen(livro: livro),
                  ),
                );
                
                // Se o livro foi atualizado, atualizar a tela
                if (result == true) {
                  // Buscar o livro atualizado
                  try {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    final apiService = Provider.of<ApiService>(context, listen: false);
                    final livroAtualizado = await apiService.getLivro(livro.id);
                    
                    setState(() {
                      _livroAtualizado = livroAtualizado;
                      _isLoading = false;
                    });
                  } catch (e) {
                    if (!mounted) return;
                    
                    setState(() {
                      _erro = e.toString();
                      _isLoading = false;
                    });
                  }
                }
              },
              tooltip: 'Editar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetalhesLivro(),
      bottomNavigationBar: livro.isAvailable()
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildDetalhesLivro() {
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar livro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_erro!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem e status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem do livro
              Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: livro.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          livro.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.book, size: 60));
                          },
                        ),
                      )
                    : const Center(child: Icon(Icons.book, size: 60)),
              ),
              const SizedBox(width: 16),
              // Informações básicas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      livro.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      livro.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Livro.getStatusColor(livro.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        livro.getStatusText(),
                        style: TextStyle(
                          color: Livro.getStatusColor(livro.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Seções de informações
          _buildInfoSection('Gênero', livro.genre ?? 'Não especificado'),
          _buildInfoSection('Seção', livro.storageSection ?? 'Não especificado'),
          _buildInfoSection('Descrição', livro.description ?? 'Sem descrição disponível'),
          
          const Divider(height: 32),
          
          // Informações do sistema
          Text(
            'Informações do Sistema',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildSystemInfo('ID', livro.id.toString()),
          _buildSystemInfo('Status', livro.status),
          _buildSystemInfo('Adicionado em', _formatDate(livro.createdAt)),
          _buildSystemInfo('Última atualização', _formatDate(livro.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _venderLivro,
              icon: const Icon(Icons.sell),
              label: const Text('VENDER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _moverLivro,
              icon: const Icon(Icons.swap_vert),
              label: const Text('MOVER'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _venderLivro() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar venda'),
        content: const Text('Deseja confirmar a venda deste livro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final livroAtualizado = await apiService.venderLivro(livro.id);
      
      setState(() {
        _livroAtualizado = livroAtualizado;
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro vendido com sucesso!')),
      );
      
      // Retornar true para a tela anterior para indicar que deve recarregar a lista
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _moverLivro() async {
    final secaoAtual = livro.storageSection ?? 'Não especificada';
    final TextEditingController secaoController = TextEditingController();
    final TextEditingController observacoesController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mover Livro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seção atual: $secaoAtual'),
              const SizedBox(height: 16),
              TextField(
                controller: secaoController,
                decoration: const InputDecoration(
                  labelText: 'Nova seção*',
                  hintText: 'Ex: A1, B2, C3',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Motivo da movimentação',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              if (secaoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, informe a nova seção')),
                );
                return;
              }
              Navigator.pop(context, {
                'secao': secaoController.text,
                'observacoes': observacoesController.text,
              });
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final livroAtualizado = await apiService.moverLivro(
        livro.id, 
        result['secao']!,
        observacoes: result['observacoes']!.isNotEmpty ? result['observacoes'] : null,
      );
      
      setState(() {
        _livroAtualizado = livroAtualizado;
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro movido com sucesso!')),
      );
      
      // Retornar true para a tela anterior para indicar que deve recarregar a lista
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return isoString;
    }
  }
} 