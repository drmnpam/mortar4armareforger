import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../app/theme/app_theme.dart';

/// Tutorial screen for new users
class TutorialScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialScreen({super.key, required this.onComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text(
                  'SKIP',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: const [
                  _TutorialPage(
                    icon: Icons.explore,
                    title: 'MORTAR CALCULATOR',
                    description:
                        'A ballistic calculator for Arma Reforger. Calculate firing solutions for mortar fire missions with precision.',
                  ),
                  _TutorialPage(
                    icon: Icons.my_location,
                    title: '1. SET MORTAR POSITION',
                    description:
                        'Enter your mortar location using grid coordinates (6-digit format: XXX YYY) or place on the map.',
                  ),
                  _TutorialPage(
                    icon: Icons.location_on,
                    title: '2. ADD TARGET',
                    description:
                        'Enter target coordinates or tap on the map. The app will automatically calculate the firing solution.',
                  ),
                  _TutorialPage(
                    icon: Icons.calculate,
                    title: '3. READ SOLUTION',
                    description:
                        'Azimuth (direction), Elevation (barrel angle), and Charge are displayed. Time of flight shows when rounds will impact.',
                  ),
                  _TutorialPage(
                    icon: Icons.trending_up,
                    title: '4. SHOT CORRECTION',
                    description:
                        'Observer calls corrections: ADD/DROP for range, LEFT/RIGHT for deflection. Apply to adjust the solution.',
                  ),
                  _TutorialPage(
                    icon: Icons.campaign,
                    title: '5. FIRE MISSIONS',
                    description:
                        'Create multi-target fire missions with priority queue. Sequential firing with automatic calculations.',
                  ),
                  _TutorialPage(
                    icon: Icons.offline_bolt,
                    title: 'OFFLINE READY',
                    description:
                        'All calculations work without internet. Save maps and ballistic tables locally for field use.',
                  ),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SmoothPageIndicator(
                controller: _controller,
                count: 7,
                effect: WormEffect(
                  dotColor: AppTheme.gridLine,
                  activeDotColor: AppTheme.accent,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Back button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      },
                      child: const Text('BACK'),
                    )
                  else
                    const SizedBox(width: 80),

                  const Spacer(),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 6) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        widget.onComplete();
                      }
                    },
                    child: Text(_currentPage < 6 ? 'NEXT' : 'GET STARTED'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppTheme.accent,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Quick help dialog for specific features
class QuickHelpDialog extends StatelessWidget {
  final String title;
  final List<HelpItem> items;

  const QuickHelpDialog({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        title,
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Icon(item.icon, color: AppTheme.accent),
              title: Text(
                item.title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                item.description,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'GOT IT',
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
      ],
    );
  }
}

class HelpItem {
  final IconData icon;
  final String title;
  final String description;

  const HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Grid input help overlay
void showGridHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const QuickHelpDialog(
      title: 'GRID COORDINATES',
      items: [
        HelpItem(
          icon: Icons.grid_on,
          title: '6-Digit Grid',
          description: 'XXX YYY format. 100m precision. Example: 012 345',
        ),
        HelpItem(
          icon: Icons.grid_on,
          title: '8-Digit Grid',
          description: 'XXXX YYYY format. 10m precision. Example: 0123 4567',
        ),
        HelpItem(
          icon: Icons.map,
          title: 'Arma Reforger',
          description: 'Compatible with Arma\'s grid system. X = East-West, Y = North-South',
        ),
      ],
    ),
  );
}

/// Shot correction help overlay
void showCorrectionHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const QuickHelpDialog(
      title: 'SHOT CORRECTIONS',
      items: [
        HelpItem(
          icon: Icons.trending_up,
          title: 'ADD [meters]',
          description: 'Increase range. Target is closer to you than expected.',
        ),
        HelpItem(
          icon: Icons.trending_down,
          title: 'DROP [meters]',
          description: 'Decrease range. Target is farther than expected.',
        ),
        HelpItem(
          icon: Icons.arrow_back,
          title: 'LEFT [mils]',
          description: 'Decrease azimuth. Target is to the left of splash.',
        ),
        HelpItem(
          icon: Icons.arrow_forward,
          title: 'RIGHT [mils]',
          description: 'Increase azimuth. Target is to the right of splash.',
        ),
      ],
    ),
  );
}
