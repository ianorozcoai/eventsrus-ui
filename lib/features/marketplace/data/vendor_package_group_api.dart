import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_package_group.dart';

/// See backend VendorPackageGroupController - vendor-defined package groups,
/// managed independently of any one package then attached to packages via
/// VendorPackageApi.setGroups.
class VendorPackageGroupApi {
  final ApiClient _apiClient;

  VendorPackageGroupApi(this._apiClient);

  Future<List<VendorPackageGroup>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/package-groups');
      return (response.data as List)
          .map((e) => VendorPackageGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorPackageGroup> create(String name) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/package-groups',
        data: {'name': name},
      );
      return VendorPackageGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/package-groups/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
