class Session {
  Session._();
  static final Session instance = Session._();

  // 로그인 생략 모드: 토큰 없음
  bool get isLoggedIn => false;
  String? get accessToken => null;

  Future<void> load() async {}
  Future<void> saveToken(String token) async {}
  Future<void> clear() async {}
}
