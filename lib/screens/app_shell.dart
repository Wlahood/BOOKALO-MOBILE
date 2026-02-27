import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'search_screen.dart';

import 'login_screen.dart';
import '../services/auth_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<Widget> _pagesFor(AuthState auth) {
    return [
      const HomeScreen(),
      const SearchScreen(),
      auth.status == AuthStatus.authenticated
          ? const ProfilePlaceholderScreen()
          : const GuestProfileScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    AuthController.instance.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthController.instance.state,
      builder: (context, auth, _) {
        final pages = _pagesFor(auth);

        return WillPopScope(
          onWillPop: () async {
            if (_index != 0) {
              setState(() => _index = 0);
              return false;
            }
            return true;
          },
          child: Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) async {
                // Se l'utente tocca "Profilo" (tab 2) ed è guest, lo mando al login
                if (i == 2 && auth.status != AuthStatus.authenticated) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );

                  // Dopo login, aggiorna lo stato (LoginScreen già fa login->state authenticated)
                  // e resta sul tab profilo:
                  setState(() => _index = 2);
                  return;
                }

                setState(() => _index = i);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Cerca',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
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

class SearchPlaceholderScreen extends StatelessWidget {
  const SearchPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cerca')),
      body: const Center(
        child: Text('Qui arriverà la ricerca (/api/v1/search).'),
      ),
    );
  }
}

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance.state.value;
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Utente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(user?.email ?? ''),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => AuthController.instance.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
            const SizedBox(height: 12),
            Text(
              'Qui arriveranno profilo / preferenze / claim.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
