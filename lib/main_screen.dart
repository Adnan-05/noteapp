import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _noteController = TextEditingController();

  Future<void> addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('notes')
        .add({'text': _noteController.text.trim(), 'timestamp': Timestamp.now()});

    _noteController.clear();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final notesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('notes')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        actions: [
          IconButton(onPressed: logout, icon: Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                        hintText: 'Enter a note',
                        border: OutlineInputBorder()),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: addNote, child: Text('Add'))
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: notesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final notes = snapshot.data!.docs;

                if (notes.isEmpty)
                  return Center(child: Text('No notes yet'));

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      title: Text(note['text']),
                      subtitle: Text(
                          note['timestamp'].toDate().toString().substring(0, 16)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          note.reference.delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
