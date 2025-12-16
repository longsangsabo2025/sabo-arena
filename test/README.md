# SABO Arena Test Suite

## Test Structure

```
test/
├── unit/              # Unit tests for models, services
├── integration/      # Integration tests for flows
├── performance/      # Performance and load tests
└── widget/           # Widget tests
```

## Running Tests

### All Tests
```bash
flutter test
```

### Unit Tests Only
```bash
flutter test test/unit/
```

### Integration Tests
```bash
flutter test test/integration/
```

### Performance Tests
```bash
flutter test test/performance/
```

### With Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Coverage Goals

- **Critical Services**: 80%+ coverage
  - tournament_service.dart
  - user_service.dart
  - payment_service.dart
  - bracket_service.dart

- **Models**: 90%+ coverage
  - Tournament
  - UserProfile
  - Match
  - Club

- **Integration Tests**: All critical user journeys
  - Tournament creation → Registration → Completion
  - User registration → Profile setup
  - Payment flow

## Writing Tests

### Unit Test Example
```dart
test('service should handle error gracefully', () async {
  // Arrange
  when(mockService.method()).thenThrow(Exception());
  
  // Act & Assert
  expect(() => service.method(), throwsA(isA<Exception>()));
});
```

### Integration Test Example
```dart
testWidgets('complete user flow', (tester) async {
  // Navigate through app
  await tester.pumpAndSettle();
  // Verify state
  expect(find.text('Expected'), findsOneWidget);
});
```

## CI/CD Integration

Tests run automatically on:
- Pull requests
- Before deployment
- Nightly builds

## Coverage Reports

Coverage reports are generated in `coverage/html/index.html`

