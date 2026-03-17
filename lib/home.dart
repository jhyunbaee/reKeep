import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rekeep/bottom_menu_bar.dart';
import 'package:rekeep/setting.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rekeep/constants/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _selectedIndex = 0; // bottomNavigationBar

  bool isLoggedIn = false;

  Map<DateTime, Map<String, int>> financeData = {
    DateTime(2026, 3, 1): {"expense": 120000, "income": 50000},
    DateTime(2026, 3, 3): {"expense": 224500, "income": 50000},
    DateTime(2026, 3, 12): {"expense": 8000},
    DateTime(2026, 3, 15): {"expense": 12000, "income": 224500},
    DateTime(2026, 3, 16): {"expense": 8000},
    DateTime(2026, 3, 19): {"expense": 12000, "income": 24500},
    DateTime(2026, 3, 27): {"expense": 12000, "income": 55000000},
    DateTime(2026, 3, 30): {"expense": 2200, "income": 60000},
  };

  // 날짜를 시간 없이 정규화
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 무지출 여부
  bool isNoSpendDay(DateTime day) {
    final data = financeData[normalizeDate(day)];
    if (data == null) return true;
    return (data["expense"] ?? 0) == 0;
  }

  // 앱바
  final List<Widget> _pages = [
    const Center(child: Text("홈")),
    const Center(child: Text("자산")),
    const Center(child: Text("분석")),
    const Setting(),
  ];
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return "자산";
      case 2:
        return "분석";
      case 3:
        return "설정";
      default:
        return "";
    }
  }

  // 합계 계산
  Map<String, int> getMonthlyTotal() {
    int incomeTotal = 0;
    int expenseTotal = 0;

    financeData.forEach((date, data) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        incomeTotal += data["income"] ?? 0;
        expenseTotal += data["expense"] ?? 0;
      }
    });

    return {
      "income": incomeTotal,
      "expense": expenseTotal,
      "total": incomeTotal - expenseTotal,
    };
  }

  // 무지출
  String formatMoney(int amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }

  int getNoSpendDays() {
    int count = 0;

    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    for (int i = 0; i < lastDay.day; i++) {
      final day = DateTime(_focusedDay.year, _focusedDay.month, i + 1);
      if (isNoSpendDay(day)) {
        count++;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = getMonthlyTotal();
    final noSpendDays = getNoSpendDays();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: _selectedIndex == 0
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                ],
              )
            : Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),

      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,

      body: _selectedIndex == 0
          ? Column(
              children: [
                /// 합계
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1; // 자산 페이지
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          /// 수입 / 지출
                          Row(
                            children: [
                              /// 수입
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "수입",
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    Text(
                                      "${formatMoney(monthlyTotal["income"]!)}원",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              /// 지출
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "지출",
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    Text(
                                      "${formatMoney(monthlyTotal["expense"]!)}원",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.pointColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// 합계
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "현 자산",
                                style: TextStyle(color: AppColors.secondary),
                              ),
                              Text(
                                "${formatMoney(monthlyTotal["total"]!)}원",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// 무지출 카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "무지출",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                        Text(
                          "총 $noSpendDays일",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// 캘린더
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TableCalendar(
                      locale: 'ko_KR',
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                      ),
                      calendarFormat: _calendarFormat,
                      availableCalendarFormats: const {
                        CalendarFormat.month: '월',
                      },
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
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
                            final data =
                                financeData[normalizeDate(selectedDay)];
                            return Container(
                              height: 350,
                              padding: const EdgeInsets.all(30),
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
                                  if (data?["expense"] != null)
                                    Text(
                                      "지출: -${formatMoney(data!["expense"]!)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.secondary,
                                      ),
                                    ),

                                  if (data?["income"] != null)
                                    Text(
                                      "수입: +${formatMoney(data!["income"]!)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.primary,
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
            )
          : _pages[_selectedIndex],

      bottomNavigationBar: BottomMenuBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),

      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 10),
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                onPressed: () {},
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            )
          : null,
    );
  }

  // 날짜 셀 공통 함수
  Widget _buildDayCell(
    DateTime day,
    Map<String, int>? data, {
    bool isSelected = false,
  }) {
    final bool isNoSpend = isNoSpendDay(day);

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
          // 무지출 dot
          isNoSpend
              ? Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.pointColor,
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox(height: 4),

          const SizedBox(height: 2),
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
      ),
    );
  }
}
