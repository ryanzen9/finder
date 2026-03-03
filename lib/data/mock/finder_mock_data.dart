import 'package:finder/models/help_request.dart';
import 'package:finder/models/manual.dart';

class FinderMockData {
  static const tags = {
    'tv': ManualTag(id: 'tv', name: '影音'),
    'kitchen': ManualTag(id: 'kitchen', name: '厨房'),
    'camera': ManualTag(id: 'camera', name: '相机'),
    'car': ManualTag(id: 'car', name: '汽车'),
    'warranty': ManualTag(id: 'warranty', name: '保修中'),
  };

  static const manuals = <ManualItem>[
    ManualItem(
      id: 'm-001',
      title: '索尼 Bravia XR 电视',
      brand: 'Sony',
      model: 'X90L',
      room: '客厅',
      updatedAt: DateTime(2026, 2, 20),
      tags: [tags['tv']!, tags['warranty']!],
      coverGradient: 'blue',
      underWarranty: true,
    ),
    ManualItem(
      id: 'm-002',
      title: '博世 洗碗机 Series 6',
      brand: 'Bosch',
      model: 'Series 6',
      room: '厨房',
      updatedAt: DateTime(2026, 1, 18),
      tags: [tags['kitchen']!],
      coverGradient: 'indigo',
      underWarranty: false,
    ),
    ManualItem(
      id: 'm-003',
      title: '松下 Lumix S5 相机',
      brand: 'Panasonic',
      model: 'S5',
      room: '摄影包',
      updatedAt: DateTime(2026, 2, 3),
      tags: [tags['camera']!],
      coverGradient: 'orange',
      underWarranty: false,
    ),
    ManualItem(
      id: 'm-004',
      title: '特斯拉 Model 3 用户手册',
      brand: 'Tesla',
      model: 'Model 3',
      room: '车库',
      updatedAt: DateTime(2026, 2, 12),
      tags: [tags['car']!, tags['warranty']!],
      coverGradient: 'red',
      underWarranty: true,
    ),
  ];

  static const requests = <HelpRequest>[
    HelpRequest(
      id: 'r-001',
      author: '张伟',
      title: '需要飞利浦空气炸锅说明书',
      location: '上海市',
      timeText: '15 分钟前',
    ),
    HelpRequest(
      id: 'r-002',
      author: '林思意',
      title: '寻找徕卡镜头校准指南',
      location: '陆家嘴',
      timeText: '1 小时前',
    ),
  ];
}
