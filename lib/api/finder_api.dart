import 'package:finder/models/help_request.dart';
import 'package:finder/models/manual.dart';

abstract class IFinderApi {
  Future<List<ManualItem>> getLibrary({String? keyword});
  Future<List<HelpRequest>> getHelpRequests();
  Future<List<ManualItem>> searchCommunity(String keyword);
}
