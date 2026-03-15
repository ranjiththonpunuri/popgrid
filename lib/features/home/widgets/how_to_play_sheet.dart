import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';

class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How to Play',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.neonGreen,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 20),
          _buildRule(
            context,
            '1',
            'Player 1 is',
            highlight: 'X',
            rest: ', Player 2 is O. Place only your letter.',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            '2',
            'Line up',
            highlight: '3+ of your letter',
            rest: 'in a row (horizontal, vertical, or diagonal) to score!',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            '3',
            'Scoring:',
            highlight: '3=1pt, 4=3pts, 5=6pts',
            rest: '— longer lines score big!',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            '4',
            'Scored lines get',
            highlight: 'struck out',
            rest: '— those cells are locked and can never be flipped!',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            '5',
            'When you score, opponent letters',
            highlight: 'adjacent to your line flip',
            rest: 'to your letter (except struck-out cells).',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            '6',
            'The grid starts with some',
            highlight: 'pre-placed letters',
            rest: 'to keep things interesting.',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            '7',
            'When the grid is full,',
            highlight: 'most points wins',
            rest: '. Tiebreaker: most cells owned.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRule(
    BuildContext context,
    String number,
    String text, {
    required String highlight,
    required String rest,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neonGreen,
                  fontSize: 10,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 9,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
              children: [
                TextSpan(text: '$text '),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(color: AppColors.neonYellow),
                ),
                TextSpan(text: ' $rest'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
