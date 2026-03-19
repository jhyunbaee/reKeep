import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rekeep/constants/colors.dart';
import 'auth_service.dart';
import 'login.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

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

    return FutureBuilder<Map<String, dynamic>?>(
      future: user != null ? getUserData(user.uid) : null,
      builder: (context, snapshot) {
        String name = "로그인 해주세요";
        String email = "로그인 후 이용 가능합니다";

        if (user != null && snapshot.hasData) {
          final data = snapshot.data!;
          name = data["name"] ?? "이름 없음";
          email = data["email"] ?? "";
        }

        return ListView(
          children: [
            /// 프로필 영역
            GestureDetector(
              onTap: () {
                if (user == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: user == null
                          ? Colors.grey[200]
                          : AppColors.primary,
                      child: user == null
                          ? const Icon(Icons.person, color: AppColors.secondary)
                          : Text(
                              name.isNotEmpty ? name[0] : "?",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 메뉴 리스트
            _buildMenuItem("공지사항", Icons.campaign, () {}),
            _buildMenuItem("도움말", Icons.help_outline, () {}),
            _buildMenuItem("알림 설정", Icons.notifications_none, () {}),

            /// 로그인 상태일 때만 로그아웃 표시
            if (user != null) ...[
              const Divider(),
              _buildMenuItem("로그아웃", Icons.logout, () async {
                await auth.signOut();
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
