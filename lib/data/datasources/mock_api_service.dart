import 'dart:math';

class MockApiService {
  final Random _random = Random();

  Future<bool> respondHelp({required String requestId, required String manualId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return _random.nextInt(100) >= 5;
  }

  Future<bool> addCommunityManual({required String manualId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    return _random.nextInt(100) >= 3;
  }

  Future<bool> publishHelpRequest({
    required String title,
    required String description,
    List<String> imagePaths = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _random.nextInt(100) >= 5;
  }
}
