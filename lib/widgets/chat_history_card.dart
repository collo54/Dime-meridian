import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/chat_session_model.dart';

class ChatHistoryCard extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const ChatHistoryCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Formatting Date: "12 Aug 2024"
    final dateString = DateFormat('dd MMM yyyy').format(session.updatedAt);
    // Formatting Time: "17:38"
    final timeString = DateFormat('HH:mm').format(session.updatedAt);
    Brightness brightness = MediaQuery.platformBrightnessOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ROW 1: Icon, Date, Menu ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // The Yellow Icon (Kept as requested)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kblack00005, width: 1),
                      ),
                      child: HugeIcon(
                        size: 20,
                        icon: HugeIcons.strokeRoundedAiChat01,
                        color: brightness == Brightness.light
                            ? kblack00008
                            : kwhite25525525510,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date
                    Text(
                      dateString,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Menu Icon (Three dots)
                InkWell(
                  onTap: onMoreTap,
                  child: HugeIcon(
                    size: 20,
                    icon: HugeIcons.strokeRoundedMore01,
                    color: brightness == Brightness.light
                        ? kblack00008
                        : kwhite25525525510,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- ROW 2: Time ---
            Text(
              timeString,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 4),

            // --- ROW 3: Title ---
            Text(
              session.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            // --- ROW 4: Description (Summary) ---
            // Since ChatSessionModel currently only has title, we use the title
            // or a placeholder. If you add a 'summary' field later, replace this.
            Text(
              "Click to view the full analysis of this session...",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
