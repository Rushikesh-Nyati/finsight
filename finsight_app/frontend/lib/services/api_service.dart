import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class ApiService {
  // IMPORTANT: Replace with your PC's IP address
  static const String baseUrl =
      'http://10.251.221.148:5000'; // Added :5000 port

  // Get Initial Budget Suggestion
  static Future<BudgetSuggestion> getInitialBudget(
      Map<String, List<double>> monthlySpending) async {
    try {
      print('📊 API: Requesting initial budget');

      final response = await http.post(
        Uri.parse('$baseUrl/initial-budget'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'monthly_spending': monthlySpending}),
      );

      print('Initial budget response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return BudgetSuggestion.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to get budget suggestion: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting budget suggestion: $e');
      rethrow;
    }
  }

  // Get Spending Forecast (30 days)
  static Future<ForecastData> getForecast(
      List<Map<String, dynamic>> dailySpends) async {
    try {
      print('\n${'=' * 60}');
      print('📡 API Service: Sending forecast request');
      print('=' * 60);
      print('URL: $baseUrl/forecast');
      print('Daily spends count: ${dailySpends.length}');
      print('Sample data: ${dailySpends.take(2).toList()}');

      final url = Uri.parse('$baseUrl/forecast');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'daily_spends': dailySpends}),
      );

      print('Response status: ${response.statusCode}');
      print(
          'Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ForecastData.fromJson(jsonData);
      } else {
        final errorBody = response.body;
        throw Exception(
            'Failed to get forecast: ${response.statusCode}\n$errorBody');
      }
    } catch (e) {
      print('❌ Error in getForecast: $e');
      rethrow;
    }
  }

  // Get Savings Plan
  static Future<SavingsPlan> getSavingsPlan({
    required double goalAmount,
    required int timelineMonths,
    required Map<String, double> averageSpending,
  }) async {
    try {
      print('💰 API: Requesting savings plan');
      print('Goal: ₹$goalAmount over $timelineMonths months');

      final response = await http.post(
        Uri.parse('$baseUrl/savings-plan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'goal_amount': goalAmount,
          'timeline_months': timelineMonths,
          'average_spending': averageSpending,
        }),
      );

      print('Savings plan response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return SavingsPlan.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get savings plan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting savings plan: $e');
      rethrow;
    }
  }

  // Health Check
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}
