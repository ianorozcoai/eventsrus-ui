import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_package.dart';

class VendorPackageApi {
  final ApiClient _apiClient;

  VendorPackageApi(this._apiClient);

  Future<List<VendorPackage>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/packages');
      return (response.data as List).map((e) => VendorPackage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorPackage> create({
    required String name,
    String? description,
    required PackageType packageType,
    required PackagePricingType pricingType,
    double? price,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/packages',
        data: {
          'name': name,
          'description': description,
          'packageType': packageType.toApi(),
          'pricingType': pricingType.toApi(),
          'price': price,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        },
      );
      return VendorPackage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorPackage> update({
    required int id,
    required String name,
    String? description,
    required PackageType packageType,
    required PackagePricingType pricingType,
    double? price,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/vendors/me/packages/$id',
        data: {
          'name': name,
          'description': description,
          'packageType': packageType.toApi(),
          'pricingType': pricingType.toApi(),
          'price': price,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        },
      );
      return VendorPackage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorPackage> setActive(int id, bool active) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/vendors/me/packages/$id/active',
        data: {'active': active},
      );
      return VendorPackage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Replaces the full set of groups this package belongs to. [groupIds] is
  /// sent as a raw JSON array (not wrapped in a map) - matches backend's
  /// `VendorPackageController#setGroups(List<Long>)`.
  Future<void> setGroups(int id, List<int> groupIds) async {
    try {
      await _apiClient.dio.put(
        '/api/v1/vendors/me/packages/$id/groups',
        data: groupIds,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
