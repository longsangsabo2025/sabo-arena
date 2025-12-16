// Load Testing Integration Tests
// Tests that load testing infrastructure is properly set up

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Load Testing Infrastructure', () {
    test('k6 scenarios file exists', () {
      final file = File('scripts/load_testing/k6_scenarios.js');
      expect(file.existsSync(), isTrue, reason: 'k6_scenarios.js should exist');
    });

    test('Locust scenarios file exists', () {
      final file = File('scripts/load_testing/locustfile.py');
      expect(file.existsSync(), isTrue, reason: 'locustfile.py should exist');
    });

    test('Load testing README exists', () {
      final file = File('scripts/load_testing/README.md');
      expect(file.existsSync(), isTrue, reason: 'README.md should exist');
    });

    test('Baseline metrics template exists', () {
      final file = File('scripts/load_testing/baseline_metrics.json');
      expect(file.existsSync(), isTrue, reason: 'baseline_metrics.json should exist');
    });

    test('Performance report template exists', () {
      final file = File('scripts/load_testing/performance_report.md');
      expect(file.existsSync(), isTrue, reason: 'performance_report.md should exist');
    });

    test('Load test results template exists', () {
      final file = File('scripts/load_testing/load_test_results.md');
      expect(file.existsSync(), isTrue, reason: 'load_test_results.md should exist');
    });
  });
}

