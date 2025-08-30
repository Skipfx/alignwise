import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class WeeklyMacroTrends extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyData;
  final Map<String, double> targets;

  const WeeklyMacroTrends({
    super.key,
    required this.weeklyData,
    required this.targets,
  });

  @override
  State<WeeklyMacroTrends> createState() => _WeeklyMacroTrendsState();
}

class _WeeklyMacroTrendsState extends State<WeeklyMacroTrends> {
  String _selectedMacro = 'protein';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Trends',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildMacroToggle(),
            ],
          ),
          SizedBox(height: 3.h),
          _buildChart(),
          SizedBox(height: 2.h),
          _buildWeeklyStats(),
        ],
      ),
    );
  }

  Widget _buildMacroToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Protein', 'protein', const Color(0xFF6BCF7F)),
          _buildToggleButton('Carbs', 'carbs', const Color(0xFF4A90E2)),
          _buildToggleButton('Fat', 'fat', const Color(0xFFF5A623)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String value, Color color) {
    final isSelected = _selectedMacro == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMacro = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? color
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final targetValue = widget.targets[_selectedMacro] ?? 0.0;
    final macroColor = _getMacroColor(_selectedMacro);

    return SizedBox(
      height: 25.h,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: targetValue / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(
                    color: Color(0xff68737d),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  String text = '';
                  if (value.toInt() < widget.weeklyData.length) {
                    text = widget.weeklyData[value.toInt()]['day'];
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: targetValue / 4,
                reservedSize: 42,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      value.round().toString(),
                      style: const TextStyle(
                        color: Color(0xff68737d),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 0.5),
          ),
          minX: 0,
          maxX: (widget.weeklyData.length - 1).toDouble(),
          minY: 0,
          maxY: targetValue * 1.5,
          lineBarsData: [
            LineChartBarData(
              spots: widget.weeklyData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value[_selectedMacro].toDouble(),
                );
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  macroColor.withValues(alpha: 0.8),
                  macroColor,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: macroColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    macroColor.withValues(alpha: 0.3),
                    macroColor.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
            // Target line
            LineChartBarData(
              spots: List.generate(widget.weeklyData.length,
                  (index) => FlSpot(index.toDouble(), targetValue)),
              isCurved: false,
              color: AppTheme.lightTheme.colorScheme.error,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBorder: BorderSide(
                color: AppTheme.lightTheme.colorScheme.surface,
                width: 1,
              ),
              tooltipRoundedRadius: 8,
              getTooltipColor: (touchedSpot) =>
                  AppTheme.lightTheme.colorScheme.surface,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  if (flSpot.barIndex == 0) {
                    // Only show for data line, not target line
                    return LineTooltipItem(
                      '${widget.weeklyData[flSpot.x.toInt()]['day']}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${flSpot.y.round()}g',
                          style: TextStyle(
                            color: macroColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    final macroValues =
        widget.weeklyData.map((day) => day[_selectedMacro] as num).toList();
    final average =
        macroValues.fold(0.0, (sum, value) => sum + value) / macroValues.length;
    final targetValue = widget.targets[_selectedMacro] ?? 0.0;
    final hitTargetDays =
        macroValues.where((value) => value >= targetValue * 0.9).length;
    final consistency = (hitTargetDays / macroValues.length * 100).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(
            'Average', '${average.round()}g', _getMacroColor(_selectedMacro)),
        _buildStatCard(
            'Target Hit',
            '$hitTargetDays/7 days',
            hitTargetDays >= 5
                ? const Color(0xFF6BCF7F)
                : const Color(0xFFF5A623)),
        _buildStatCard(
            'Consistency',
            '$consistency%',
            consistency >= 70
                ? const Color(0xFF6BCF7F)
                : const Color(0xFFF5A623)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMacroColor(String macro) {
    switch (macro) {
      case 'protein':
        return const Color(0xFF6BCF7F);
      case 'carbs':
        return const Color(0xFF4A90E2);
      case 'fat':
        return const Color(0xFFF5A623);
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }
}