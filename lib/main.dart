import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const NotesPage(),
    );//HIIIII THIS IS AIDYN
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController controller = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // CREATE
  Future<void> addNote(String text) async {
    await db.collection("notes").add({
      "text": text,
      "time": Timestamp.now(),
    });
  }

  // DELETE
  Future<void> deleteNote(String id) async {
    await db.collection("notes").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase CRUD Demo")),

      body: Column(
        children: [

          // INPUT BOX
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter note",
              ),
            ),
          ),

          // ADD BUTTON
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                addNote(controller.text);
                controller.clear();
              }
            },
            child: const Text("Add Note"),
          ),

          const SizedBox(height: 10),

          // READ DATA (REAL-TIME)
          Expanded(
            child: StreamBuilder(
              stream: db
                  .collection("notes")
                  .orderBy("time", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final doc = notes[index];

                    return Card(
                      child: ListTile(
                        title: Text(doc["text"]),

                        // DELETE BUTTON
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteNote(doc.id),
                        ),
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