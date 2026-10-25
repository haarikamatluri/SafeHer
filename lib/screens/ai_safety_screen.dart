import 'package:flutter/material.dart';

import '../app/theme.dart';

class AiSafetyScreen extends StatefulWidget {
  const AiSafetyScreen({super.key});

  @override
  State<AiSafetyScreen> createState() => _AiSafetyScreenState();
}

class _AiSafetyScreenState extends State<AiSafetyScreen> {
  int _selectedScenario = 0;

  final List<Map<String, dynamic>> _scenarios = [
    {
      'title': 'Night Transit / Walking',
      'icon': Icons.nightlight_round,
      'summary': 'Plan for walking or waiting for public transit after dark.',
      'items': [
        'Stay on well-lit main thoroughfares rather than shortcuts.',
        'Keep one ear free if listening to audio to remain alert to footsteps.',
        'Have your keys or phone accessible before reaching your entrance.',
        'Start a SafeHer 15-minute Safety Check-in timer before your walk.',
        'If you sense someone following you, cross the street or enter an open commercial store.',
      ],
    },
    {
      'title': 'Rideshare & Taxis',
      'icon': Icons.local_taxi,
      'summary': 'Proactive safety checks before and during car journeys.',
      'items': [
        'Confirm driver name, photo, and license plate match the app before entering.',
        'Ask the driver "Who are you picking up?" rather than stating your name first.',
        'Sit in the back seat opposite the driver to maintain exit access from both sides.',
        'Share your live trip progress or map link with a trusted contact.',
        'Ensure the child-lock is not engaged by verifying the door handle functions.',
      ],
    },
    {
      'title': 'Solo Travel & Lodging',
      'icon': Icons.flight_takeoff,
      'summary': 'Guidance for staying safe in unfamiliar cities or hotels.',
      'items': [
        'Request rooms between the 2nd and 4th floors (accessible to fire trucks, secure from street entry).',
        'Verify door deadbolt and security latch upon entering your hotel room.',
        'Keep emergency numbers for your destination saved in SafeHer Settings.',
        'Avoid displaying room keys with visible room numbers in public lobbies.',
        'Leave a digital itinerary with your primary emergency contact.',
      ],
    },
    {
      'title': 'Campus & Study Late',
      'icon': Icons.school,
      'summary': 'Precautions for libraries, dorms, and campus facilities.',
      'items': [
        'Use campus safety escort services when walking between facilities at night.',
        'Know the locations of campus emergency blue-light poles.',
        'Inform a roommate or study partner when departing the campus building.',
        'Keep your phone battery above 30% before heading out.',
      ],
    },
  ];

  final Set<String> _checkedItems = {};

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_selectedScenario];
    final List<String> checklist = scenario['items'];

    return Scaffold(
      backgroundColor: SafeHerTheme.offWhite,
      appBar: AppBar(title: const Text('AI Safety Guidance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ethical AI Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SafeHerTheme.roseLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SafeHerTheme.roseBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.auto_awesome,
                    color: SafeHerTheme.plumPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Guidance provides structured situational checklists based on curated safety protocols. '
                      'It does NOT predict danger, replace personal judgment, or substitute for emergency dispatch.',
                      style: TextStyle(
                        fontSize: 12,
                        color: SafeHerTheme.textDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select Scenario Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SafeHerTheme.plumPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Scenario Selector Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _scenarios.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final s = _scenarios[index];
                  final isSelected = _selectedScenario == index;
                  return ChoiceChip(
                    avatar: Icon(
                      s['icon'],
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : SafeHerTheme.plumPrimary,
                    ),
                    label: Text(s['title']),
                    selected: isSelected,
                    selectedColor: SafeHerTheme.plumPrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : SafeHerTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedScenario = index;
                        });
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Scenario Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          scenario['icon'],
                          color: SafeHerTheme.plumPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            scenario['title'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: SafeHerTheme.plumPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scenario['summary'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: SafeHerTheme.textMuted,
                      ),
                    ),
                    const Divider(height: 22),
                    const Text(
                      'Actionable Checklist:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SafeHerTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...checklist.map((item) {
                      final isChecked = _checkedItems.contains(item);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _checkedItems.remove(item);
                              } else {
                                _checkedItems.add(item);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: SafeHerTheme.safeGreen,
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _checkedItems.add(item);
                                    } else {
                                      _checkedItems.remove(item);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: isChecked
                                          ? SafeHerTheme.textMuted
                                          : SafeHerTheme.textDark,
                                      decoration: isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Situational de-escalation tips
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'De-Escalation & Emergency Principles',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SafeHerTheme.plumPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Trust your instincts: If a situation feels wrong, remove yourself immediately without waiting for confirmation.\n'
                      '2. Create distance: Move toward well-lit public spaces with open businesses.\n'
                      '3. Use verbal boundaries: Project confidence with a clear, firm voice.\n'
                      '4. Activate SafeHer SOS or dial 112/911 before a confrontation escalates.',
                      style: TextStyle(
                        fontSize: 13,
                        color: SafeHerTheme.textDark,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
