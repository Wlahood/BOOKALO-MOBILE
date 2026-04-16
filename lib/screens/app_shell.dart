import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

import '../repositories/notifications_repository.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _notificationsRepo = NotificationsRepository(ApiClient());
  int _unreadNotifications = 0;

  List<Widget> _pagesFor(AuthState auth) {
    return [const HomeScreen(), const SearchScreen(), const ProfileScreen()];
  }

  @override
  void initState() {
    super.initState();
    AuthController.instance.bootstrap();
    AuthController.instance.state.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  @override
  void dispose() {
    AuthController.instance.state.removeListener(_handleAuthChanged);
    super.dispose();
  }

  Future<void> _handleAuthChanged() async {
    final auth = AuthController.instance.state.value;

    if (auth.status != AuthStatus.authenticated) {
      if (mounted) {
        setState(() => _unreadNotifications = 0);
      }
      return;
    }

    try {
      final count = await _notificationsRepo.fetchUnreadCount();
      if (!mounted) {
        return;
      }
      setState(() => _unreadNotifications = count);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _unreadNotifications = 0);
    }
  }

  Widget _buildProfileIcon() {
    if (_unreadNotifications <= 0) {
      return const Icon(Icons.person_outline);
    }

    return Badge(
      label: Text(_unreadNotifications > 99 ? '99+' : '$_unreadNotifications'),
      child: const Icon(Icons.person_outline),
    );
  }

  Widget _buildProfileActiveIcon() {
    if (_unreadNotifications <= 0) {
      return const Icon(Icons.person);
    }

    return Badge(
      label: Text(_unreadNotifications > 99 ? '99+' : '$_unreadNotifications'),
      child: const Icon(Icons.person),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthController.instance.state,
      builder: (context, auth, _) {
        final pages = _pagesFor(auth);

        return PopScope(
          canPop: _index == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }

            if (_index != 0) {
              setState(() => _index = 0);
            }
          },
          child: Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) async {
                if (i == 2 && auth.status != AuthStatus.authenticated) {
                  final navigator = Navigator.of(context);

                  await navigator.push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );

                  await _handleAuthChanged();

                  if (!mounted) {
                    return;
                  }

                  setState(() => _index = 2);
                  return;
                }

                if (i == 2) {
                  await _handleAuthChanged();
                }

                if (!mounted) {
                  return;
                }

                setState(() => _index = i);
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Cerca',
                ),
                BottomNavigationBarItem(
                  icon: _buildProfileIcon(),
                  activeIcon: _buildProfileActiveIcon(),
                  label: 'Profilo',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GuestProfileScreen extends StatelessWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Non sei autenticato',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Accedi per sbloccare le funzioni riservate.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Accedi'),
            ),
          ],
        ),
      ),
    );
  }
}
