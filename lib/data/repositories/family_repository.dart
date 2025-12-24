import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/family.dart';
import '../mock/mock_data.dart';

/// 家庭数据仓库
class FamilyRepository {
  final _dio = DioClient().dio;
  final bool useMock = false; // 是否使用 Mock 数据，改为 false 连接实际后端

  /// 获取家庭列表
  Future<List<Family>> getFamilies() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockFamilies.map((e) => Family.fromJson(e)).toList();
    }

    final response = await _dio.get(ApiConstants.families);
    final List<dynamic> data = response.data;
    return data.map((e) => Family.fromJson(e)).toList();
  }

  /// 创建家庭
  Future<Family> createFamily({
    required String name,
    String? avatar,
    String? description,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newFamily = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': name,
        'avatar': avatar,
        'description': description,
        'invite_code': _generateInviteCode(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      return Family.fromJson(newFamily);
    }

    final request = CreateFamilyRequest(
      name: name,
      avatar: avatar,
      description: description,
    );
    final response = await _dio.post(
      ApiConstants.families,
      data: request.toJson(),
    );
    return Family.fromJson(response.data);
  }

  /// 删除家庭
  Future<void> deleteFamily(int id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _dio.delete(ApiConstants.deleteFamily(id));
  }

  /// 加入家庭（通过邀请码）
  Future<Family> joinFamily(String inviteCode, {String? nickname}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      // 模拟查找家庭
      final family = MockData.mockFamilies.first;
      return Family.fromJson(family);
    }

    final request = JoinFamilyRequest(
      inviteCode: inviteCode,
      nickname: nickname,
    );
    final response = await _dio.post(
      ApiConstants.joinFamily,
      data: request.toJson(),
    );
    return Family.fromJson(response.data);
  }

  /// 获取家庭成员
  Future<List<FamilyMember>> getFamilyMembers(int familyId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockFamilyMembers
          .map((e) => FamilyMember.fromJson(e))
          .toList();
    }

    final response = await _dio.get(ApiConstants.familyMembers(familyId));
    final List<dynamic> data = response.data;
    return data.map((e) => FamilyMember.fromJson(e)).toList();
  }

  /// 更新成员昵称
  Future<FamilyMember> updateMemberNickname(
    int memberId,
    String nickname,
  ) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final member = MockData.mockFamilyMembers
          .firstWhere((e) => e['id'] == memberId);
      member['nickname'] = nickname;
      return FamilyMember.fromJson(member);
    }

    final request = UpdateMemberRequest(nickname: nickname);
    final response = await _dio.patch(
      ApiConstants.updateMember(memberId),
      data: request.toJson(),
    );
    return FamilyMember.fromJson(response.data);
  }

  /// 移除成员
  Future<void> removeMember(int memberId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _dio.delete(ApiConstants.removeMember(memberId));
  }

  /// 添加设备到家庭
  Future<void> addDeviceToFamily(int familyId, int deviceId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _dio.post(ApiConstants.addDeviceToFamily(familyId, deviceId));
  }

  /// 从家庭移除设备
  Future<void> removeDeviceFromFamily(int familyId, int deviceId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _dio.delete(ApiConstants.removeDeviceFromFamily(familyId, deviceId));
  }

  /// 生成邀请码（Mock用）
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      8,
      (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length],
    ).join();
  }
}

