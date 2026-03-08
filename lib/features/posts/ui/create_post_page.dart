import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/posts_providers.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool _submitting = false;

  static const int _titleMax = 60;
  static const int _bodyMax = 200;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String? _validateRequiredMax(String? value, int max, String field) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$field e obrigatorio';
    if (v.length > max) return '$field deve ter no maximo $max caracteres';
    return null;
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    setState(() => _submitting = true);

    try {
      await ref.read(postsViewModelProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
          );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Post')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Preencha os campos abaixo para criar um post.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: _titleMax,
                  decoration: const InputDecoration(
                    labelText: 'Titulo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validateRequiredMax(v, _titleMax, 'Titulo'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  maxLength: _bodyMax,
                  decoration: const InputDecoration(
                    labelText: 'Descricao',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      _validateRequiredMax(v, _bodyMax, 'Descricao'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_submitting ? 'Salvando...' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
