import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../manual_glyph_selector/presentation/manual_glyph_selector_screen.dart';

/// Phase-2 camera capture screen — intentionally the simple version described
/// in the architecture doc's build order. It captures a full-frame photo and
/// hands off to the Manual Glyph Selector; there is no bounding-box overlay
/// or crop UI yet, since no detection model exists until Phase 3.
///
/// Replacing the "Select Glyph" handoff below with an actual detection call
/// is exactly the Phase 3 integration point — the rest of this screen
/// (camera lifecycle, capture, retake) stays the same.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _capturedPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera found on this device.');
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      setState(() => _errorMessage = 'Could not start camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final file = await controller.takePicture();
    if (!mounted) return;
    setState(() => _capturedPath = file.path);
  }

  void _openManualSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ManualGlyphSelectorScreen(capturedImagePath: _capturedPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a Glyph')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _openManualSelector,
                      child: const Text('Select Glyph Manually Instead'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_capturedPath != null) {
            return Column(
              children: [
                Expanded(
                  child: Image.file(File(_capturedPath!), fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _capturedPath = null),
                          child: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _openManualSelector,
                          child: const Text('Select Glyph'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: CameraPreview(_controller!)),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.large(
                    onPressed: _capture,
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: TextButton(
                  onPressed: _openManualSelector,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Skip — Browse Dictionary'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
