import 'package:flutter/material.dart';

class CustomerSliverAppBarDelegate extends StatelessWidget {
  const CustomerSliverAppBarDelegate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar(
          //   expandedHeight: 200, // 展开高度
          //   collapsedHeight: kToolbarHeight, // 收起高度（可选）
          //   pinned: true,   // 是否吸顶
          //   floating: false,// 是否“轻拉就出现”
          //   snap: false,    // 配合 floating 使用，是否自动吸附
          //   stretch: false,// 下拉是否可拉伸
          //  )
          SliverAppBar(
            expandedHeight: 200,
            pinned: true, // 收起后仍然吸在顶部
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Sliver App Bar'),
              background: Image.network(
                'https://picsum.photos/800/400',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(title: Text('Item $index')),
              childCount: 50,
            ),
          ),
        ],
      ),
    );
  }
}
