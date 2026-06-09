import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';

class SecurityUtils {
  /// Generates a unique key based on the User's Supabase ID
  static String generateUserKey(String userId) {
    var bytes = utf8.encode("${userId}coursyria_secret_salt");
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  /// Encrypts a file chunk by chunk (AES-256)
  static Future<void> encryptFile(File sourceFile, File targetFile, String userKey) async {
    final key = encrypt.Key.fromUtf8(userKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final sourceBytes = await sourceFile.readAsBytes();
    final encrypted = encrypter.encryptBytes(sourceBytes, iv: iv);
    
    // Save IV + Encrypted Data
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    await targetFile.writeAsBytes(combined);
  }

  /// Decrypts a file into memory for playback
  static Future<Uint8List> decryptFile(File encryptedFile, String userKey) async {
    final key = encrypt.Key.fromUtf8(userKey);
    final bytes = await encryptedFile.readAsBytes();
    
    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(bytes.sublist(0, 16));
    final data = bytes.sublist(16);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(data), iv: iv);
    
    return Uint8List.fromList(decrypted);
  }

  /// Check if the device is safe (No root, no emulator)
  static Future<bool> isDeviceSecure() async {
    bool isRooted = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isMockLocation = await SafeDevice.canMockLocation;

    if (isRooted || !isRealDevice || isMockLocation) {
      return false;
    }
    return true;
  }

  /// Prevent Screenshots (Android only)
  static Future<void> preventScreenshots() async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.coursyria/security');
      try {
        await platform.invokeMethod('preventScreenshots');
      } on PlatformException catch (e) {
        print("Failed to prevent screenshots: ${e.message}");
      }
    }
  }
}
