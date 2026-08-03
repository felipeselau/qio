import 'package:flutter/material.dart';

import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_input.dart';
import 'queue_panel_screen.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '10');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final queue = await QueueService.instance.createQueue(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        avgServiceMin: int.tryParse(_timeCtrl.text.trim()) ?? 10,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                QueuePanelScreen(queueId: queue.id, queueName: queue.name),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: QioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova fila')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QioInput(
                  label: 'Nome da fila *',
                  hint: 'Ex: Atendimento balcão',
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                QioInput(
                  label: 'Descrição (opcional)',
                  hint: 'Detalhes do atendimento',
                  controller: _descCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                QioInput(
                  label: 'Tempo médio de atendimento (minutos)',
                  hint: '10',
                  controller: _timeCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Informe um número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                QioButton(
                  label: 'Criar fila',
                  onPressed: _create,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
