//路由动画设计
import 'package:flutter/material.dart';
class CustomeRout extends PageRouteBuilder {
  final Widget widget;
  CustomeRout(this.widget,double x)
      : super(
            transitionDuration: Duration(milliseconds: 600),
            pageBuilder: (
              BuildContext context,
              Animation<double> animation1,
              Animation<double> animation2,
            ) {
              return widget;
            },
            transitionsBuilder: (BuildContext context,
                Animation<double> animation1,
                Animation<double> animation2,
                Widget child) {
              return SlideTransition(
                position: Tween<Offset>(
                        begin: Offset(x, 0.0), end: Offset(0.0, 0.0))
                    .animate(CurvedAnimation(
                        parent: animation1, curve: Curves.fastOutSlowIn)),
                child: child,
              );
            });
}
