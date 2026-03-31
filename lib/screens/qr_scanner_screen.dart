import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/user_model.dart';
import '../models/thermal_point_model.dart';
import '../services/qr_service.dart';
import '../services/user_data_service.dart';
import '../utils/app_theme.dart';
import '../utils/web_camera_permission.dart';

class QRScannerScreen extends StatefulWidget {
  final User user;
  final ThermalPoint thermalPoint;

  const QRScannerScreen({
    super.key,
    required this.user,
    required this.thermalPoint,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController cameraController;
  bool _isProcessing = false;
  bool _isScannerActive = false;
  String? _errorMessage;
  final TextEditingController _manualQRController = TextEditingController();

  final QRService _qrService = QRService();
  final UserDataService _userDataService = UserDataService();

  @override
  void initState() {
    super.initState();
    // En web: autoStart es verdadero, en móvil es falso
    cameraController = MobileScannerController(autoStart: kIsWeb);
    if (!kIsWeb) {
      _checkPermissionAndStart();
    } else {
      _isScannerActive = true;
    }
  }

  Future<void> _checkPermissionAndStart() async {
    try {
      final hasPermission = await requestWebCameraPermission();

      if (!mounted) return;

      if (!hasPermission) {
        setState(() {
          _isScannerActive = false;
          _errorMessage =
              'Permiso de cámara denegado. Activa el permiso del navegador y recarga la página.';
        });
        return;
      }

      setState(() {
        _isScannerActive = true;
        _errorMessage = null;
      });

      await cameraController.start();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al iniciar cámara: $e';
        _isScannerActive = false;
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    _manualQRController.dispose();
    super.dispose();
  }

  /// Procesa el código QR escaneado
  Future<void> _handleQRScan(BarcodeCapture capture) async {
    if (!_isScannerActive || _isProcessing) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;

      if (rawValue == null) {
        continue;
      }

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      try {
        // Validar el QR
        final thermalPointId = await _qrService.validateQRCode(rawValue);

        if (!mounted) return;

        if (thermalPointId == null) {
          setState(() {
            _errorMessage = 'QR inválido o expirado';
            _isProcessing = false;
          });
          continue;
        }

        // Verificar que el QR pertenece al punto termal correcto
        if (thermalPointId != widget.thermalPoint.id) {
          setState(() {
            _errorMessage = 'QR no corresponde a este punto termal';
            _isProcessing = false;
          });
          continue;
        }

        // El QR es válido, proceder con el check-in
        await _performCheckIn();
      } catch (e) {
        debugPrint('Error procesando QR: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Error al procesar QR';
            _isProcessing = false;
          });
        }
      }
    }
  }

  /// Realiza el check-in del usuario
  Future<void> _performCheckIn() async {
    try {
      // Crear check-in
      await _userDataService.createCheckIn(
        userId: widget.user.id,
        pointId: widget.thermalPoint.id,
        points: 50,
      );

      // Actualizar puntos del usuario
      await _userDataService.updateUserPoints(widget.user.id, 50);

      // Verificar si es el primer check-in
      final checkIns = await _userDataService.getUserCheckIns(widget.user.id);
      if (checkIns.length == 1) {
        await _userDataService.addBadge(
          userId: widget.user.id,
          badgeId: 'first_checkin',
          name: 'Primera Visita',
          description: 'Has visitado tu primer punto termal',
          icon: '🎯',
        );
      }

      if (!mounted) return;

      // Mostrar éxito y cerrar
      _showSuccessDialog();
    } catch (e) {
      debugPrint('Error en check-in: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al realizar check-in';
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Check-in Exitoso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido a ${widget.thermalPoint.name}!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '+50 puntos ganados',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.light.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar dialog
              Navigator.pop(context, true); // Cerrar scanner y devolver true
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(MobileScannerException error) {
    final errorCode = error.errorCode.name.toLowerCase();
    
    if (kIsWeb) {
      // Mensajes específicos para Web
      if (errorCode.contains('permission')) {
        return 'Permiso de cámara denegado.\n\n'
            'Habilita el permiso en la barra de direcciones del navegador y recarga.';
      }
      if (errorCode.contains('notfound') || errorCode.contains('notallowed')) {
        return 'No se encontró cámara o permiso no concedido.\n\n'
            'Asegúrate de entrar con HTTPS o localhost.';
      }
      if (errorCode.contains('generic')) {
        return 'Error genérico de cámara.\n\n'
            'Intenta:\n'
            '1. Recargar la página\n'
            '2. Usar HTTPS o localhost\n'
            '3. Comprobar permisos del navegador';
      }
      return 'Error: $errorCode\n\nRecarga la página e intenta de nuevo.';
    } else {
      // Mensajes para móvil
      if (errorCode.contains('permission')) {
        return 'Permiso de cámara denegado.\n\n'
            'Habilita el permiso en configuración.';
      }
      return 'Error de cámara: $errorCode\n\nIntenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // En Web: mostrar formulario de entrada manual
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Introducir Código QR'),
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.qr_code_2,
                    size: 64,
                    color: AppTheme.brandTeal,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Escaneo de QR en Web',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Introduce el código QR proporcionado por el administrador',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _manualQRController,
                    enabled: !_isProcessing,
                    decoration: InputDecoration(
                      labelText: 'Código QR',
                      hintText: 'ej: point-1-1711828800000',
                      prefixIcon: const Icon(Icons.qr_code),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _errorMessage,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _handleManualQRInput(value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              if (_manualQRController.text.isNotEmpty) {
                                _handleManualQRInput(_manualQRController.text);
                              } else {
                                setState(() {
                                  _errorMessage = 'Por favor introduce un código QR';
                                });
                              }
                            },
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isProcessing ? 'Procesando...' : 'Validar QR'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // En Móvil: mostrar scanner normal
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scanner de cámara
          MobileScanner(
            controller: cameraController,
            onDetect: _handleQRScan,
            errorBuilder: (context, error, child) {
              String errorMessage = _getErrorMessage(error);
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error de cámara',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _checkPermissionAndStart();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onScannerStarted: (args) {
              debugPrint('Scanner iniciado: ${args != null}');
            },
          ),

          // Overlay con marco de escaneo
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.light.primaryColor,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Esquinas del marco
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                            left: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                            right: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                            left: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                            right: BorderSide(
                              color: AppTheme.light.primaryColor,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Información inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _isProcessing
                        ? 'Procesando QR...'
                        : 'Acerca la cámara al código QR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Botón de cancelar
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black.withOpacity(0.6),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Maneja entrada manual de QR en Web
  Future<void> _handleManualQRInput(String qrCode) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Validar el QR
      final thermalPointId = await _qrService.validateQRCode(qrCode);

      if (!mounted) return;

      if (thermalPointId == null) {
        setState(() {
          _errorMessage = 'Código QR inválido o expirado';
          _isProcessing = false;
        });
        return;
      }

      // Verificar que el QR pertenece al punto termal correcto
      if (thermalPointId != widget.thermalPoint.id) {
        setState(() {
          _errorMessage = 'QR no corresponde a este punto termal';
          _isProcessing = false;
        });
        return;
      }

      // El QR es válido, proceder con el check-in
      await _performCheckIn();
    } catch (e) {
      debugPrint('Error validando QR manual: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al validar QR';
          _isProcessing = false;
        });
      }
    }
  }
}
