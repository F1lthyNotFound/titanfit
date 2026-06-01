import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app PayMongo checkout — closes when success/cancel URLs are reached.
class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.checkoutUrl,
  });

  final String checkoutUrl;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (_isSuccessUrl(url)) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (_isCancelUrl(url)) {
              _finish(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isSuccessUrl(String url) {
    return url.contains('/paymongo/wallet-success') || url.startsWith('titanfit://wallet');
  }

  bool _isCancelUrl(String url) {
    return url.contains('/paymongo/wallet-cancel') ||
        url.contains('status=cancelled') ||
        url.startsWith('titanfit://wallet') && url.contains('status=cancelled');
  }

  void _finish(bool success) {
    if (!mounted) return;
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Complete payment'),
        backgroundColor: const Color(0xFF000000),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
