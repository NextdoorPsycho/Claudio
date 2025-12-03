import 'package:claudio/claudio.dart';
import 'package:claudio/services/interactive_wizard.dart';

/// Entry point for claudio CLI application
void main(List<String> arguments) async {
  // Launch interactive wizard if no arguments provided
  if (arguments.isEmpty) {
    await InteractiveWizard.run();
    return;
  }

  // Otherwise, run the standard CLI
  final ClaudioRunner runner = ClaudioRunner();
  await runner.run(arguments);
}
