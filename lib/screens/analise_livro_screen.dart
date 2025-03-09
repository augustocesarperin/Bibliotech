import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/livro_model.dart';
import 'camera_screen.dart';
import 'adicionar_livro_screen.dart';

class AnaliseLivroScreen extends StatefulWidget {
  const AnaliseLivroScreen({super.key});

  @override
  State<AnaliseLivroScreen> createState() => _AnaliseLivroScreenState();
}

class _AnaliseLivroScreenState extends State<AnaliseLivroScreen> {
  File? _imageFile;
  Map<String, dynamic>? _extractedData;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _imageFile = result['image'] as File?;
        _extractedData = result['data'] as Map<String, dynamic>?;
        _populateFormWithExtractedData();
      });
    } else {
      // Usuário cancelou, voltar à tela anterior
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _populateFormWithExtractedData() {
    if (_extractedData != null) {
      if (_extractedData!.containsKey('title')) {
        _titleController.text = _extractedData!['title'] as String? ?? '';
      }
      
      if (_extractedData!.containsKey('author')) {
        _authorController.text = _extractedData!['author'] as String? ?? '';
      }
      
      if (_extractedData!.containsKey('genre')) {
        _genreController.text = _extractedData!['genre'] as String? ?? '';
      }
      
      if (_extractedData!.containsKey('description')) {
        _descriptionController.text = _extractedData!['description'] as String? ?? '';
      }
    }
  }

  Future<void> _adicionarLivro() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validar dados mínimos
    if (_titleController.text.isEmpty || _authorController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Título e autor são obrigatórios';
        _isLoading = false;
      });
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Preparar dados do livro
      final livroData = {
        'title': _titleController.text,
        'author': _authorController.text,
        'genre': _genreController.text.isNotEmpty ? _genreController.text : null,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        // Outros campos conforme necessário
      };
      
      // Se tiver imagem, enviar para API
      if (_imageFile != null) {
        // A API pode ser implementada para receber a imagem junto com os dados do livro
        // ou podemos enviar a imagem separadamente e depois atualizar o livro
      }
      
      // Adicionar livro
      final livro = await apiService.adicionarLivro(livroData);
      
      // Retornar à tela anterior com sucesso
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao adicionar livro: $e';
        _isLoading = false;
      });
    }
  }

  void _editarManualmente() {
    // Navegar para tela de adição manual, pré-preenchendo os campos
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarLivroScreen(
          livroPreenchido: {
            'title': _titleController.text,
            'author': _authorController.text,
            'genre': _genreController.text,
            'description': _descriptionController.text,
          },
          imagemCapturada: _imageFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Livro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _openCamera,
            tooltip: 'Capturar novamente',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                  // Imagem capturada
                  if (_imageFile != null)
                    Center(
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Text('Nenhuma imagem capturada'),
                    ),
                    
                  const SizedBox(height: 24),
                  const Text(
                    'Dados Extraídos da Imagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campos de formulário
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Autor*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _genreController,
                    decoration: const InputDecoration(
                      labelText: 'Gênero',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    '* Campos obrigatórios',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _editarManualmente,
                          child: const Text('Editar Manualmente'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _adicionarLivro,
                          child: const Text('Adicionar Livro'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 