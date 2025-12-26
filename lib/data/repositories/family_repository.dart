import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/family.dart';

/// 家庭数据仓库
class FamilyRepository {
  final _dio = DioClient().dio;

  /// 获取家庭列表
  Future<List<Family>> getFamilies() async {
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
    await _dio.delete(ApiConstants.deleteFamily(id));
  }

  /// 加入家庭（通过邀请码）
  Future<Family> joinFamily(String inviteCode, {String? nickname}) async {
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
    final response = await _dio.get(ApiConstants.familyMembers(familyId));
    final List<dynamic> data = response.data;
    return data.map((e) => FamilyMember.fromJson(e)).toList();
  }

  /// 更新成员昵称
  Future<FamilyMember> updateMemberNickname(
    int memberId,
    String nickname,
  ) async {
    final request = UpdateMemberRequest(nickname: nickname);
    final response = await _dio.patch(
      ApiConstants.updateMember(memberId),
      data: request.toJson(),
    );
    return FamilyMember.fromJson(response.data);
  }

  /// 移除成员
  Future<void> removeMember(int memberId) async {
    await _dio.delete(ApiConstants.removeMember(memberId));
  }

  /// 添加设备到家庭
  Future<void> addDeviceToFamily(int familyId, int deviceId) async {
    await _dio.post(ApiConstants.addDeviceToFamily(familyId, deviceId));
  }

  /// 从家庭移除设备
  Future<void> removeDeviceFromFamily(int familyId, int deviceId) async {
    await _dio.delete(ApiConstants.removeDeviceFromFamily(familyId, deviceId));
  }
}

