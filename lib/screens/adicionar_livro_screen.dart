import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AdicionarLivroScreen extends StatefulWidget {
  final Map<String, String>? livroPreenchido;
  final File? imagemCapturada;

  const AdicionarLivroScreen({
    super.key, 
    this.livroPreenchido,
    this.imagemCapturada,
  });

  @override
  State<AdicionarLivroScreen> createState() => _AdicionarLivroScreenState();
}

class _AdicionarLivroScreenState extends State<AdicionarLivroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _generoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _secaoController = TextEditingController();
  
  bool _isLoading = false;
  String? _erro;
  File? _imagemSelecionada;
  
  @override
  void initState() {
    super.initState();
    _preencherCampos();
  }
  
  void _preencherCampos() {
    if (widget.livroPreenchido != null) {
      _tituloController.text = widget.livroPreenchido!['title'] ?? '';
      _autorController.text = widget.livroPreenchido!['author'] ?? '';
      _generoController.text = widget.livroPreenchido!['genre'] ?? '';
      _descricaoController.text = widget.livroPreenchido!['description'] ?? '';
      if (widget.livroPreenchido!['storage_section'] != null) {
        _secaoController.text = widget.livroPreenchido!['storage_section']!;
      }
    }
    
    if (widget.imagemCapturada != null) {
      _imagemSelecionada = widget.imagemCapturada;
    }
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
        title: const Text('Adicionar Livro'),
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
                    
                    // Imagem do livro, se houver
                    if (_imagemSelecionada != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imagemSelecionada!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.5),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _imagemSelecionada = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
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
                    
                    // Botão para adicionar imagem
                    if (_imagemSelecionada == null)
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                          );
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('ADICIONAR IMAGEM'),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão para salvar o livro
                    ElevatedButton(
                      onPressed: _salvarLivro,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SALVAR LIVRO'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Future<void> _salvarLivro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final livroData = {
        'title': _tituloController.text,
        'author': _autorController.text,
        'genre': _generoController.text.isNotEmpty ? _generoController.text : null,
        'description': _descricaoController.text.isNotEmpty ? _descricaoController.text : null,
        'storage_section': _secaoController.text.isNotEmpty ? _secaoController.text : null,
      };
      
      // Upload da imagem, se houver
      if (_imagemSelecionada != null) {
        // Implementar o upload da imagem
        // Como exemplo, poderíamos usar o método analisarImagemLivro apenas para upload
        // e ignorar os resultados retornados
        try {
          await apiService.analisarImagemLivro(_imagemSelecionada!, 
            dadosAdicionais: {'skip_analysis': 'true'});
        } catch (e) {
          // Tratar erro de upload, mas não impedir o cadastro do livro
          print('Aviso: Falha ao enviar imagem: $e');
        }
      }
      
      await apiService.adicionarLivro(livroData);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro adicionado com sucesso!')),
      );
      
      Navigator.pop(context, true); // Retorna true para indicar que um livro foi adicionado
    } catch (e) {
      setState(() {
        _erro = 'Erro ao adicionar livro: $e';
        _isLoading = false;
      });
    }
  }
} 