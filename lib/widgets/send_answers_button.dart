import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../progress/results_store.dart';
import '../report/answer_sender.dart';

/// Builds the answer report and opens the share sheet.
class SendAnswersButton extends StatefulWidget {
  const SendAnswersButton({super.key, this.label = 'Send my answers'});

  final String label;

  @override
  State<SendAnswersButton> createState() => _SendAnswersButtonState();
}

class _SendAnswersButtonState extends State<SendAnswersButton> {
  bool _sending = false;

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    final sender = context.read<AnswerSender>();
    final results = context.read<ResultsStore>();
    setState(() => _sending = true);
    try {
      await sender.send(results);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't send your answers. Try again.")),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _sending ? null : _send,
      icon: const Icon(Icons.send),
      label: Text(widget.label),
    );
  }
}
