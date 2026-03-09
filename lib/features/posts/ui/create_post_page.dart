import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/app_snackbar.dart';
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
  bool _canSubmit = false;

  static const int _titleMax = 60;
  static const int _bodyMax = 200;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_recomputeCanSubmit);
    _bodyCtrl.addListener(_recomputeCanSubmit);
    _recomputeCanSubmit();
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_recomputeCanSubmit);
    _bodyCtrl.removeListener(_recomputeCanSubmit);
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

  void _recomputeCanSubmit() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final valid = title.isNotEmpty &&
        title.length <= _titleMax &&
        body.isNotEmpty &&
        body.length <= _bodyMax &&
        !_submitting;

    if (_canSubmit == valid) {
      return;
    }

    setState(() => _canSubmit = valid);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    setState(() {
      _submitting = true;
      _canSubmit = false;
    });

    try {
      await ref
          .read(postsViewModelProvider.notifier)
          .create(title: _titleCtrl.text.trim(), body: _bodyCtrl.text.trim());

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        'Não foi possível salvar o post. Tente novamente.',
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _recomputeCanSubmit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Post')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Titulo',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ate $_titleMax caracteres.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _titleCtrl,
                              textInputAction: TextInputAction.next,
                              maxLength: _titleMax,
                              decoration: InputDecoration(
                                hintText: 'Digite um titulo objetivo',
                                filled: true,
                                fillColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) =>
                                  _validateRequiredMax(v, _titleMax, 'Titulo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descricao',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use ate $_bodyMax caracteres.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _bodyCtrl,
                              maxLines: 6,
                              maxLength: _bodyMax,
                              decoration: InputDecoration(
                                hintText: 'Descreva o conteudo do post',
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) => _validateRequiredMax(
                                v,
                                _bodyMax,
                                'Descricao',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_submitting ? 'Salvando...' : 'Salvar post'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
