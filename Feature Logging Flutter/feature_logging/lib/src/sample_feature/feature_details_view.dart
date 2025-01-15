import 'package:flutter/material.dart';

/// Displays an editor to author a Feature.
class FeatureEditorView extends StatelessWidget {
  const FeatureEditorView({super.key});

  static const routeName = '/feature';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Details'),
      ),
      body: const Center(
        child: Text('Information about the feature (editor) goes here'),
      ),
    );
  }
}
