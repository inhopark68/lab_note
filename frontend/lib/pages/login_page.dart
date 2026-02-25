import 'package:flutter/material.dart';

/// 로그인 생략 모드: 이 화면은 사용하지 않습니다.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('로그인 생략 모드입니다.')),
    );
  }
}
