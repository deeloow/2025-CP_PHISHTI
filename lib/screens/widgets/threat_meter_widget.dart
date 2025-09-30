import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/phishing_detection.dart';

class ThreatMeterWidget extends ConsumerWidget {
  final ThreatLevel threatLevel;
  final int weeklyDetections;
  final int totalDetections;

  const ThreatMeterWidget({
    super.key,
    required this.threatLevel,
    required this.weeklyDetections,
    required this.totalDetections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getThreatGradient(threatLevel),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getThreatColor(threatLevel).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getThreatIcon(threatLevel),
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Threat Meter',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getThreatLabel(threatLevel),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Threat Level Indicator
          Row(
            children: [
              Expanded(
                child: _ThreatLevelIndicator(
                  level: threatLevel,
                  weeklyDetections: weeklyDetections,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$weeklyDetections',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'This Week',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalDetections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total Blocked',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Threat Description
          Text(
            _getThreatDescription(threatLevel),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getThreatGradient(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThreatLevel.medium:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThreatLevel.high:
        return const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThreatLevel.critical:
        return const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getThreatColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return const Color(0xFF4CAF50);
      case ThreatLevel.medium:
        return const Color(0xFFFF9800);
      case ThreatLevel.high:
        return const Color(0xFFFF5722);
      case ThreatLevel.critical:
        return const Color(0xFFD32F2F);
    }
  }

  IconData _getThreatIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return Icons.check_circle;
      case ThreatLevel.medium:
        return Icons.warning;
      case ThreatLevel.high:
        return Icons.error;
      case ThreatLevel.critical:
        return Icons.dangerous;
    }
  }

  String _getThreatLabel(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return 'LOW';
      case ThreatLevel.medium:
        return 'MEDIUM';
      case ThreatLevel.high:
        return 'HIGH';
      case ThreatLevel.critical:
        return 'CRITICAL';
    }
  }

  String _getThreatDescription(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return 'Great! You\'re well protected with minimal threats detected.';
      case ThreatLevel.medium:
        return 'Moderate threat level. Stay vigilant and review your security settings.';
      case ThreatLevel.high:
        return 'High threat level detected. Consider reviewing your security practices.';
      case ThreatLevel.critical:
        return 'Critical threat level! Immediate attention required for your security.';
    }
  }
}

class _ThreatLevelIndicator extends StatefulWidget {
  final ThreatLevel level;
  final int weeklyDetections;

  const _ThreatLevelIndicator({
    required this.level,
    required this.weeklyDetections,
  });

  @override
  State<_ThreatLevelIndicator> createState() => _ThreatLevelIndicatorState();
}

class _ThreatLevelIndicatorState extends State<_ThreatLevelIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: _getThreatPercentage(widget.level),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getThreatPercentage(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return 0.25;
      case ThreatLevel.medium:
        return 0.5;
      case ThreatLevel.high:
        return 0.75;
      case ThreatLevel.critical:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threat Level',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ThreatLevelDot(level: ThreatLevel.low, isActive: widget.level.index >= 0),
                const SizedBox(width: 8),
                _ThreatLevelDot(level: ThreatLevel.medium, isActive: widget.level.index >= 1),
                const SizedBox(width: 8),
                _ThreatLevelDot(level: ThreatLevel.high, isActive: widget.level.index >= 2),
                const SizedBox(width: 8),
                _ThreatLevelDot(level: ThreatLevel.critical, isActive: widget.level.index >= 3),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ThreatLevelDot extends StatelessWidget {
  final ThreatLevel level;
  final bool isActive;

  const _ThreatLevelDot({
    required this.level,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
    );
  }
}
