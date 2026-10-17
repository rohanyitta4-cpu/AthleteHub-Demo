# ATHLETEHUB Testing Suite

This directory contains comprehensive tests for the ATHLETEHUB application, including unit tests, integration tests, Firebase emulator tests, and security rules tests.

## 📁 Test Structure

```
test/
├── README.md                    # This file
├── run_all_tests.sh            # Main test runner script
├── emulator_test.dart          # Flutter integration tests
├── unit/
│   └── repo_test.dart          # Repository unit tests
├── functions_test.js           # Cloud Functions tests
├── security_rules_test.js      # Security rules tests
└── run_emulator_tests.dart     # Emulator test runner
```

## 🧪 Test Types

### 1. Flutter Unit Tests
- **Location**: `test/unit/repo_test.dart`
- **Purpose**: Test individual repository methods and data models
- **Coverage**: TeamRepo, RosterRepo, GameRepo, StatsRepo
- **Run**: `flutter test test/unit/`

### 2. Flutter Integration Tests
- **Location**: `test/emulator_test.dart`
- **Purpose**: Test complete workflows with Firebase emulators
- **Coverage**: Team management, game creation, data flow
- **Run**: `flutter test test/emulator_test.dart`

### 3. Cloud Functions Tests
- **Location**: `test/functions_test.js`
- **Purpose**: Test Cloud Functions behavior with emulators
- **Coverage**: onTeamGameWrite, onRosterChange, data aggregation
- **Run**: `node test/functions_test.js`

### 4. Security Rules Tests
- **Location**: `test/security_rules_test.js`
- **Purpose**: Test Firestore security rules enforcement
- **Coverage**: RBAC, permission checks, access control
- **Run**: `node test/security_rules_test.js`

## 🚀 Running Tests

### Prerequisites

1. **Flutter**: Install Flutter SDK
2. **Node.js**: Install Node.js (v18+)
3. **Firebase CLI**: Install Firebase CLI
4. **Dependencies**: Install project dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install Node.js dependencies
cd functions && npm install && cd ..

# Install Firebase CLI
npm install -g firebase-tools
```

### Quick Start

Run all tests with a single command:

```bash
./test/run_all_tests.sh
```

### Individual Test Suites

#### Flutter Tests Only
```bash
./test/run_all_tests.sh --flutter
```

#### Firebase Emulator Tests Only
```bash
./test/run_all_tests.sh --emulator
```

#### Manual Test Execution

**Flutter Unit Tests:**
```bash
flutter test test/unit/
```

**Flutter Integration Tests:**
```bash
flutter test test/emulator_test.dart
```

**Cloud Functions Tests:**
```bash
# Start emulators
firebase emulators:start --only firestore,functions,auth &

# Run tests
node test/functions_test.js

# Stop emulators
pkill -f firebase
```

**Security Rules Tests:**
```bash
# Start Firestore emulator
firebase emulators:start --only firestore &

# Run tests
node test/security_rules_test.js

# Stop emulator
pkill -f firebase
```

## 📋 Test Scenarios

### Team Management Workflow
1. **Coach creates team** → Team document created
2. **Coach adds player to roster** → Roster entry created, user linkedTeams updated
3. **Player views team** → Access granted based on role
4. **Unauthorized user tries to access** → Access denied

### Game Management Workflow
1. **Coach creates game** → Game document created
2. **Cloud Function triggers** → Team totals and player totals updated
3. **Coach updates game stats** → Delta calculation, totals adjusted
4. **Coach deletes game** → Totals decremented correctly

### Security Rules Validation
1. **Coach permissions** → Can create/edit teams, games, roster
2. **Player permissions** → Can read team data, cannot edit
3. **Unauthorized access** → All operations denied
4. **Admin permissions** → Full access to all resources

## 🔧 Test Configuration

### Firebase Emulator Configuration
The emulators are configured in `firebase.json`:

```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

### Test Data
Test data is defined in each test file with consistent IDs:
- `teamId`: 'team-test-123'
- `seasonId`: 'season-2024'
- `gameId`: 'game-test-123'
- `coachId`: 'coach-test-123'
- `playerId`: 'player-test-123'

