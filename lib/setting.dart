import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rekeep/constants/colors.dart';
import 'auth_service.dart';
import 'package:rekeep/login.dart';
import 'package:rekeep/setting_profile.dart';

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

    if (user == null) {
      // 로그아웃 상태
      return const Scaffold(body: Center(child: Text("로그인 해주세요")));
    }

    // StreamBuilder로 실시간 구독
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(), // 실시간 구독
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data();
        final nickname = data?["nickname"] ?? "이름 없음";
        final email = data?["email"] ?? "";

        return ListView(
          children: [
            /// 프로필 영역
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingProfile()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        nickname.isNotEmpty ? nickname[0] : "?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                nickname,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                          Text(
                            email,
                            style: const TextStyle(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 메뉴 리스트
            _buildMenuItem("알림 설정", () {}),
            _buildMenuItem("앱 잠금", () {}),
            _buildMenuItem("언어 설정", () {}),
            _buildMenuItem("백업", () {}),
            _buildMenuItem("데이터 및 저장공간", () {}),
            _buildMenuItem("라이트/다크모드", () {}),
            Container(height: 10, color: const Color(0xFFF2F2F7)),
            _buildMenuItem("사용방법", () {}),
            _buildMenuItem("앱 별점 남기기", () {}),
            _buildMenuItem("피드백 / 문의하기", () {}),
            Container(height: 10, color: const Color(0xFFF2F2F7)),
            _buildMenuItem("앱 버전", () {}),
            _buildMenuItem("공지사항", () {}),
            _buildMenuItem("고객센터", () {}),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      leading: null,
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
