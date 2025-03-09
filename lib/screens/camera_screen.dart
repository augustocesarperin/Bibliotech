import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';

class CameraScreen extends StatefulWidget {
  final bool allowGallery;
  final Function(File?, Map<String, dynamic>?)? onImageProcessed;

  const CameraScreen({
    super.key,
    this.allowGallery = true,
    this.onImageProcessed,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Controle do ciclo de vida da câmera
    if (_cameraService.controller == null || !_cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await _cameraService.initialize();
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Falha ao inicializar câmera: $e';
      });
    }
  }

  Future<void> _captureImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final File? imageFile = await _cameraService.takePicture();
      if (imageFile != null) {
        await _processImage(imageFile);
      } else {
        setState(() {
          _errorMessage = 'Falha ao capturar imagem';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao capturar imagem: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final File? imageFile = await _cameraService.pickImageFromGallery();
      if (imageFile != null) {
        await _processImage(imageFile);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar imagem: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Enviar a imagem para a API para análise OCR
      final result = await apiService.analisarImagemLivro(imageFile);
      
      // Callback com a imagem e os dados extraídos
      if (widget.onImageProcessed != null) {
        widget.onImageProcessed!(imageFile, result);
      }
      
      // Retornar à tela anterior
      if (mounted) {
        Navigator.of(context).pop({
          'image': imageFile,
          'data': result,
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao processar imagem: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar Imagem'),
        actions: [
          if (widget.allowGallery)
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _isProcessing ? null : _pickFromGallery,
              tooltip: 'Escolher da galeria',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Visualização da câmera
          if (_isInitializing)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _buildErrorWidget()
          else if (_cameraService.controller != null)
            _buildCameraPreview(),
            
          // Overlay de processamento
          if (_isProcessing)
            const LoadingOverlay(message: 'Processando imagem...'),
        ],
      ),
      floatingActionButton: _isInitializing || _errorMessage != null || _isProcessing
          ? null
          : FloatingActionButton(
              onPressed: _captureImage,
              child: const Icon(Icons.camera),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildErrorWidget() {
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
            'Erro na câmera',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCamera,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: AspectRatio(
            aspectRatio: deviceRatio,
            child: CameraPreview(_cameraService.controller!),
          ),
        ),
      ),
    );
  }
} 