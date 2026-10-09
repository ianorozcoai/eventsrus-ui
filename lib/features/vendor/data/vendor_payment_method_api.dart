import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_payment_method.dart';

class VendorPaymentMethodApi {
  final ApiClient _apiClient;

  VendorPaymentMethodApi(this._apiClient);

  Future<List<VendorPaymentMethod>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/payment-methods');
      return (response.data as List)
          .map((json) => VendorPaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorPaymentMethod> create(String label, PlatformFile qrImage) async {
    final formData = FormData.fromMap({
      'label': label,
      'qrImage': MultipartFile.fromBytes(qrImage.bytes!, filename: qrImage.name),
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/payment-methods',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return VendorPaymentMethod.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int paymentMethodId) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/payment-methods/$paymentMethodId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
