import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/livro_model.dart';
import '../services/api_service.dart';

class EditarLivroScreen extends StatefulWidget {
  final Livro livro;

  const EditarLivroScreen({super.key, required this.livro});

  @override
  State<EditarLivroScreen> createState() => _EditarLivroScreenState();
}

class _EditarLivroScreenState extends State<EditarLivroScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _autorController;
  late TextEditingController _generoController;
  late TextEditingController _descricaoController;
  late TextEditingController _secaoController;
  
  bool _isLoading = false;
  String? _erro;
  
  @override
  void initState() {
    super.initState();
    // Inicializar os controllers com os valores do livro
    _tituloController = TextEditingController(text: widget.livro.title);
    _autorController = TextEditingController(text: widget.livro.author);
    _generoController = TextEditingController(text: widget.livro.genre ?? '');
    _descricaoController = TextEditingController(text: widget.livro.description ?? '');
    _secaoController = TextEditingController(text: widget.livro.storageSection ?? '');
  }
  
  @override
  void dispose() {
    _tituloController.dispose();
    _autorController.dispose();
    _generoController.dispose();
    _descricaoController.dispose();
    _secaoController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Livro'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mensagem de erro, se houver
                    if (_erro != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _erro!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    
                    // Título do livro
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o título do livro';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Autor do livro
                    TextFormField(
                      controller: _autorController,
                      decoration: const InputDecoration(
                        labelText: 'Autor *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o autor do livro';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Gênero do livro
                    TextFormField(
                      controller: _generoController,
                      decoration: const InputDecoration(
                        labelText: 'Gênero',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Seção de armazenamento
                    TextFormField(
                      controller: _secaoController,
                      decoration: const InputDecoration(
                        labelText: 'Seção',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shelves),
                        hintText: 'Ex: A1, B2, C3',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Descrição do livro
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão para adicionar imagem (será implementado posteriormente)
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('ALTERAR IMAGEM'),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão para salvar o livro
                    ElevatedButton(
                      onPressed: _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SALVAR ALTERAÇÕES'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Criamos um novo objeto Livro com os dados atualizados
      final livroAtualizado = Livro(
        id: widget.livro.id,
        title: _tituloController.text,
        author: _autorController.text,
        genre: _generoController.text.isNotEmpty ? _generoController.text : null,
        description: _descricaoController.text.isNotEmpty ? _descricaoController.text : null,
        storageSection: _secaoController.text.isNotEmpty ? _secaoController.text : null,
        status: widget.livro.status,
        imagePath: widget.livro.imagePath,
        createdAt: widget.livro.createdAt,
        updatedAt: widget.livro.updatedAt,
      );
      
      await apiService.atualizarLivro(livroAtualizado);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro atualizado com sucesso!')),
      );
      
      Navigator.pop(context, true); // Retorna true para indicar que o livro foi atualizado
    } catch (e) {
      setState(() {
        _erro = 'Erro ao atualizar livro: $e';
        _isLoading = false;
      });
    }
  }
} 