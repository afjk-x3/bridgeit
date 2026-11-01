import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../progress/results_store.dart';
import '../theme/app_theme.dart';
import '../widgets/speech_bubble.dart';

const _maxFieldLength = 40;

/// The character's greeting, then the name and section form. Shown once.
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                height: 120,
                semanticsLabel: 'BridgeIt logo',
              ),
              const SizedBox(height: 16),
              if (_asking) _buildForm() else _buildGreeting(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SpeechBubble(
          "Hi, Bridge Builder! I'm ready to go on an adventure, but I need "
          'your help to reach my destination!',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'assets/images/girl_wave.svg',
              width: 150,
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
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() => _asking = true),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpeechBubble('Before we go, who is helping me today?'),
          const SizedBox(height: 8),
          _field(_name, 'Your name', TextInputAction.next),
          const SizedBox(height: 16),
          _field(_section, 'Your section', TextInputAction.done),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Text("Let's get started, Bridge Builder!"),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    TextInputAction action,
  ) {
    return TextFormField(
      controller: controller,
      maxLength: _maxFieldLength,
      textCapitalization: TextCapitalization.words,
      textInputAction: action,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Please fill this in.' : null,
    );
  }
}
