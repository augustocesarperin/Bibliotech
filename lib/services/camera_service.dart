import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isInitialized = false;
  
  // Inicializar câmeras disponíveis
  Future<void> initialize() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        controller = CameraController(
          cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller!.initialize();
        isInitialized = true;
      }
    } catch (e) {
      debugPrint('Erro ao inicializar câmera: $e');
      rethrow;
    }
  }
  
  // Tirar foto usando a câmera
  Future<File?> takePicture() async {
    if (!isInitialized || controller == null || !controller!.value.isInitialized) {
      throw Exception('Câmera não inicializada');
    }
    
    try {
      final XFile xFile = await controller!.takePicture();
      
      // Salvar a imagem em um diretório temporário
      final directory = await getTemporaryDirectory();
      final filename = path.basename(xFile.path);
      final savedImage = await File(xFile.path).copy('${directory.path}/$filename');
      
      return savedImage;
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      return null;
    }
  }
  
  // Selecionar imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedFile == null) return null;
      
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }
  
  // Dispose do controlador da câmera
  void dispose() {
    controller?.dispose();
    isInitialized = false;
  }
  
  // Detectar orientação da câmera
  DeviceOrientation getDeviceOrientation() {
    if (controller?.value.deviceOrientation != null) {
      return controller!.value.deviceOrientation;
    }
    return DeviceOrientation.portraitUp;
  }
} 