import 'package:material_ui/material_ui.dart';

void main() => runApp(const EcoEatsApp());

class EcoEatsApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EcoEats',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('EcoEats'))),
    );
  }
}
