import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../utils/friendly_error.dart';

class TeamSeasonScreen extends StatefulWidget {
  const TeamSeasonScreen({super.key});

  @override
  State<TeamSeasonScreen> createState() => _TeamSeasonScreenState();
}

class _TeamSeasonScreenState extends State<TeamSeasonScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _teamNameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final name = _teamNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team name')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Enforce 1-team-per-coach limit
      final existing = await _firestore
          .collection('teams')
          .where('coachIds', arrayContains: user.uid)
          .where('ended', isEqualTo: false)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have an active team')), 
        );
        return;
      }
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 100));
      final teamDoc = _firestore.collection('teams').doc();
      final teamId = teamDoc.id;

      await teamDoc.set({
        'teamId': teamId,
        'name': name,
        'coachIds': [user.uid],
        'playerIds': [],
        'settings': {},
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'ended': false,
        'expiresAt': expiresAt.toIso8601String(),
      });

      final callable = FirebaseFunctions.instance.httpsCallable('createInviteCode');
      await callable.call({'teamId': teamId, 'role': 'player', 'ttlHours': 48});

      await _firestore.collection('users').doc(user.uid).set({'teamId': teamId}, SetOptions(merge: true));
      _teamNameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, "Couldn't create the team")), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _endSeason(String teamId) async {
    try {
      await _firestore.collection('teams').doc(teamId).update({
        'ended': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final activeInvites = await _firestore
          .collection('inviteCodes')
          .where('teamId', isEqualTo: teamId)
          .where('active', isEqualTo: true)
          .get();
      for (final doc in activeInvites.docs) {
        await doc.reference.update({'active': false});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Season ended'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, "Couldn't end the season")), backgroundColor: Colors.red),
      );
    }
  }

  DateTime _parseDate(dynamic raw, {DateTime? fallback}) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? (fallback ?? DateTime.now());
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return fallback ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Team')),
      body: user == null
          ? const Center(child: Text('Please sign in', style: TextStyle(color: Colors.black)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('teams')
                  .where('coachIds', arrayContains: user.uid)
                  .where('ended', isEqualTo: false)
                  .limit(1)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildCreateLayout();
                }
                final teamDoc = snap.data!.docs.first;
                final data = teamDoc.data();
                final teamId = data['teamId'] as String;
                final createdAt = _parseDate(data['createdAt']);
                final expiresAt = _parseDate(data['expiresAt'], fallback: createdAt.add(const Duration(days: 100)));
                if (DateTime.now().isAfter(expiresAt)) {
                  _endSeason(teamId);
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }
                return _buildSeasonActiveLayout(teamId, data, createdAt, expiresAt);
              },
            ),
    );
  }

  Widget _buildCreateLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header('CREATE TEAM', 'Start your season'),
        const SizedBox(height: 16),
        _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Team Name', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 8),
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(hintText: 'Enter your team name', border: OutlineInputBorder()),
              style: GoogleFonts.poppins(color: Colors.black),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _createTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_busy ? 'Creating…' : 'Create Team', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSeasonActiveLayout(String teamId, Map<String, dynamic> data, DateTime createdAt, DateTime expiresAt) {
    final inviteStream = _firestore
        .collection('inviteCodes')
        .where('teamId', isEqualTo: teamId)
        .where('active', isEqualTo: true)
        .limit(1)
        .snapshots();
    final rosterStream = _firestore.collection('teams').doc(teamId).collection('roster_entries').snapshots();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header((data['name'] ?? 'Team').toString(), 'Season Active'),
        const SizedBox(height: 16),
        // Invite Code
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: inviteStream,
          builder: (context, snap) {
            String code = '…';
            if (snap.hasData && snap.data!.docs.isNotEmpty) {
              code = (snap.data!.docs.first.data()['code'] ?? '').toString();
            }
            return _card(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Invite Code', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 8),
                    SelectableText(code, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ]),
                ),
                IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: code)), icon: const Icon(Icons.copy, color: Colors.black)),
              ]),
            );
          },
        ),
        const SizedBox(height: 16),
        // Dates
        _card(
          child: Row(children: [
            Expanded(child: _dateTile('Start Date', createdAt)),
            const SizedBox(width: 12),
            Expanded(child: _dateTile('Expiry Date', expiresAt)),
          ]),
        ),
        const SizedBox(height: 16),
        // Roster
        _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Roster', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: rosterStream,
              builder: (context, rs) {
                if (rs.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }
                final docs = rs.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Text('No players yet', style: GoogleFonts.poppins(color: Colors.grey[600], fontStyle: FontStyle.italic));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final name = (d['name'] ?? d['playerId'] ?? '').toString();
                    final jersey = (d['jerseyNumber'] ?? '').toString();
                    final pos = (d['position'] ?? 'Player').toString();
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.black, child: Text(jersey.isEmpty ? '?' : jersey, style: const TextStyle(color: Colors.white))),
                      title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('Position: $pos', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    );
                  },
                );
              },
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _endSeason(teamId),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('End Season', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        )
      ]),
    );
  }

  Widget _header(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.black, Colors.black87]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFFC0C0C0), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
      ]),
      child: child,
    );
  }

  Widget _dateTile(String title, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Text('${date.day}/${date.month}/${date.year}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}


