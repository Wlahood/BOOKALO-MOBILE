import 'package:flutter/material.dart';

import '../models/venue_members.dart';
import '../repositories/venues_repository.dart';
import '../services/api_client.dart';

class VenueMembersScreen extends StatefulWidget {
  const VenueMembersScreen({super.key, required this.venueId});

  final int venueId;

  @override
  State<VenueMembersScreen> createState() => _VenueMembersScreenState();
}

class _VenueMembersScreenState extends State<VenueMembersScreen> {
  late final VenuesRepository repo;
  late Future<VenueMembersData> _future;

  final emailCtrl = TextEditingController();

  bool inviteSaving = false;
  String? selectedInviteRole;

  @override
  void initState() {
    super.initState();
    repo = VenuesRepository(ApiClient());
    _future = repo.fetchVenueMembers(widget.venueId);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = repo.fetchVenueMembers(widget.venueId);
    });
  }

  String _roleLabel(String role) {
    return role.replaceAll('_', ' ');
  }

  Future<void> _invite(VenueMembersData data) async {
    final email = emailCtrl.text.trim();
    final role = selectedInviteRole;

    if (email.isEmpty || role == null || role.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inserisci email e ruolo')));
      return;
    }

    setState(() => inviteSaving = true);

    try {
      await repo.inviteVenueMember(widget.venueId, email: email, role: role);

      emailCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invito inviato')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invio fallito: $e')));
    } finally {
      if (mounted) {
        setState(() => inviteSaving = false);
      }
    }
  }

  Future<void> _changeRole(VenueMemberItem member, String role) async {
    try {
      await repo.updateVenueMemberRole(
        widget.venueId,
        userId: member.id,
        role: role,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ruolo aggiornato')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Aggiornamento fallito: $e')));
    }
  }

  Future<void> _removeMember(VenueMemberItem member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rimuovere membro?'),
        content: Text('Vuoi rimuovere ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repo.removeVenueMember(widget.venueId, userId: member.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Membro rimosso')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rimozione fallita: $e')));
    }
  }

  Future<void> _revokeInvite(VenueInviteItem invite) async {
    try {
      await repo.revokeInvite(invite.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invito revocato')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Revoca fallita: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestisci membri')),
      body: FutureBuilder<VenueMembersData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Errore: ${snap.error}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reload,
                  child: const Text('Riprova'),
                ),
              ],
            );
          }

          final data = snap.data!;
          selectedInviteRole ??= data.invitableRoles.isNotEmpty
              ? data.invitableRoles.first
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data.venue.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              Text(
                'Invita membro',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedInviteRole,
                        decoration: const InputDecoration(
                          labelText: 'Ruolo',
                          border: OutlineInputBorder(),
                        ),
                        items: data.invitableRoles
                            .map(
                              (role) => DropdownMenuItem<String>(
                                value: role,
                                child: Text(_roleLabel(role)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedInviteRole = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: inviteSaving ? null : () => _invite(data),
                        icon: inviteSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(inviteSaving ? 'Invio...' : 'Invia invito'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text('Membri', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: data.members.map((member) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(member.name),
                              subtitle: Text(member.email),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeMember(member),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: member.role,
                              decoration: const InputDecoration(
                                labelText: 'Ruolo',
                                border: OutlineInputBorder(),
                              ),
                              items: data.assignableRoles
                                  .map(
                                    (role) => DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(_roleLabel(role)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null || value == member.role)
                                  return;
                                _changeRole(member, value);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Inviti pendenti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (data.pendingInvites.isEmpty)
                const Text('Nessun invito pendente.')
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: data.pendingInvites.map((invite) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(invite.email),
                          subtitle: Text(
                            'Ruolo: ${_roleLabel(invite.role)}'
                            '${invite.expiresAt != null ? '\nScade: ${invite.expiresAt}' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _revokeInvite(invite),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
