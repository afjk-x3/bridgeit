import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../progress/results_store.dart';
import '../widgets/speech_bubble.dart';
import 'start_screen.dart';

const _maxFieldLength = 40;

/// The character's greeting on every Play. A new player then fills in the
/// name and section form; a returning one is greeted by name and goes on to
/// the level menu.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _section = TextEditingController();
  bool _asking = false;

  @override
  void dispose() {
    _name.dispose();
    _section.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await context.read<ResultsStore>().saveProfile(_name.text, _section.text);
    if (mounted) Navigator.pushReplacementNamed(context, '/levels');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (!_asking)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BridgeStrip(),
            ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SvgPicture.asset(
                          'assets/images/logo.svg',
                          height: 96,
                          semanticsLabel: 'BridgeIt logo',
                        ),
                        const SizedBox(height: 12),
                        if (_asking) _buildForm() else _buildGreeting(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: _asking
                      ? FilledButton(
                          onPressed: _submit,
                          child: const Text(
                            "Let's get started, Bridge Builder!",
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(120, 52),
                            ),
                            onPressed: () =>
                                context.read<ResultsStore>().profile == null
                                ? setState(() => _asking = true)
                                : Navigator.pushReplacementNamed(
                                    context,
                                    '/levels',
                                  ),
                            child: const Text('Next'),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final name = context.read<ResultsStore>().profile?.name ?? 'Bridge Builder';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpeechBubble(
          "Hi, $name! I'm ready to go on an adventure, but I need your help "
          'to reach my destination!',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'assets/images/girl_wave.svg',
              width: 130,
              semanticsLabel: 'Your guide, waving',
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SpeechBubble(
                    'Complete each level, choose the correct coordinating '
                    'conjunctions, and build and strengthen the bridges along '
                    'the way.',
                  ),
                  SpeechBubble(
                    'Every correct answer brings me one step closer to my '
                    'destination!',
                  ),
                  SpeechBubble(
                    'Are you ready to build the bridges and connect the '
                    'clauses?',
                    strong: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        // Room for the bridge strip under the guide.
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SvgPicture.asset(
                'assets/images/girl_journal.svg',
                height: 180,
                semanticsLabel: 'Your guide, holding her journal',
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: SpeechBubble('Before we go, who is helping me today?'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    _name,
                    'Your name',
                    'e.g. Juan Dela Cruz',
                    TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _section,
                    'Your section',
                    'e.g. Grade 8 - Rizal',
                    TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your teacher sees these with your answers.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    TextInputAction action,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLength: _maxFieldLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: action,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          decoration: InputDecoration(hintText: hint),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please fill this in.'
              : null,
        ),
      ],
    );
  }
}
