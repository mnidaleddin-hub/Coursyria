import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class DownloadManager {
  final Dio _dio = Dio();

  // AES Decryption for on-the-fly play or full file
  static Uint8List decryptData(Uint8List encryptedData, String keyString) {
    final key = encrypt.Key.fromUtf8(keyString.padRight(16).substring(0, 16));
    final iv = encrypt.IV.fromLength(16); // Should match backend IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedData), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Future<String> getInternalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> downloadAndEncrypt(String url, String fileName, String key) async {
    final path = await getInternalPath();
    final file = File('$path/$fileName.bin');

    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      // Simple encryption before saving to .bin
      final keyObj = encrypt.Key.fromUtf8(key.padRight(16).substring(0, 16));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(keyObj, mode: encrypt.AESMode.cbc));
      
      final encrypted = encrypter.encryptBytes(response.data, iv: iv);
      
      await file.writeAsBytes(encrypted.bytes);
      if (kDebugMode) debugPrint("Downloaded and Encrypted: ${file.path}");
    } catch (e) {
      if (kDebugMode) debugPrint("Download error: $e");
    }
  }
}
