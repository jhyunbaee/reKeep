import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rekeep/login.dart';
import 'package:rekeep/widgets/custom_app_bar.dart';
import 'auth_service.dart';
import 'package:rekeep/constants/colors.dart';

class SettingProfile extends StatefulWidget {
  const SettingProfile({super.key});

  @override
  State<SettingProfile> createState() => _SettingProfileState();
}

class _SettingProfileState extends State<SettingProfile> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final double fieldHeight = 50;

  @override
  void dispose() {
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    // 로그인 안 됐거나 uid가 없는 경우 바로 로그인 페이지로 이동
    if (user == null) {
      // Future.microtask로 Navigator 호출 -> build 중에 안전하게 라우팅
      Future.microtask(() {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      });

      // 화면에는 일시적 로딩 표시
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 로그인 상태이면 기존 프로필 화면
    return Scaffold(
      appBar: customAppBar(
        context: context,
        title: "프로필",
        actions: [
          TextButton(
            onPressed: () async {
              final newNickname = _nicknameController.text.trim();
              if (newNickname.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("닉네임을 입력해주세요.")));
                return;
              }

              // 실제 저장 (중복 확인 다시 해도 됨)
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('nickname', isEqualTo: newNickname)
                  .get();

              if (query.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("이미 사용중인 닉네임입니다.")),
                );
                return;
              }

              // Firebase 저장
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .update({'nickname': newNickname});

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("닉네임이 저장되었습니다.")));
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text(
              "저장",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Firebase 문서가 없으면 로그인 페이지로 이동
          if (!snapshot.hasData || snapshot.data == null) {
            Future.microtask(() {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!;
          final name = data["name"] ?? "이름 없음";
          final nickname = data["nickname"] ?? "";
          final email = data["email"] ?? "";

          _passwordController.text = "********";
          _nicknameController.text = nickname;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 아바타
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        nickname.isNotEmpty ? nickname[0] : "?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 이름
                  const Text(
                    "이름",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: TextEditingController(text: name),
                    readOnly: true,
                    style: const TextStyle(color: Color(0xFFA8A8AA)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF2F3F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 닉네임
                  const Text(
                    "닉네임",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          readOnly: false,
                          style: const TextStyle(color: Color(0xFF000000)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF2F3F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(80, fieldHeight),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final newNickname = _nicknameController.text.trim();
                          if (newNickname.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("닉네임을 입력해주세요.")),
                            );
                            return;
                          }

                          // Firebase에서 중복 확인
                          final query = await FirebaseFirestore.instance
                              .collection('users')
                              .where('nickname', isEqualTo: newNickname)
                              .get();

                          if (query.docs.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("이미 사용중인 닉네임입니다.")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("사용 가능한 닉네임입니다.")),
                            );
                          }
                        },
                        child: const Text(
                          "중복확인",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 이메일
                  const Text(
                    "이메일",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: TextEditingController(text: email),
                    readOnly: true,
                    style: const TextStyle(color: Color(0xFFA8A8AA)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF2F3F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 비밀번호
                  const Text(
                    "비밀번호",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          readOnly: true,
                          style: const TextStyle(color: Color(0xFF000000)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF2F3F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(80, fieldHeight),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          elevation: 0,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => _ChangePasswordDialog(auth: auth),
                          );
                        },
                        child: const Text(
                          "변경",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),

                  // 로그아웃 | 회원탈퇴
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await auth.signOut();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "로그아웃",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 10,
                        color: AppColors.secondary,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.white,
                              contentPadding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              titlePadding: const EdgeInsets.all(5),
                              title: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.black,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                  ),
                                  const Text(
                                    "회원탈퇴",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "회원탈퇴시 회원 정보는 복구되지 않습니다.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: const Color(
                                              0xFFF5F5F5,
                                            ),
                                            foregroundColor: const Color(
                                              0xFFA8A8AA,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text(
                                            "아니오",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            "네",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await auth.deleteAccount();
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        child: const Text(
                          "회원탈퇴",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 비밀번호 변경 다이얼로그
class _ChangePasswordDialog extends StatefulWidget {
  final AuthService auth;
  const _ChangePasswordDialog({required this.auth});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("비밀번호 변경", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "현재 비밀번호"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "새 비밀번호"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "새 비밀번호 확인"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_newController.text != _confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("새 비밀번호가 일치하지 않습니다.")),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    // ✅ AuthService에 비밀번호 변경 메서드 만들어야 함
                    await widget.auth.updatePassword(
                      currentPassword: _currentController.text,
                      newPassword: _newController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("비밀번호가 변경되었습니다.")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("변경"),
        ),
      ],
    );
  }
}
