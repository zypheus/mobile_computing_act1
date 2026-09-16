import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Preferences & Global State',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              const SectionHeader(
                title: 'Appearance & Theme',
                subtitle: 'Global state managed via Provider & ChangeNotifier',
              ),
              const SizedBox(height: 8),

              // Theme Quick Switch Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: themeProvider.isDarkMode,
                        onChanged: (bool value) {
                          themeProvider.toggleTheme(value);
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          'Dark Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          themeProvider.isDarkMode
                              ? 'Dark theme active across all screens'
                              : 'Light theme active across all screens',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const Divider(height: 24),

                      // Detailed Theme Selectors
                      _buildThemeTile(
                        context,
                        mode: AppThemeMode.light,
                        label: 'Light Theme',
                        icon: Icons.wb_sunny_outlined,
                        provider: themeProvider,
                      ),
                      _buildThemeTile(
                        context,
                        mode: AppThemeMode.dark,
                        label: 'Dark Theme',
                        icon: Icons.nightlight_round_outlined,
                        provider: themeProvider,
                      ),
                      _buildThemeTile(
                        context,
                        mode: AppThemeMode.system,
                        label: 'System Default',
                        icon: Icons.brightness_auto_outlined,
                        provider: themeProvider,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // State Management Explanation Card
              const SectionHeader(
                title: 'State Architecture Info',
                subtitle: 'How Provider propagates theme changes dynamically',
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Provider Mechanism',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '1. ThemeProvider notifies listeners when state changes.\n'
                        '2. The root MaterialApp listens via Consumer<ThemeProvider>.\n'
                        '3. MaterialApp updates its themeMode parameter dynamically without resetting route stack or reloading the app.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required AppThemeMode mode,
    required String label,
    required IconData icon,
    required ThemeProvider provider,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = provider.appThemeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      onTap: () {
        provider.setAppThemeMode(mode);
      },
    );
  }
}
