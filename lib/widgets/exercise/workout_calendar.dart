import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/exercise_models.dart';

class WorkoutCalendar extends StatefulWidget {
  final List<ExerciseLog> logs;
  final DateTime initialDate;
  final Function(DateTime)? onDateSelected;

  WorkoutCalendar({
    Key? key,
    required this.logs,
    DateTime? initialDate,
    this.onDateSelected,
  })  : initialDate = initialDate ?? DateTime.now(),
        super(key: key);

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late Map<DateTime, List<ExerciseLog>> _logsByDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _updateLogsByDate();
  }

  @override
  void didUpdateWidget(WorkoutCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs != oldWidget.logs) {
      _updateLogsByDate();
    }
  }

  void _updateLogsByDate() {
    // Group logs by date (excluding time)
    _logsByDate = {};
    for (final log in widget.logs) {
      final date = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );

      if (!_logsByDate.containsKey(date)) {
        _logsByDate[date] = [];
      }

      _logsByDate[date]!.add(log);
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: AppTheme.primaryBlue,
              ),
              Text(
                _getMonthYearText(_displayedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Tue', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Thu', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),

          const SizedBox(height: 8),

          // Calendar grid
          SizedBox(
            height: 280,
            child: _buildCalendarGrid(),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.grey.shade300, 'No Workout'),
              const SizedBox(width: 16),
              _buildLegendItem(
                  AppTheme.primaryBlue.withOpacity(0.3), 'Workout'),
              const SizedBox(width: 16),
              _buildLegendItem(AppTheme.primaryBlue, 'Selected'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;

    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstWeekdayOfMonth =
        firstDayOfMonth.weekday; // 1 for Monday, 7 for Sunday

    // Calculate the number of placeholder days needed before the first day
    final daysBeforeMonth = firstWeekdayOfMonth - 1;

    // Calculate the total number of cells needed (include all placeholder days)
    final totalCells = daysBeforeMonth + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalRows * 7,
      itemBuilder: (context, index) {
        // Calculate the day number
        final dayNumber = index - daysBeforeMonth + 1;

        // If the index is less than the first day offset or greater than days in month, render an empty cell
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Container();
        }

        // Create the date for this cell
        final date =
            DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);

        // Check if there are logs for this date
        final hasWorkout =
            _logsByDate.containsKey(date) && _logsByDate[date]!.isNotEmpty;

        // Check if this is the selected date
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        // Check if this is today
        final isToday = _isToday(date);

        return GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue
                  : hasWorkout
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: AppTheme.primaryBlue, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getMonthYearText(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
