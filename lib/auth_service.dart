import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  User? get user => FirebaseAuth.instance.currentUser;

  User? currentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  void signUp({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String phone,
    required Function() onSuccess,
    required Function(String err) onError,
  }) async {
    if (email.isEmpty) {
      onError("이메일을 입력해 주세요.");
      return;
    } else if (password.isEmpty) {
      onError("비밀번호를 입력해 주세요.");
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;

      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "email": email,
        "name": name,
        "nickname": nickname,
        "phone": phone,
        "createdAt": Timestamp.now(),
      });

      onSuccess();
    } on FirebaseAuthException catch (e) {
      onError(e.message!);
    } catch (e) {
      onError(e.toString());
    }
  }

  void signIn({
    required String email,
    required String password,
    required Function() onSuccess,
    required Function(String err) onError,
  }) async {
    if (email.isEmpty) {
      onError('이메일을 입력해주세요.');
      return;
    } else if (password.isEmpty) {
      onError('비밀번호를 입력해주세요.');
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      onSuccess();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      onError(e.message!);
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception("최근 로그인 필요");
      } else {
        throw Exception(e.message);
      }
    }
  }

  // 🔹 비밀번호 변경 메서드 추가
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인된 유저가 없습니다.");

    try {
      // 🔑 현재 비밀번호로 재인증
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 🔑 새 비밀번호로 업데이트
      await user.updatePassword(newPassword);

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception("현재 비밀번호가 올바르지 않습니다.");
      } else if (e.code == 'requires-recent-login') {
        throw Exception("최근 로그인 필요");
      } else {
        throw Exception(e.message);
      }
    }
  }
}

// 닉네임 중복 확인
Future<bool> checkNicknameDuplicate(String nickname) async {
  final query = await FirebaseFirestore.instance
      .collection("users")
      .where("nickname", isEqualTo: nickname)
      .get();
  return query.docs.isNotEmpty;
}
