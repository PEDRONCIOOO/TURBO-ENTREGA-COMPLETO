import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

class HtmlViewerScreen extends StatefulWidget {
  final bool isPrivacyPolicy;
  const HtmlViewerScreen({super.key, required this.isPrivacyPolicy});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  late Future<_HtmlResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHtml();
  }

  Future<_HtmlResult> _loadHtml() async {
    final uri = Uri.parse(
      widget.isPrivacyPolicy
          ? 'https://producao.turboentregas.com.br/api/v1/privacy-policy'
          : 'https://producao.turboentregas.com.br/api/v1/terms-and-conditions',
    );

    try {
      final res = await http.get(
        uri,
        headers: {
          'X-localization': 'pt', // ajuste se quiser controlar o idioma
          'Accept': 'text/html, application/json;q=0.9, */*;q=0.8',
        },
      );

      // Logs úteis em dev (remova em prod)
      // print('GET ${res.request?.url} -> ${res.statusCode}');
      // print(res.headers);
      // print(res.body.substring(0, res.body.length > 800 ? 800 : res.body.length));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return _HtmlResult.error(
          'Erro ${res.statusCode}',
          details: res.body.isEmpty ? 'Resposta vazia' : res.body,
        );
      }

      final ct = (res.headers['content-type'] ?? '').toLowerCase();
      String? html;

      if (ct.contains('text/html')) {
        // ✅ HTML puro vindo da API (recomendado)
        html = res.body.trim().isEmpty ? null : res.body;
      } else {
        // Possível JSON; tentar extrair HTML
        dynamic decoded;
        try {
          decoded = jsonDecode(res.body);
        } catch (_) {
          // não é JSON válido — tenta usar como HTML mesmo
          html = res.body.trim().isEmpty ? null : res.body;
        }

        if (decoded != null && html == null) {
          if (decoded is Map<String, dynamic>) {
            final data = decoded['data'];
            if (data is String) {
              html = data.trim().isEmpty ? null : data;
            } else if (data is Map && data['html'] is String) {
              html = (data['html'] as String).trim().isEmpty ? null : data['html'];
            } else if (decoded['html'] is String) {
              html = (decoded['html'] as String).trim().isEmpty ? null : decoded['html'];
            }
          } else if (decoded is String) {
            html = decoded.trim().isEmpty ? null : decoded;
          }
        }
      }

      if (html == null || html.trim().isEmpty) {
        return _HtmlResult.empty();
      }

      return _HtmlResult.ok(html);
    } catch (e) {
      return _HtmlResult.error('Falha ao carregar', details: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPrivacyPolicy ? 'Política de Privacidade' : 'Termos de Uso';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<_HtmlResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData) {
            return _ErrorView(
              title: 'Sem dados',
              message: 'Não foi possível obter o conteúdo.',
              onRetry: () => setState(() => _future = _loadHtml()),
            );
          }

          final res = snap.data!;
          switch (res.status) {
            case _HtmlStatus.ok:
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: HtmlWidget(
                  res.html!,
                  onTapUrl: (url) => launchUrlString(url, mode: LaunchMode.externalApplication),
                ),
              );
            case _HtmlStatus.empty:
              return _InfoView(
                icon: Icons.description_outlined,
                title: 'Conteúdo vazio',
                message: 'Nenhum conteúdo disponível no momento.',
                onRetry: () => setState(() => _future = _loadHtml()),
              );
            case _HtmlStatus.error:
              return _ErrorView(
                title: res.errorTitle ?? 'Erro',
                message: res.errorDetails ?? 'Ocorreu um erro inesperado.',
                onRetry: () => setState(() => _future = _loadHtml()),
              );
          }
        },
      ),
    );
  }
}

enum _HtmlStatus { ok, empty, error }

class _HtmlResult {
  final _HtmlStatus status;
  final String? html;
  final String? errorTitle;
  final String? errorDetails;

  _HtmlResult._(this.status, {this.html, this.errorTitle, this.errorDetails});

  factory _HtmlResult.ok(String html) => _HtmlResult._(_HtmlStatus.ok, html: html);
  factory _HtmlResult.empty() => _HtmlResult._(_HtmlStatus.empty);
  factory _HtmlResult.error(String title, {String? details}) =>
      _HtmlResult._(_HtmlStatus.error, errorTitle: title, errorDetails: details);
}

class _InfoView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _InfoView({super.key, required this.icon, required this.title, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _FeedbackScaffold(
      icon: icon,
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.title, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _FeedbackScaffold(
      icon: Icons.error_outline,
      title: title,
      message: message,
      onRetry: onRetry,
      expandableDetails: message.length > 120 ? message : null,
    );
  }
}

class _FeedbackScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? expandableDetails;
  final VoidCallback onRetry;
  const _FeedbackScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    this.expandableDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (expandableDetails != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('Detalhes técnicos'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(expandableDetails!),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
