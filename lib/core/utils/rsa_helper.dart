import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

/// RSA加密工具类
class RsaHelper {
  RsaHelper._();

  /// 使用RSA公钥加密数据
  /// 
  /// [data] 需要加密的明文数据
  /// [publicKeyPem] PEM格式的RSA公钥字符串
  /// 返回 Base64编码的加密结果
  static String encryptWithPublicKey(String data, String publicKeyPem) {
    try {
      // 清理公钥字符串，移除PEM头尾和换行符
      String cleanedKey = publicKeyPem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      // 解析公钥
      final publicKey = RSAKeyParser().parse(cleanedKey) as RSAPublicKey;

      // 创建加密器
      final encrypter = Encrypter(RSA(publicKey: publicKey));

      // 加密数据并返回Base64字符串
      final encrypted = encrypter.encrypt(data);
      return encrypted.base64;
    } catch (e) {
      throw Exception('RSA加密失败: $e');
    }
  }

  /// 验证PEM格式的公钥是否有效
  /// 
  /// [publicKeyPem] PEM格式的RSA公钥字符串
  /// 返回 true表示有效，false表示无效
  static bool isValidPublicKey(String publicKeyPem) {
    try {
      String cleanedKey = publicKeyPem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      RSAKeyParser().parse(cleanedKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 格式化公钥为标准PEM格式
  /// 
  /// [publicKey] 公钥字符串（可能缺少PEM头尾）
  /// 返回 标准PEM格式的公钥
  static String formatPublicKey(String publicKey) {
    String cleanedKey = publicKey
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();

    // 添加PEM头尾
    return '-----BEGIN PUBLIC KEY-----\n$cleanedKey\n-----END PUBLIC KEY-----';
  }
}

