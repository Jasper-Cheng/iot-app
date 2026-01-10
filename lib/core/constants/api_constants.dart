/// API 常量配置
class ApiConstants {
  ApiConstants._();

  // Base URL
  // 注意: 移动平台需要完整的 URL (包含协议和域名)
  // 开发环境: http://localhost:8000 (需要使用实际设备IP或模拟器可访问的地址)
  // Android模拟器访问本机: http://10.0.2.2:8000
  // iOS模拟器可以直接使用: http://localhost:8000
  // 真机测试: 使用电脑的局域网IP，如 http://192.168.1.100:8000
  // 生产环境: 使用正式的 API 域名
  static const String baseUrl = 'http://192.168.12.119:8000/api/v1/client';
  
  // 超时时间
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 认证接口
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String wechatLogin = '/auth/login/wechat'; // 微信登录
  static const String qrcode = '/auth/login/qrcode';
  static const String checkStatus = '/auth/login/check_status';
  static const String bindPhone = '/auth/login/bind_phone';
  static const String setPassword = '/auth/set_password';
  static const String rsaPublicKey = '/auth/rsa_public_key';
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String currentFamily = '/auth/current-family';
  static const String deleteAccount = '/auth/account';

  // 设备接口
  static const String devices = '/devices/';
  static const String bindDevice = '/devices/bind-by-sn/';
  static String unbindDevice(String sn) => '/devices/unbind-by-sn/$sn';
  static String updateDeviceName(int id) => '/devices/$id/name';

  // 设备消息接口
  static const String deviceMessages = '/device-messages/';
  static String markMessageRead(int id) => '/device-messages/$id/make-read';
  static const String markAllRead = '/device-messages/mark-all-read';
  static const String unreadCount = '/device-messages/unread-count';

  // 家庭接口
  static const String families = '/families/';
  static String deleteFamily(int id) => '/families/$id';
  static String addDeviceToFamily(int familyId, int deviceId) =>
      '/families/$familyId/devices/$deviceId';
  static String removeDeviceFromFamily(int familyId, int deviceId) =>
      '/families/$familyId/devices/$deviceId';

  // 家庭成员接口
  static String familyMembers(int familyId) => '/family-members/family/$familyId';
  static const String joinFamily = '/family-members/join-by-invite-code';
  static String updateMember(int id) => '/family-members/$id';
  static String removeMember(int id) => '/family-members/$id';

  // 签到接口
  static const String checkIn = '/check-in/';
  static const String checkInCalendar = '/check-in/calendar';
  static const String checkInStats = '/check-in/stats';
  static const String checkInHistory = '/check-in/history';

  // 积分接口
  static const String pointsBalance = '/points/balance';
  static const String pointsHistory = '/points/history';

  // 其他接口
  static const String systemMessages = '/system-messages/';
  static const String feedback = '/feedback/';
  static const String versionInfo = '/version-info/';

  // MQTT 配置
  static const String mqttBroker = '192.168.12.119';
  static const int mqttPort = 1883;
  static const String mqttClientPrefix = 'app_iot_';
  
  // MQTT 主题
  static const String mqttSystemNotice = 'system/notice';        // 系统通知
  static String mqttHomeNotice(int homeId) => 'home/$homeId/notice';  // 家庭通知
  static String mqttDeviceNotice(String sn) => 'device/$sn/notice';    // 设备消息通知
  static String mqttDeviceData(String sn) => 'client/$sn/data';          // 后台 -> 客户端（web/app）
  static String mqttDeviceStatus(String sn) => 'client/$sn/status';      // 后台 -> 客户端（web/app）
  static String mqttDeviceControl(String sn) => 'client/$sn/control';    // 客户端（web/app）-> 后台
}

