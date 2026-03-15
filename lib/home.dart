import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rekeep/constants/colors.dart';
import 'package:rekeep/login.dart';
import '../auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, Map<String, int>> financeData = {
    DateTime(2026, 3, 15): {"expense": 12000, "income": 50000},
    DateTime(2026, 3, 16): {"expense": 8000},
  };

  // 날짜를 시간 없이 정규화
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 이전 달 버튼
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                    1,
                  );
                });
              },
            ),
            // 현재 월 표시
            Text(
              "${_focusedDay.year}년 ${_focusedDay.month}월",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            // 다음 달 버튼
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                    1,
                  );
                });
              },
            ),
            // 로그아웃 버튼
            TextButton(
              onPressed: () async {
                context.read<AuthService>().signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("로그아웃", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          /// 캘린더
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {CalendarFormat.month: '월'},
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rowHeight: 80, // 충분히 높여 overflow 방지
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: false,
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                ),
                headerVisible: false,
                daysOfWeekHeight: 40,

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  // 하단 상세창
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      final data = financeData[normalizeDate(selectedDay)];
                      return Container(
                        height: 350,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${selectedDay.year}년 ${selectedDay.month}월 ${selectedDay.day}일",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (data?["income"] != null)
                              Text(
                                "수입: +${data!["income"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            if (data?["expense"] != null)
                              Text(
                                "지출: -${data?["expense"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            const SizedBox(height: 20),
                            // 상세 내역 샘플
                            const ListTile(
                              title: Text("스타벅스"),
                              trailing: Text("-4500"),
                            ),
                            const ListTile(
                              title: Text("점심식사"),
                              trailing: Text("-8000"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },

                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final data = financeData[normalizeDate(day)];
                    return _buildDayCell(day, data);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final data = financeData[normalizeDate(day)];
                    return _buildDayCell(day, data);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final data = financeData[normalizeDate(day)];
                    return _buildDayCell(day, data, isSelected: true);
                  },
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 100),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          onPressed: () {},
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 날짜 셀 공통 함수
  Widget _buildDayCell(
    DateTime day,
    Map<String, int>? data, {
    bool isSelected = false,
  }) {
    final int income = data?["income"] ?? 0;
    final int expense = data?["expense"] ?? 0;

    double circleSize = 30; // 원 크기
    double spacing = 5; // 원과 텍스트 사이 간격
    double cellHeight = 80; // 전체 칸 높이 충분히 확보

    Color bgColor = isSelected ? AppColors.primary : Colors.transparent;
    Color textColor = isSelected ? Colors.white : Colors.black;

    return SizedBox(
      height: cellHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 원 + 날짜
          Container(
            width: circleSize,
            height: circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          SizedBox(height: spacing),
          // 수입/지출
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (income != 0)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+$income',
                      style: const TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ),
                if (expense != 0)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '-$expense',
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
