import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

/// An [http.BaseClient] that streams a synthetic payload instead of opening a
/// real socket.
///
/// It is a genuine `package:http` client, so the request pipeline in
/// [HttpRequestService] (headers, [http.StreamedResponse], byte stream,
/// [http.ClientException]) behaves exactly like it would against a real API -
/// which keeps the demo deterministic and works without internet access.
class SimulatedHttpClient extends http.BaseClient {
  SimulatedHttpClient({
    this.handshakeDelay = const Duration(milliseconds: 260),
    this.maxChunkSize = 256 * 1024,
  });

  /// Fake TLS + server think time before the body starts streaming.
  final Duration handshakeDelay;

  /// Safety cap for a single streamed chunk.
  final int maxChunkSize;

  bool _closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final Map<String, String> query = request.url.queryParameters;
    final int totalBytes = _readInt(query['bytes'], 320 * 1024);
    final int chunkCount = max(1, _readInt(query['chunks'], 24));
    final Duration chunkDelay =
        Duration(milliseconds: _readInt(query['chunkDelayMs'], 140));

    await Future<void>.delayed(handshakeDelay);
    if (_closed) {
      throw http.ClientException(
        'Connection closed before the request could be sent.',
        request.url,
      );
    }

    final int chunkSize = max(1, min(totalBytes ~/ chunkCount, maxChunkSize));
    final StreamController<List<int>> controller = StreamController<List<int>>();

    unawaited(
      _streamBody(
        controller,
        request: request,
        totalBytes: totalBytes,
        chunkSize: chunkSize,
        chunkDelay: chunkDelay,
      ),
    );

    return http.StreamedResponse(
      controller.stream,
      200,
      contentLength: totalBytes,
      request: request,
      headers: const <String, String>{
        'content-type': 'application/octet-stream',
        'x-simulated': 'true',
      },
    );
  }

  Future<void> _streamBody(
    StreamController<List<int>> controller, {
    required http.BaseRequest request,
    required int totalBytes,
    required int chunkSize,
    required Duration chunkDelay,
  }) async {
    try {
      var sent = 0;
      while (sent < totalBytes) {
        await Future<void>.delayed(chunkDelay);
        if (_closed || controller.isClosed) {
          if (!controller.isClosed) {
            controller.addError(
              http.ClientException('Connection dropped while streaming.', request.url),
            );
          }
          return;
        }
        final int size = min(chunkSize, totalBytes - sent);
        controller.add(List<int>.filled(size, 0));
        sent += size;
      }
    } finally {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  @override
  void close() {
    _closed = true;
    super.close();
  }

  int _readInt(String? raw, int fallback) {
    final int? value = raw == null ? null : int.tryParse(raw);
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }
}