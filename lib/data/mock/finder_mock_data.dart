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
    ManualItem(id: 'm-001', title: '索尼 Bravia XR 电视', brand: 'Sony', model: 'X90L', room: '客厅', updatedAt: DateTime(2026, 2, 20), tags: [tags['tv']!, tags['warranty']!], coverGradient: 'blue', underWarranty: true),
    ManualItem(id: 'm-002', title: '博世 洗碗机 Series 6', brand: 'Bosch', model: 'Series 6', room: '厨房', updatedAt: DateTime(2026, 1, 18), tags: [tags['kitchen']!], coverGradient: 'indigo', underWarranty: false),
    ManualItem(id: 'm-003', title: '松下 Lumix S5 相机', brand: 'Panasonic', model: 'S5', room: '摄影包', updatedAt: DateTime(2026, 2, 3), tags: [tags['camera']!], coverGradient: 'orange', underWarranty: false),
    ManualItem(id: 'm-004', title: '特斯拉 Model 3 用户手册', brand: 'Tesla', model: 'Model 3', room: '车库', updatedAt: DateTime(2026, 2, 12), tags: [tags['car']!, tags['warranty']!], coverGradient: 'red', underWarranty: true),
    ManualItem(id: 'm-005', title: '小米空气净化器 4 Pro', brand: 'Xiaomi', model: '4 Pro', room: '卧室', updatedAt: DateTime(2026, 2, 1), tags: [tags['kitchen']!], coverGradient: 'green', underWarranty: true),
    ManualItem(id: 'm-006', title: '戴森 V12 Detect Slim', brand: 'Dyson', model: 'V12', room: '玄关', updatedAt: DateTime(2026, 1, 30), tags: [tags['kitchen']!], coverGradient: 'purple', underWarranty: false),
    ManualItem(id: 'm-007', title: '华为路由 AX3 Pro', brand: 'Huawei', model: 'AX3 Pro', room: '书房', updatedAt: DateTime(2026, 1, 25), tags: [tags['tv']!], coverGradient: 'blue', underWarranty: false),
    ManualItem(id: 'm-008', title: '海尔 变频冰箱 BCD-470', brand: 'Haier', model: 'BCD-470', room: '厨房', updatedAt: DateTime(2026, 2, 5), tags: [tags['kitchen']!, tags['warranty']!], coverGradient: 'green', underWarranty: true),
    ManualItem(id: 'm-009', title: 'LG OLED C3 用户指南', brand: 'LG', model: 'OLED C3', room: '客厅', updatedAt: DateTime(2026, 2, 10), tags: [tags['tv']!], coverGradient: 'red', underWarranty: true),
    ManualItem(id: 'm-010', title: '佳能 EOS R6 Mark II', brand: 'Canon', model: 'R6 II', room: '摄影包', updatedAt: DateTime(2026, 2, 14), tags: [tags['camera']!], coverGradient: 'orange', underWarranty: true),
    ManualItem(id: 'm-011', title: '尼康 Z6 II 快速手册', brand: 'Nikon', model: 'Z6 II', room: '摄影包', updatedAt: DateTime(2026, 1, 19), tags: [tags['camera']!], coverGradient: 'purple', underWarranty: false),
    ManualItem(id: 'm-012', title: '奥迪 A4L 用户手册', brand: 'Audi', model: 'A4L', room: '车库', updatedAt: DateTime(2026, 2, 7), tags: [tags['car']!], coverGradient: 'indigo', underWarranty: false),
    ManualItem(id: 'm-013', title: '比亚迪 海豹 DM-i 用车指南', brand: 'BYD', model: 'Seal DM-i', room: '车库', updatedAt: DateTime(2026, 2, 8), tags: [tags['car']!, tags['warranty']!], coverGradient: 'blue', underWarranty: true),
    ManualItem(id: 'm-014', title: '方太蒸烤一体机 KQD50', brand: 'Fotile', model: 'KQD50', room: '厨房', updatedAt: DateTime(2026, 1, 11), tags: [tags['kitchen']!], coverGradient: 'orange', underWarranty: false),
    ManualItem(id: 'm-015', title: '美的洗衣机 MG100V11', brand: 'Midea', model: 'MG100V11', room: '阳台', updatedAt: DateTime(2026, 1, 9), tags: [tags['kitchen']!], coverGradient: 'green', underWarranty: false),
    ManualItem(id: 'm-016', title: '飞利浦空气炸锅 HD9650', brand: 'Philips', model: 'HD9650', room: '厨房', updatedAt: DateTime(2026, 2, 16), tags: [tags['kitchen']!, tags['warranty']!], coverGradient: 'red', underWarranty: true),
    ManualItem(id: 'm-017', title: '大疆 Mini 4 Pro 快速入门', brand: 'DJI', model: 'Mini 4 Pro', room: '书房', updatedAt: DateTime(2026, 2, 2), tags: [tags['camera']!], coverGradient: 'purple', underWarranty: true),
    ManualItem(id: 'm-018', title: 'Apple TV 4K 使用手册', brand: 'Apple', model: 'TV 4K', room: '客厅', updatedAt: DateTime(2026, 2, 4), tags: [tags['tv']!], coverGradient: 'indigo', underWarranty: false),
    ManualItem(id: 'm-019', title: '任天堂 Switch OLED 指南', brand: 'Nintendo', model: 'Switch OLED', room: '客厅', updatedAt: DateTime(2026, 1, 29), tags: [tags['tv']!], coverGradient: 'red', underWarranty: false),
    ManualItem(id: 'm-020', title: '九号电动车 N90C 说明书', brand: 'Segway', model: 'N90C', room: '车位', updatedAt: DateTime(2026, 2, 11), tags: [tags['car']!], coverGradient: 'green', underWarranty: true),
  ];

  static const requests = <HelpRequest>[
    HelpRequest(id: 'r-001', author: '张伟', title: '需要飞利浦空气炸锅说明书', location: '上海市', timeText: '15 分钟前'),
    HelpRequest(id: 'r-002', author: '林思意', title: '寻找徕卡镜头校准指南', location: '陆家嘴', timeText: '1 小时前'),
    HelpRequest(id: 'r-003', author: '周婷', title: '想要 LG OLED 77 使用技巧', location: '静安寺', timeText: '今天'),
    HelpRequest(id: 'r-004', author: '王磊', title: '博世洗碗机报警 E15 怎么处理？', location: '徐汇', timeText: '2 小时前'),
  ];
}
