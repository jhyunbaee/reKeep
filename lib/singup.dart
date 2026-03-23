import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rekeep/constants/colors.dart';
import '../auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    nicknameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "회원가입",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "이름",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "이름",
                  filled: true,
                  fillColor: AppColors.fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // 둥근 모서리
                    borderSide: BorderSide.none, // 테두리 제거
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "닉네임",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  // 🔹 닉네임 텍스트필드
                  Expanded(
                    child: SizedBox(
                      child: TextField(
                        controller: nicknameController,
                        decoration: InputDecoration(
                          hintText: "닉네임",
                          filled: true,
                          fillColor: AppColors.fieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 🔹 중복확인 버튼
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                      onPressed: () async {
                        final nickname = nicknameController.text.trim();
                        if (nickname.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("닉네임을 입력해주세요.")),
                          );
                          return;
                        }

                        final exists = await checkNicknameDuplicate(nickname);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              exists ? "이미 사용 중인 닉네임입니다." : "사용 가능한 닉네임입니다.",
                            ),
                          ),
                        );
                      },
                      child: const Text("중복확인"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "휴대전화",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: "휴대전화('-'제외 11자리)",
                  filled: true,
                  fillColor: AppColors.fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // 둥근 모서리
                    borderSide: BorderSide.none, // 테두리 제거
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "이메일",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "이메일",
                  filled: true,
                  fillColor: AppColors.fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // 둥근 모서리
                    borderSide: BorderSide.none, // 테두리 제거
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "비밀번호",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "비밀번호(6자리 이상)",
                  filled: true,
                  fillColor: AppColors.fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    context.read<AuthService>().signUp(
                      email: emailController.text,
                      password: passwordController.text,
                      name: nameController.text,
                      nickname: nicknameController.text,
                      phone: phoneController.text,
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("회원가입 성공")),
                        );

                        Navigator.pop(context);
                      },
                      onError: (err) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err)));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
