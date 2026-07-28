import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../../models/budget.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend.

class BudgetApiException implements Exception {
  final String message;
  const BudgetApiException(this.message);
}

class BudgetApiService {
  BudgetApiService._();
  static final BudgetApiService instance = BudgetApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  /// Explicit create/update — what the onboarding wizard calls. Generates
  /// categories from the template only if no budget exists yet.
  Future<Budget> initBudget(
    String accessToken, {
    required double total,
    required String currency,
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/budget',
        data: {
          'total_amount': total,
          'currency': currency,
          'service_categories': serviceCategories,
          'custom_items': customItems?.map((i) => {'name': i.name, 'amount': i.amount}).toList(),
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return Budget.fromJson(data['budget'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw BudgetApiException(_extractError(e));
    }
  }

  /// Returns `null` if the couple has no budget yet (404 — expected).
  Future<Budget?> fetchBudget(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/budget',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return Budget.fromJson(data['budget'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw BudgetApiException(_extractError(e));
    }
  }

  Future<BudgetCategory> updateCategoryAllocation(
      String accessToken, String categoryId, double allocatedAmount) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/budget/categories/$categoryId',
        data: {'allocated_amount': allocatedAmount},
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return BudgetCategory.fromJson(data['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw BudgetApiException(_extractError(e));
    }
  }

  Future<Expense> addExpense(
    String accessToken, {
    required String categoryName,
    required double amount,
    required String description,
    String? vendorId,
    String? vendorName,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) async {
    try {
      final form = FormData.fromMap({
        'category_name': categoryName,
        'amount': amount,
        'description': description,
        'vendor_id': ?vendorId,
        'vendor_name': ?vendorName,
        if (receiptBytes != null)
          'receipt': MultipartFile.fromBytes(receiptBytes, filename: receiptFilename ?? 'receipt.jpg'),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/budget/expenses',
        data: form,
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return Expense.fromJson(data['expense'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw BudgetApiException(_extractError(e));
    }
  }

  Future<void> removeExpense(String accessToken, String expenseId) async {
    try {
      await _dio.delete('/api/budget/expenses/$expenseId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw BudgetApiException(_extractError(e));
    }
  }

  Future<BudgetCustomItem> addCustomItem(String accessToken, String name, double amount) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/budget/custom-items',
        data: {'name': name, 'amount': amount},
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return BudgetCustomItem.fromJson(data['custom_item'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw BudgetApiException(_extractError(e));
    }
  }

  Future<void> removeCustomItem(String accessToken, String itemId) async {
    try {
      await _dio.delete('/api/budget/custom-items/$itemId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw BudgetApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}
