import 'package:finder/data/datasources/mock_api_service.dart';

class ExploreViewModel {
  ExploreViewModel({MockApiService? api}) : _api = api ?? MockApiService();

  final MockApiService _api;

  Future<bool> respondHelp({required String requestId, required String manualId}) {
    return _api.respondHelp(requestId: requestId, manualId: manualId);
  }

  Future<bool> addCommunityManual({required String manualId}) {
    return _api.addCommunityManual(manualId: manualId);
  }

  Future<bool> publishHelpRequest({
    required String title,
    required String description,
    String? imagePath,
  }) {
    return _api.publishHelpRequest(
      title: title,
      description: description,
      imagePath: imagePath,
    );
  }
}
