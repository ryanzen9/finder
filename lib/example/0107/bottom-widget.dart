import 'package:flutter/material.dart';

/// 封装组件

// 事件回调
typedef ButtonCallback = void Function();

// 按钮类型
enum ButtonType { DEFAULT, PRIMARY, SUCCESS, INFO, WARN, DANGER }

class CustomerButtom extends StatefulWidget {
  final String text; // 按钮文字
  final TextStyle? style; // 文字样式
  final EdgeInsets? margin; // 按钮外间距
  final EdgeInsets? padding; // 按钮内间距
  final Widget? icon; // 按钮的图标
  final Border? border; // 按钮边框
  final BorderRadius? radius; // 按钮的圆角
  final ButtonType type; // 按钮类型
  final ButtonCallback? onTap; // 按钮的点击事件

  // 当一个对象中所有属性都是 final 的时候，可以在构造前面添加 const 关键字，反之则会报错
  const CustomerButtom({
    super.key,
    required this.text,
    this.style,
    this.margin,
    this.padding,
    this.icon,
    this.border,
    this.radius,
    this.type = ButtonType.DEFAULT, // 这里给它一个默认类型
    this.onTap,
  });

  @override
  State<CustomerButtom> createState() => _CustomerButtomState();
}

class _CustomerButtomState extends State<CustomerButtom> {
  Color? _bgColor;
  Color? _textColor;

  @override
  void initState() {
    super.initState();
    // 初始化按钮样式
    _switchStyle(active: false);
  }

  @override
  Widget build(BuildContext context) {
    // 按钮内样式
    Widget body = DefaultTextStyle(
      style: TextStyle(color: _textColor),
      child: Text(widget.text, style: widget.style),
    );

    if (widget.icon != null) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标（带默认样式）
          IconTheme(
            data: IconThemeData(color: _textColor),
            child: widget.icon!,
          ),
          const SizedBox(width: 5), // 5 像素的左右间隔
          // 按钮文本
          body,
        ],
      );
    }

    // 按钮的动态样式
    BoxDecoration decoration = BoxDecoration(
      border: widget.border,
      boxShadow: [
        BoxShadow(
          color: _bgColor!.withAlpha(120),
          blurRadius: 10,
          offset: const Offset(0, 5),
          spreadRadius: 1,
        ),
      ],
      borderRadius: widget.radius ?? BorderRadius.circular(100),

      color: _bgColor,
    );

    body = Container(
      decoration: decoration,
      margin: widget.margin,
      padding: widget.padding,
      height: 45,
      child: body,
    );

    // 监听点击事件
    return GestureDetector(
      onTapDown: (e) => _switchStyle(active: true),
      onTapUp: (e) => _resetStyle(),
      onTapCancel: _resetStyle,
      child: body,
    );
  }

  void _resetStyle() {
    // 恢复默认样式
    _switchStyle(active: false);
    // 触发点击事件回调
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  // 动态选择当前状态下的按钮应该渲染什么样的颜色以及样式
  void _switchStyle({required bool active}) {
    switch (widget.type) {
      case ButtonType.DEFAULT:
        _bgColor = active ? Colors.grey[800] : Colors.grey[900];
        _textColor = Colors.white;
        break;
      case ButtonType.PRIMARY:
        _bgColor = active ? Colors.blueAccent[400] : Colors.blueAccent[700];
        _textColor = Colors.white;
        break;
      case ButtonType.SUCCESS:
        _bgColor = active ? Colors.green[800] : Colors.green[900];
        _textColor = Colors.white;
        break;
      case ButtonType.INFO:
        _bgColor = active ? Colors.cyan[800] : Colors.cyan[900];
        _textColor = Colors.white;
        break;
      case ButtonType.WARN:
        _bgColor = active ? Colors.yellow[800] : Colors.yellow[900];
        _textColor = Colors.white;
        break;
      case ButtonType.DANGER:
        _bgColor = active ? Colors.red[400] : Colors.red[700];
        _textColor = Colors.white;
        break;
    }
    if (super.mounted) {
      super.setState(() {});
    }
  }
}

class ButtonPage extends StatefulWidget {
  const ButtonPage({super.key});

  @override
  State<StatefulWidget> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<ButtonPage> {
  String? message;

  @override
  void initState() {
    super.initState();
    message = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message == null ? "啥也没有" : "你点击了: $message 按钮",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // ========================================================== //
              CustomerButtom(
                padding: EdgeInsets.all(8.0),
                text: "我是按钮1",
                icon: const Icon(Icons.home),
                type: ButtonType.DEFAULT,
                onTap: btnClick,
              ),
              const SizedBox(height: 50),
              CustomerButtom(
                padding: EdgeInsets.all(8.0),
                text: "我是按钮2",
                icon: const Icon(Icons.home),
                type: ButtonType.PRIMARY,
                onTap: btnClick,
              ),
              const SizedBox(height: 50),
              CustomerButtom(
                padding: EdgeInsets.all(8.0),
                text: "我是按钮3",
                icon: const Icon(Icons.home),
                type: ButtonType.SUCCESS,
                onTap: btnClick,
              ),
              // ========================================================== //
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            border: const Border(
              top: BorderSide(color: Colors.grey, width: 0.1),
            ),
          ),
          child: const Text("编码中..."),
        ),
      ],
    );
  }

  void btnClick() {
    super.setState(() {
      message = "点击了按钮";
    });
  }
}
