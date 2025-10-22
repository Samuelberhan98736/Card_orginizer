import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'card_screen.dart';

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> _folders = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _dbHelper.getFolders();
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _showDeleteConfirmation(int folderId, String folderName) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder'),
        content: Text('Are you sure you want to delete "$folderName" and all its cards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteFolder(folderId);
              Navigator.pop(context);
              _loadFolders();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Folder deleted successfully')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFolderDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Folder'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _dbHelper.createFolder(controller.text);
                Navigator.pop(context);
                _loadFolders();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getSuitColor(String folderName) {
    if (folderName == 'Hearts' || folderName == 'Diamonds') {
      return Colors.red;
    }
    return Colors.black;
  }

  IconData _getSuitIcon(String folderName) {
    switch (folderName) {
      case 'Hearts': return Icons.favorite;
      case 'Diamonds': return Icons.diamond;
      case 'Spades': return Icons.spa;
      case 'Clubs': return Icons.cloud;
      default: return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
        backgroundColor: Colors.blue,
      ),
      body: _folders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return FutureBuilder<int>(
                  future: _dbHelper.getCardCountInFolder(folder['id']),
                  builder: (context, countSnapshot) {
                    final cardCount = countSnapshot.data ?? 0;
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _dbHelper.getFirstCardInFolder(folder['id']),
                      builder: (context, cardSnapshot) {
                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CardsScreen(
                                    folderId: folder['id'],
                                    folderName: folder['folder_name'],
                                  ),
                                ),
                              );
                              _loadFolders();
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.grey[100],
                                    child: cardSnapshot.hasData && cardSnapshot.data != null
                                        ? Image.network(
                                            cardSnapshot.data!['image_url'],
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(_getSuitIcon(folder['folder_name']), 
                                                     size: 80, 
                                                     color: _getSuitColor(folder['folder_name'])),
                                          )
                                        : Icon(_getSuitIcon(folder['folder_name']), 
                                               size: 80, 
                                               color: _getSuitColor(folder['folder_name'])),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Text(
                                        folder['folder_name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getSuitColor(folder['folder_name']),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text('$cardCount cards'),
                                      SizedBox(height: 4),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _showDeleteConfirmation(
                                          folder['id'],
                                          folder['folder_name'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Folder (Bonus)',
      ),
    );
  }
}
