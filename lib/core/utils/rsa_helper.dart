import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';

/// RSA加密工具类
/// 使用 OAEP 填充，SHA-256 哈希，MGF1 掩码生成函数（与Web端保持一致）
class RsaHelper {
  RsaHelper._();

  /// 格式化公钥为标准PEM格式
  /// 
  /// [publicKey] 公钥字符串（可能缺少PEM头尾，可能是PKCS1或PKCS8格式）
  /// 返回 标准PEM格式的公钥（PKCS8格式）
  static String _formatPublicKey(String publicKey) {
    String trimmed = publicKey.trim();
    
    // 如果已经是完整的PEM格式，直接返回
    if (trimmed.contains('-----BEGIN') && trimmed.contains('-----END')) {
      return trimmed;
    }
    
    // 移除可能存在的PEM头尾和换行符，只保留Base64内容
    String cleanedKey = trimmed
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
        .replaceAll('-----END RSA PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .trim();

    // 添加标准PKCS8格式的PEM头尾
    // 每64个字符换行，符合PEM格式规范
    StringBuffer formattedKey = StringBuffer('-----BEGIN PUBLIC KEY-----\n');
    for (int i = 0; i < cleanedKey.length; i += 64) {
      int end = (i + 64 < cleanedKey.length) ? i + 64 : cleanedKey.length;
      formattedKey.writeln(cleanedKey.substring(i, end));
    }
    formattedKey.write('-----END PUBLIC KEY-----');
    
    return formattedKey.toString();
  }

  /// 使用RSA公钥加密数据（OAEP填充，SHA-256，MGF1）
  /// 
  /// [data] 需要加密的明文数据
  /// [publicKeyPem] RSA公钥字符串（可以是PEM格式或纯Base64）
  /// 返回 Base64编码的加密结果
  static String encryptWithPublicKey(String data, String publicKeyPem) {
    try {
      // 先格式化为标准PEM格式
      String formattedKey = _formatPublicKey(publicKeyPem);
      
      // 使用 encrypt 包的 RSAKeyParser 解析公钥
      final parser = RSAKeyParser();
      final publicKey = parser.parse(formattedKey) as RSAPublicKey;

      // 将明文转换为字节
      Uint8List dataBytes = Uint8List.fromList(utf8.encode(data));

      // 使用 pointycastle 实现 OAEP 加密，配置 SHA-256
      // 使用 withSHA256 方法指定 SHA-256 哈希函数，与 Web 端保持一致
      final encryptor = OAEPEncoding.withSHA256(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      // 加密数据
      Uint8List encryptedBytes = encryptor.process(dataBytes);

      // 转换为Base64字符串
      return base64Encode(encryptedBytes);
    } catch (e) {
      // 提供更详细的错误信息
      if (e.toString().contains('parse') || e.toString().contains('format')) {
        throw Exception('RSA公钥格式错误，请检查后端返回的公钥格式: $e');
      }
      throw Exception('RSA加密失败: $e');
    }
  }

  /// 验证PEM格式的公钥是否有效
  /// 
  /// [publicKeyPem] PEM格式的RSA公钥字符串
  /// 返回 true表示有效，false表示无效
  static bool isValidPublicKey(String publicKeyPem) {
    try {
      String formattedKey = _formatPublicKey(publicKeyPem);
      final parser = RSAKeyParser();
      parser.parse(formattedKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}

