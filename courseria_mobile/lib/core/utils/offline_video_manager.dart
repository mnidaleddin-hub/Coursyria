import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:courseria_mobile/controllers/auth_controller.dart';
import 'package:get_storage/get_storage.dart';

enum DownloadStatus { pending, downloading, paused, completed, failed }

class OfflineVideoManager {
  static final OfflineVideoManager _instance = OfflineVideoManager._internal();
  factory OfflineVideoManager() => _instance;
  OfflineVideoManager._internal();

  final Dio _dio = Dio();
  final _storage = GetStorage('offline_metadata');
  
  // Encryption key derivation
  enc.Key _deriveKey(String userId) {
    String keyStr = ("${userId}coursyria_secure_v2_salt").padRight(32, '0').substring(0, 32);
    return enc.Key.fromUtf8(keyStr);
  }

  final _iv = enc.IV.fromLength(16);

  String _hashId(String id) {
    return sha256.convert(utf8.encode(id)).toString().substring(0, 16);
  }

  Future<String> _getVaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final vault = p.join(directory.path, '.vault');
    if (!await Directory(vault).exists()) {
      await Directory(vault).create(recursive: true);
    }
    return vault;
  }

  Future<String> getLocalFilePath(String lessonId) async {
    final vault = await _getVaultPath();
    return p.join(vault, '${_hashId(lessonId)}.dat');
  }

  // Segmented Download with Resume Support
  Future<void> downloadVideo({
    required String url,
    required String lessonId,
    required String title,
    required Function(double progress, DownloadStatus status) onUpdate,
  }) async {
    final userId = Get.find<AuthController>().userData['id'];
    if (userId == null) throw "User not authenticated";

    final savePath = await getLocalFilePath(lessonId);
    final tempPath = "$savePath.tmp";
    final file = File(tempPath);
    
    int startByte = 0;
    if (await file.exists()) {
      startByte = await file.length();
    }

    try {
      onUpdate(startByte > 0 ? 0.01 : 0.0, DownloadStatus.downloading);

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            if (startByte > 0) HttpHeaders.rangeHeader: 'bytes=$startByte-',
          },
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      final totalBytes = int.tryParse(response.headers.value(HttpHeaders.contentLengthHeader) ?? "") ?? 0;
      final fullSize = startByte + totalBytes;
      
      RandomAccessFile raf = await file.open(mode: FileMode.append);
      int downloadedBytes = startByte;

      await for (var chunk in response.data.stream) {
        await raf.writeFrom(chunk);
        downloadedBytes += (chunk as List<int>).length;
        if (fullSize > 0) {
          onUpdate(downloadedBytes / fullSize, DownloadStatus.downloading);
        }
      }

      await raf.close();

      // Finalize: Encrypt and move to final path
      await _finalizeDownload(tempPath, savePath, userId);
      
      // Save Metadata
      _storage.write(lessonId, {
        'title': title,
        'size': downloadedBytes,
        'downloaded_at': DateTime.now().toIso8601String(),
        'status': 'completed'
      });

      onUpdate(1.0, DownloadStatus.completed);
    } catch (e) {
      onUpdate(0.0, DownloadStatus.failed);
      rethrow;
    }
  }

  Future<void> cleanupDecryptedCache() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(tempDir.path);
    if (await dir.exists()) {
      await for (var file in dir.list()) {
        if (file is File && p.basename(file.path).startsWith('v_cache_')) {
          await file.delete();
        }
      }
    }
  }

  Future<void> _finalizeDownload(String tempPath, String finalPath, String userId) async {
    final tempFile = File(tempPath);
    final videoBytes = await tempFile.readAsBytes();
    
    final encrypter = enc.Encrypter(enc.AES(_deriveKey(userId)));
    final encrypted = encrypter.encryptBytes(videoBytes, iv: _iv);
    
    final finalFile = File(finalPath);
    await finalFile.writeAsBytes(encrypted.bytes);
    
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  Future<File?> getDecryptedVideo(String lessonId) async {
    final userId = Get.find<AuthController>().userData['id'];
    if (userId == null) return null;

    final path = await getLocalFilePath(lessonId);
    final file = File(path);

    if (!await file.exists()) return null;

    final encryptedBytes = await file.readAsBytes();
    final encrypter = enc.Encrypter(enc.AES(_deriveKey(userId)));
    final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: _iv);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'v_cache_${_hashId(lessonId)}.mp4'));
    await tempFile.writeAsBytes(decryptedBytes);

    return tempFile;
  }

  Future<bool> isVideoDownloaded(String lessonId) async {
    final path = await getLocalFilePath(lessonId);
    return await File(path).exists();
  }

  Future<void> deleteVideo(String lessonId) async {
    final path = await getLocalFilePath(lessonId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _storage.remove(lessonId);
  }

  Map<String, dynamic> getAllDownloads() {
    final Map<String, dynamic> all = {};
    _storage.getKeys().forEach((key) {
      all[key] = _storage.read(key);
    });
    return all;
  }

  Future<double> getUsedStorageMB() async {
    final vault = await _getVaultPath();
    final dir = Directory(vault);
    int totalSize = 0;
    if (await dir.exists()) {
      await for (var file in dir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }
    return totalSize / (1024 * 1024);
  }
}
