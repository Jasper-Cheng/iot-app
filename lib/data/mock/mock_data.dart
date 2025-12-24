/// Mock 数据
class MockData {
  MockData._();

  /// Mock 登录响应
  static final mockLoginResponse = {
    'access_token': 'mock_jwt_token_xxx',
    'token_type': 'bearer',
    'role': 'user',
    'account': {
      'id': 1,
      'nickname': '测试用户',
      'gender': 'male',
      'phone': '13800138000',
      'email': 'test@example.com',
      'avatar': null,
      'role': 'user',
      'current_family_id': null,
      'created_at': '2025-01-01T00:00:00',
    }
  };

  /// Mock 设备列表（使用下划线格式的SN）
  static final mockDevices = [
    {
      'id': 1,
      'name': '客厅空调',
      'sn': 'AC001_250101_000001',
      'status': 'online',
      'account_id': 1,
      'model_id': 1,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 2,
      'name': '卧室灯',
      'sn': 'LIGHT001_250101_000002',
      'status': 'online',
      'account_id': 1,
      'model_id': 2,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 3,
      'name': '门口摄像头',
      'sn': 'CAM001_250101_000003',
      'status': 'offline',
      'account_id': 1,
      'model_id': 3,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 4,
      'name': '客厅电视',
      'sn': 'TV001_250101_000004',
      'status': 'online',
      'account_id': 1,
      'model_id': 4,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 5,
      'name': '卧室跌倒检测器',
      'sn': 'FALL001_250101_000005',
      'status': 'online',
      'account_id': 1,
      'model_id': 5,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 6,
      'name': '主卧路由器',
      'sn': 'WIFI001_250101_000006',
      'status': 'online',
      'account_id': 1,
      'model_id': 6,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 7,
      'name': '客厅扫地机器人',
      'sn': 'ROBOT001_250101_000007',
      'status': 'online',
      'account_id': 1,
      'model_id': 7,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 8,
      'name': '洗衣房洗衣机',
      'sn': 'WASH001_250101_000008',
      'status': 'online',
      'account_id': 1,
      'model_id': 8,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 9,
      'name': '厨房冰箱',
      'sn': 'FRIDGE001_250101_000009',
      'status': 'online',
      'account_id': 1,
      'model_id': 9,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 10,
      'name': '书房音箱',
      'sn': 'SPEAKER001_250101_000010',
      'status': 'online',
      'account_id': 1,
      'model_id': 10,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 11,
      'name': '客厅空气净化器',
      'sn': 'AIR001_250101_000011',
      'status': 'online',
      'account_id': 1,
      'model_id': 11,
      'created_at': '2025-01-01T00:00:00',
    },
    {
      'id': 12,
      'name': '阳台环境监测器',
      'sn': 'M701001_250101_000012',
      'status': 'online',
      'account_id': 1,
      'model_id': 12,
      'created_at': '2025-01-01T00:00:00',
    },
  ];

  /// Mock 家庭列表
  static final mockFamilies = [
    {
      'id': 1,
      'name': '我的家',
      'avatar': null,
      'description': '温馨的家',
      'invite_code': 'ABC12345',
      'created_at': '2025-01-01T00:00:00',
      'updated_at': '2025-01-01T00:00:00',
    }
  ];

  /// Mock 家庭成员
  static final mockFamilyMembers = [
    {
      'id': 1,
      'nickname': '爸爸',
      'role': 'owner',
      'joined_at': '2025-01-01T00:00:00',
      'account': {
        'id': 1,
        'nickname': '测试用户',
        'gender': 'male',
        'phone': '13800138000',
        'email': 'test@example.com',
        'avatar': null,
        'role': 'user',
        'current_family_id': 1,
        'created_at': '2025-01-01T00:00:00',
      }
    },
    {
      'id': 2,
      'nickname': '妈妈',
      'role': 'member',
      'joined_at': '2025-01-02T10:00:00',
      'account': {
        'id': 2,
        'nickname': '家庭成员',
        'gender': 'female',
        'phone': '13800138001',
        'email': 'member@example.com',
        'avatar': null,
        'role': 'user',
        'current_family_id': 1,
        'created_at': '2025-01-02T00:00:00',
      }
    },
  ];

  /// Mock 设备消息
  static final mockDeviceMessages = [
    {
      'id': 1,
      'device_id': 1,
      'level': 'normal',
      'message': '空调已开启',
      'detail': {'temperature': 26},
      'status': 'new',
      'created_at': '2025-01-01T10:00:00',
      'updated_at': null,
    },
    {
      'id': 2,
      'device_id': 3,
      'level': 'error',
      'message': '摄像头离线',
      'detail': null,
      'status': 'new',
      'created_at': '2025-01-01T09:00:00',
      'updated_at': null,
    },
  ];

  /// Mock 系统消息
  static final mockSystemMessages = [
    {
      'id': 1,
      'title': '系统维护通知',
      'content': '系统将于今晚22:00-24:00进行维护',
      'type': 'maintenance',
      'priority': 'high',
      'platforms': ['web', 'mobile'],
      'extra': null,
      'created_at': '2025-01-01T08:00:00',
      'updated_at': '2025-01-01T08:00:00',
    },
  ];

  /// Mock 签到统计
  static final mockCheckinStats = {
    'total_check_ins': 30,
    'continuous_days': 7,
    'longest_continuous': 15,
  };

  /// Mock 签到日历
  static final mockCheckinCalendar = {
    'dates': [
      '2025-01-01',
      '2025-01-02',
      '2025-01-03',
      '2025-01-04',
      '2025-01-05',
      '2025-01-06',
      '2025-01-07',
    ],
  };

  /// Mock 签到历史
  static final mockCheckinHistory = [
    {
      'id': 1,
      'check_in_type': 'bonus',
      'points_earned': 20,
      'continuous_days': 7,
      'check_in_time': '2025-01-07T08:00:00',
      'extra': null,
    },
    {
      'id': 2,
      'check_in_type': 'normal',
      'points_earned': 5,
      'continuous_days': 6,
      'check_in_time': '2025-01-06T08:00:00',
      'extra': null,
    },
  ];

  /// Mock 积分余额
  static final mockPointsBalance = {
    'available_balance': 500,
  };

  /// Mock 积分历史
  static final mockPointsHistory = [
    {
      'id': 1,
      'type': 'earn',
      'amount': 20,
      'description': '连续签到7天奖励',
      'created_at': '2025-01-07T08:00:00',
    },
    {
      'id': 2,
      'type': 'earn',
      'amount': 5,
      'description': '每日签到',
      'created_at': '2025-01-06T08:00:00',
    },
  ];

  /// Mock 反馈列表
  static final mockFeedbacks = [
    {
      'id': 1,
      'type': 'bug',
      'content': '设备离线后无法重新连接',
      'contact': '13800138000',
      'images': null,
      'status': 'processing',
      'created_at': '2025-01-01T10:00:00',
      'updated_at': '2025-01-01T10:00:00',
    },
  ];

  /// Mock 版本信息
  static final mockVersionInfo = {
    'version': '1.0.0',
    'description': '初始版本',
    'release_date': '2025-01-01',
    'download_url': null,
  };
}

