import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../config.dart';
import '../screens/event_detail_screen.dart';
import '../screens/band_detail_screen.dart';
import '../screens/venue_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/workspace/messages_screen.dart';
import '../screens/workspace/board_screen.dart';
import '../screens/workspace/account_screen.dart';
import '../screens/workspace/workflow_form_screen.dart';
import 'auth_controller.dart';

class LinkRouter {
  LinkRouter(this.navigatorKey);
  final GlobalKey<NavigatorState> navigatorKey;
  final _links = AppLinks();
  StreamSubscription<Uri>? _subscription;
  final _queue = <Uri>[];
  bool _routing = false;
  String? _last;
  DateTime? _lastAt;
  Future<void> start() async {
    _subscription = _links.uriLinkStream.listen(open, onError: (_) {});
    final initial = await _links.getInitialLink();
    if (initial != null) open(initial);
  }

  void dispose() => _subscription?.cancel();
  void open(Uri uri) {
    if (uri.scheme != 'bookalo' && !['http', 'https'].contains(uri.scheme)) {
      return;
    }
    if (uri.scheme != 'bookalo' &&
        uri.host != Uri.parse(apiBaseUrl).host &&
        uri.host != Uri.parse(webBaseUrl).host) {
      return;
    }
    if (_last == uri.toString() &&
        _lastAt != null &&
        DateTime.now().difference(_lastAt!).inSeconds < 2) {
      return;
    }
    _last = uri.toString();
    _lastAt = DateTime.now();
    _queue.add(uri);
    _drain();
  }

  Future<void> _drain() async {
    if (_routing) return;
    _routing = true;
    try {
      while (_queue.isNotEmpty) {
        await _route(_queue.removeAt(0));
      }
    } finally {
      _routing = false;
    }
  }

  Future<void> _route(Uri uri) async {
    final segments = [
      if (uri.scheme == 'bookalo' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];
    final id = segments.length > 1
        ? int.tryParse(segments.last.split('-').first)
        : null;
    Widget? page;
    bool requiresLogin = false;
    if (segments.contains('reset-password')) {
      page = ResetPasswordScreen(
        link: uri.scheme == 'bookalo'
            ? uri.queryParameters['url']
            : uri.toString(),
      );
    } else if (segments.contains('verify-email')) {
      requiresLogin = true;
      page = WorkflowFormScreen(
        title: 'Verifica email',
        path: '/me/email/verify',
        initial: {'url': uri.queryParameters['url'] ?? uri.toString()},
        fields: const [
          FormFieldSpec('url', 'Link di verifica ricevuto', required: true),
        ],
      );
    } else if (segments.contains('invites') ||
        segments.contains('campaign-invites')) {
      requiresLogin = true;
      page = WorkflowFormScreen(
        title: 'Accetta invito',
        path: '/me/invites/accept',
        initial: {
          'token': segments.last,
          'kind': segments.contains('campaign-invites') ? 'campaign' : 'entity',
        },
        fields: const [
          FormFieldSpec('token', 'Codice invito', required: true),
          FormFieldSpec(
            'kind',
            'Tipo',
            kind: InputKind.choice,
            choices: {
              'entity': 'Invito profilo',
              'campaign': 'Invito campagna',
            },
            required: true,
          ),
        ],
      );
    } else if ((segments.contains('thread') || segments.contains('threads')) &&
        id != null) {
      requiresLogin = true;
      page = ThreadScreen(threadId: id);
    } else if ((segments.contains('event') || segments.contains('events')) &&
        id != null) {
      page = EventDetailScreen(eventId: id);
    } else if ((segments.contains('band') || segments.contains('bands')) &&
        id != null) {
      page = BandDetailScreen(bandId: id);
    } else if ((segments.contains('venue') || segments.contains('venues')) &&
        id != null) {
      page = VenueDetailScreen(venueId: id);
    } else if (segments.contains('bacheca')) {
      requiresLogin = true;
      page = const BoardScreen();
    } else if (segments.contains('notifications')) {
      requiresLogin = true;
      page = const NotificationsScreen();
    }
    if (page == null) return;
    if (requiresLogin) {
      final auth = AuthController.instance;
      if ([
        AuthStatus.unknown,
        AuthStatus.loading,
      ].contains(auth.state.value.status)) {
        final ready = Completer<void>();
        void listener() {
          if (![
                AuthStatus.unknown,
                AuthStatus.loading,
              ].contains(auth.state.value.status) &&
              !ready.isCompleted) {
            ready.complete();
          }
        }

        auth.state.addListener(listener);
        listener();
        try {
          await ready.future.timeout(const Duration(seconds: 50));
        } catch (_) {
          return;
        } finally {
          auth.state.removeListener(listener);
        }
      }
      if (auth.state.value.status != AuthStatus.authenticated) {
        await navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      if (auth.state.value.status != AuthStatus.authenticated) return;
    }
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page!));
  }
}

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, this.link});
  final String? link;
  @override
  Widget build(BuildContext context) => WorkflowFormScreen(
    title: 'Reimposta password',
    path: '/auth/reset-password',
    initial: {'reset_url': link},
    fields: const [
      FormFieldSpec('reset_url', 'Link ricevuto via email', required: true),
      FormFieldSpec(
        'password',
        'Nuova password',
        kind: InputKind.password,
        required: true,
      ),
      FormFieldSpec(
        'password_confirmation',
        'Conferma password',
        kind: InputKind.password,
        required: true,
      ),
    ],
  );
}
