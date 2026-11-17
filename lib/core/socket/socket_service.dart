import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SocketService {
  static final SocketService instance = SocketService._init();
  IO.Socket? _socket;

  SocketService._init();

  Future<void> connect({String serverUrl = AppConstants.defaultSocketUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);

    if (token == null) return;

    if (_socket != null && _socket!.connected) {
      _socket!.disconnect();
    }

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('[SOCKET MOBILE] Conectado exitosamente');
    });

    _socket!.onDisconnect((_) {
      print('[SOCKET MOBILE] Desconectado');
    });

    _socket!.onError((error) {
      print('[SOCKET MOBILE ERROR] $error');
    });
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
