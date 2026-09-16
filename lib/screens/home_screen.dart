import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flutter_dash_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flutter Portfolio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mobile Computing 3 Activities',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.6),
                      colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Our Portfolio',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explore laboratory activities, state management patterns, and interactive Flutter components.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Section
              const SectionHeader(
                title: 'Student Developers',
                subtitle: 'Course & Identification details',
              ),
              const SizedBox(height: 8),
              const ProfileCard(),

              const SizedBox(height: 28),

              // Activities Section
              SectionHeader(
                title: 'Laboratory Activities',
                subtitle: 'Tap an activity card to launch module',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '2 Activities',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Responsive Grid/List layout for Activity Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 650;

                  final activity1Card = ActivityCard(
                    subtitle: 'ACTIVITY 01',
                    title: 'Flutter & State Management',
                    description:
                        'Demonstrates local state management (StatefulWidget) alongside global Provider theme state.',
                    icon: Icons.alt_route_rounded,
                    tags: const [
                      'Provider',
                      'StatefulWidget',
                      'Local vs Global',
                    ],
                    status: ActivityStatus.completed,
                    onTap: () {
                      Navigator.pushNamed(context, '/activity1');
                    },
                  );

                  final activity2Card = ActivityCard(
                    subtitle: 'ACTIVITY 02',
                    title: 'Activity 2 Placeholder',
                    description:
                        'Reserved module for upcoming mobile computing laboratory assignments and exercises.',
                    icon: Icons.hourglass_empty_rounded,
                    tags: const ['Placeholder', 'Upcoming Lab'],
                    status: ActivityStatus.upcoming,
                    onTap: () {
                      Navigator.pushNamed(context, '/activity2');
                    },
                  );

                  if (isWideScreen) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: activity1Card),
                        const SizedBox(width: 16),
                        Expanded(child: activity2Card),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      activity1Card,
                      const SizedBox(height: 16),
                      activity2Card,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
