import 'package:flutter/widgets.dart';

class Flicker extends StatefulWidget {
  final Widget child;
  final double minOpacity;
  final double maxOpacity;
  final int durationInMillis;

  Flicker({
    @required this.child,
    this.minOpacity = 0.0,
    this.maxOpacity = 1.0,
    this.durationInMillis = 800,
  });

  @override
  State<StatefulWidget> createState() => _FlickerState();
}

class _FlickerState extends State<Flicker> {
  double _opacity;
  bool _disposed = false;

  //Invert animated opacity each duration + 100 milliseconds  seconds
  void _fadeHelper() async {
    while (!_disposed) {
      await Future.delayed(Duration(milliseconds: widget.durationInMillis + 100), () {
        if (!_disposed) {
          setState(() {
            if (_opacity == widget.minOpacity) {
              _opacity = widget.maxOpacity;
            } else {
              _opacity = widget.minOpacity;
            }
          });
        }
      });
    }
  }

  @override
  void initState() {
    _opacity = widget.maxOpacity;
    _fadeHelper();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: widget.durationInMillis),
      curve: Curves.linear,
      opacity: _opacity,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
