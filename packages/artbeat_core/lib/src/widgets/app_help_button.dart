import 'package:flutter/material.dart';

class AppHelpButton extends StatelessWidget {
  const AppHelpButton({
    super.key,
    required this.title,
    required this.body,
    this.steps = const [],
    this.tooltip = 'Help',
  });

  final String title;
  final String body;
  final List<String> steps;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF101322),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFF22D3EE),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (var i = 0; i < steps.length; i++) ...[
                    _HelpStep(number: i + 1, text: steps[i]),
                    if (i < steps.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF7C4DFF),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
