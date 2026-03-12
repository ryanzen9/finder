import 'dart:async';

import 'package:finder/api/finder_api.dart';
import 'package:finder/data/mock/finder_mock_data.dart';
import 'package:finder/models/help_request.dart';
import 'package:finder/models/manual.dart';

class FinderMockApi implements IFinderApi {
  const FinderMockApi();

  @override
  Future<List<ManualItem>> getLibrary({String? keyword}) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    var list = FinderMockData.manuals;

    if (keyword != null && keyword.trim().isNotEmpty) {
      final q = keyword.toLowerCase();
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.brand.toLowerCase().contains(q) ||
            e.model.toLowerCase().contains(q);
      }).toList();
    }


    return list;
  }

  @override
  Future<List<HelpRequest>> getHelpRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return FinderMockData.requests;
  }

  @override
  Future<List<ManualItem>> searchCommunity(String keyword) async {
    return getLibrary(keyword: keyword);
  }
}
