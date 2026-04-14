import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rekeep/bottom_menu_bar.dart';
import 'package:rekeep/asset.dart';
import 'package:rekeep/analysis.dart';
import 'package:rekeep/setting.dart';
import 'package:rekeep/widgets/custom_app_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rekeep/constants/colors.dart';
import 'auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SizedBox(),
    const Asset(),
    const Analysis(),
    const Setting(),
  ];

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String formatMoney(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  // --- 실시간 계산 로직 ---
  Map<String, int> getMonthlyTotal(Map<DateTime, Map<String, int>> data) {
    int incomeTotal = 0;
    int expenseTotal = 0;
    data.forEach((date, val) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        incomeTotal += val["income"] ?? 0;
        expenseTotal += val["expense"] ?? 0;
      }
    });
    return {
      "income": incomeTotal,
      "expense": expenseTotal,
      "total": incomeTotal - expenseTotal,
    };
  }

  // 무지출 여부 확인 (기존 로직 복구)
  bool isNoSpendDay(DateTime day, Map<DateTime, Map<String, int>> data) {
    final dayData = data[normalizeDate(day)];
    if (dayData == null) return true; // 데이터가 아예 없으면 무지출
    return (dayData["expense"] ?? 0) == 0; // 지출이 0이면 무지출
  }

  int getNoSpendDays(Map<DateTime, Map<String, int>> data) {
    int count = 0;
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    for (int i = 1; i <= lastDay; i++) {
      final day = DateTime(_focusedDay.year, _focusedDay.month, i);
      if (isNoSpendDay(day, data)) count++;
    }
    return count;
  }

  // --- 메뉴 및 입력 폼 (기존과 동일) ---
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.center_focus_weak,
                color: AppColors.primary,
              ),
              title: const Text("이미지 추가하기"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text("직접 입력하기"),
              onTap: () {
                Navigator.pop(context);
                _showAddForm(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddForm(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String category = "지출";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "가격",
                  suffixText: "원",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // 기록 추가 폼(_showAddForm) 내부의 Row 부분
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: const Text(
                      "분류",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Expanded 대신 필요한 만큼의 공간만 차지하도록 수정
                  _typeButton(
                    "지출",
                    category == "지출",
                    () => setModalState(() => category = "지출"),
                  ),
                  const SizedBox(width: 10),
                  _typeButton(
                    "수입",
                    category == "수입",
                    () => setModalState(() => category = "수입"),
                  ),
                  const SizedBox(width: 10),
                  _typeButton(
                    "이체",
                    category == "이체",
                    () => setModalState(() => category = "이체"),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "구입 내역",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(
                  "날짜: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null)
                    setModalState(() => selectedDate = picked);
                },
              ),

              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 버튼 모서리 둥글게
                    ),
                  ),
                  onPressed: () async {
                    final user = context.read<AuthService>().user;
                    if (user == null || titleController.text.isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('records')
                        .add({
                          'title': titleController.text,
                          'amount': int.tryParse(amountController.text) ?? 0,
                          'date': Timestamp.fromDate(selectedDate),
                          'type': category,
                        });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    "저장하기",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, bool isSelected, VoidCallback onTap) {
    return SizedBox(
      width: 70,
      height: 50,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFCCCCCC),
              width: isSelected ? 2.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- 날짜 클릭 시 상세 내역 ---
  void _showDayDetails(DateTime selectedDay) {
    final start = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final end = start.add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 내부 요소들 기본 왼쪽 정렬
          children: [
            // 날짜와 X 버튼을 한 줄에 배치
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝으로 배치
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(selectedDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(), // 터치 영역 최소화
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context), // 창 닫기 기능
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(context.read<AuthService>().user?.uid)
                  .collection('records')
                  .where('date', isGreaterThanOrEqualTo: start)
                  .where('date', isLessThan: end)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final count = snapshot.data!.docs.length; // 데이터의 개수 추출

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    "총 $count건",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            const Divider(
              thickness: 0.5,
              color: Color(0xFFCCCCCC),
              indent: 5, // 왼쪽 여백
              endIndent: 5,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(context.read<AuthService>().user?.uid)
                    .collection('records')
                    .where('date', isGreaterThanOrEqualTo: start)
                    .where('date', isLessThan: end)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Center(child: Text("기록이 없습니다."));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final item = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        // 1. 기본 패딩 제거 (날짜와 왼쪽 끝 정렬 맞추기)
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),

                        title: Text(
                          item['title'] ?? "내역 없음",
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Text(
                          "${item['type'] == '지출' ? '-' : '+'}${formatMoney(item['amount'])}원",
                          style: TextStyle(
                            color: item['type'] == '지출'
                                ? AppColors.pointColor
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 15), // 리스트와 버튼 사이 간격
            // 하단 확인 버튼
            SizedBox(
              width: double.infinity, // 가로 꽉 채우기
              height: 50, // 버튼 높이
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // 가계부 메인 테마 색상
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 버튼 모서리 둥글게
                  ),
                  elevation: 0, // 그림자 없애서 깔끔하게 (선택 사항)
                ),
                onPressed: () {
                  Navigator.pop(context); // X 버튼과 동일하게 창 닫기
                },
                child: const Text(
                  "확인",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10), // 바닥과의 최소 여백
          ], // Column의 children 끝
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인 해주세요")));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('records')
          .snapshots(),
      builder: (context, snapshot) {
        Map<DateTime, Map<String, int>> financeData = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final normalized = normalizeDate(date);
            if (!financeData.containsKey(normalized))
              financeData[normalized] = {"expense": 0, "income": 0};
            if (data['type'] == "지출") {
              financeData[normalized]!["expense"] =
                  (financeData[normalized]!["expense"] ?? 0) +
                  (data['amount'] as int);
            } else {
              financeData[normalized]!["income"] =
                  (financeData[normalized]!["income"] ?? 0) +
                  (data['amount'] as int);
            }
          }
        }

        final monthlyTotal = getMonthlyTotal(financeData);
        final noSpendDays = getNoSpendDays(financeData);

        return Scaffold(
          appBar: _selectedIndex == 0
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  centerTitle: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                        ),
                        onPressed: () => setState(
                          () => _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month - 1,
                            1,
                          ),
                        ),
                      ),
                      Text(
                        "${_focusedDay.month}월",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                        onPressed: () => setState(
                          () => _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month + 1,
                            1,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : customAppBar(
                  context: context,
                  title: _selectedIndex == 1
                      ? "자산"
                      : _selectedIndex == 2
                      ? "분석"
                      : "설정",
                ),

          body: _selectedIndex == 0
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSummaryCard(monthlyTotal),
                      _buildNoSpendCard(noSpendDays),
                      const SizedBox(height: 10),
                      TableCalendar(
                        locale: 'ko_KR',
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2030),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        headerVisible: false,
                        daysOfWeekHeight: 40,
                        rowHeight: 80,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _showDayDetails(selectedDay);
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) =>
                              _buildDayCell(day, financeData),
                          todayBuilder: (context, day, focusedDay) =>
                              _buildDayCell(day, financeData),
                          selectedBuilder: (context, day, focusedDay) =>
                              _buildDayCell(day, financeData, isSelected: true),
                        ),
                      ),
                    ],
                  ),
                )
              : _pages[_selectedIndex],

          bottomNavigationBar: BottomMenuBar(
            selectedIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),

          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  shape: const CircleBorder(),
                  onPressed: () => _showAddMenu(context),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                )
              : null,
        );
      },
    );
  }

  // --- 기존 카드 디자인 ---
  Widget _buildSummaryCard(Map<String, int> total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = 1),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _rowValue(
                      "수입",
                      "${formatMoney(total["income"]!)}원",
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _rowValue(
                      "지출",
                      "${formatMoney(total["expense"]!)}원",
                      AppColors.pointColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _rowValue(
                "현 자산",
                "${formatMoney(total["total"]!)}원",
                Colors.black,
                fontSize: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowValue(
    String label,
    String value,
    Color color, {
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNoSpendCard(int days) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("무지출", style: TextStyle(color: AppColors.secondary)),
            Text(
              "총 $days일",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- 캘린더 셀 디자인 (무지출 Dot 포함) ---
  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, Map<String, int>> data, {
    bool isSelected = false,
  }) {
    final bool isNoSpend = isNoSpendDay(day, data);
    final dayData = data[normalizeDate(day)];
    final int income = dayData?["income"] ?? 0;
    final int expense = dayData?["expense"] ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // 무지출 dot (기존 디자인 복구)
        isNoSpend
            ? Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.pointColor,
                  shape: BoxShape.circle,
                ),
              )
            : const SizedBox(height: 5),
        const SizedBox(height: 3),
        // 날짜 원
        Container(
          child: Text(
            '${day.day}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(height: 5),
        // 수입/지출 텍스트
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expense != 0)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '-${formatMoney(expense)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              if (income != 0)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '+${formatMoney(income)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