## 🐛 Debugging Tests

### Common Issues

1. **Emulators not starting**
   ```bash
   # Check if ports are available
   lsof -i :8080,5001,9099
   
   # Kill existing processes
   pkill -f firebase
   ```

2. **Permission denied errors**
   ```bash
   # Make test script executable
   chmod +x test/run_all_tests.sh
   ```

3. **Flutter test failures**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter test
   ```

4. **Node.js dependency issues**
   ```bash
   # Clear npm cache
   npm cache clean --force
   
   # Reinstall dependencies
   rm -rf node_modules package-lock.json
   npm install
   ```

### Debug Mode

Run tests with verbose output:

```bash
# Flutter tests with verbose output
flutter test --verbose

# Node.js tests with debug output
DEBUG=* node test/functions_test.js
```

## 📊 Test Coverage

### Current Coverage
- ✅ **Repository Methods**: 100% of CRUD operations
- ✅ **Data Models**: All model serialization/deserialization
- ✅ **Cloud Functions**: Core aggregation logic
- ✅ **Security Rules**: RBAC enforcement
- ✅ **Integration Workflows**: End-to-end scenarios

### Coverage Goals
- 🎯 **Unit Tests**: 90%+ code coverage
- 🎯 **Integration Tests**: All major user workflows
- 🎯 **Security Tests**: All permission scenarios
- 🎯 **Performance Tests**: Large dataset handling

## 🔄 Continuous Integration

### GitHub Actions
Tests run automatically on:
- Push to `main` branch
- Pull requests
- Scheduled runs

### Local CI
Run the same tests locally:

```bash
# Full CI pipeline
./test/run_all_tests.sh

# Check specific components
flutter analyze
flutter test
node test/functions_test.js
```

## 📝 Writing New Tests

### Flutter Tests
```dart
test('should create team successfully', () async {
  final team = Team(/* ... */);
  await teamRepo.createTeam(team);
  
  final created = await teamRepo.getTeam(team.teamId);
  expect(created, isNotNull);
  expect(created!.name, equals(team.name));
});
```

### Cloud Functions Tests
```javascript
test('onTeamGameWrite should update totals', async () => {
  // Create test data
  await db.collection('teams').doc(teamId).set(teamData);
  
  // Trigger function
  await db.collection('teams').doc(teamId)
    .collection('seasons').doc(seasonId)
    .collection('games').doc(gameId).set(gameData);
  
  // Verify results
  const totals = await db.collection('teams').doc(teamId)
    .collection('seasons').doc(seasonId)
    .collection('stats').doc('totals').get();
  
  expect(totals.exists).toBe(true);
});
```

### Security Rules Tests
```javascript
test('player cannot create team', async () => {
  try {
    await db.collection('teams').doc('unauthorized').set({
      teamId: 'unauthorized',
      coachIds: ['player123'],
    });
    fail('Should have thrown permission error');
  } catch (error) {
    expect(error.code).toBe('permission-denied');
  }
});
```

## 🎯 Best Practices

### Test Organization
1. **Group related tests** using `group()`
2. **Use descriptive test names** that explain the scenario
3. **Set up test data** in `setUp()` methods
4. **Clean up** after each test

### Test Data
1. **Use consistent test IDs** across all tests
2. **Create realistic test data** that matches production
3. **Clean up test data** after each test run
4. **Use factories** for complex test data creation

### Assertions
1. **Be specific** in assertions
2. **Test edge cases** and error conditions
3. **Verify side effects** (e.g., Cloud Function triggers)
4. **Check data integrity** after operations

## 📚 Additional Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Firestore Security Rules Testing](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Cloud Functions Testing](https://firebase.google.com/docs/functions/unit-testing)

## 🤝 Contributing

When adding new tests:

1. **Follow naming conventions**
2. **Add to appropriate test suite**
3. **Update this documentation**
4. **Ensure tests pass locally**
5. **Add to CI pipeline if needed**

## 📞 Support

For test-related issues:

1. Check this documentation
2. Review test logs for specific errors
3. Verify prerequisites are installed
4. Check Firebase emulator status
5. Contact the development team

---

**Happy Testing! 🧪✨**