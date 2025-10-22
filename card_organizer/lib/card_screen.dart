import 'package:flutter/material.dart';
import 'database_helper.dart';

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardsScreen({required this.folderId, required this.folderName});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await _dbHelper.getCardsInFolder(widget.folderId);
    setState(() {
      _cards = cards;
    });
  }

  Future<void> _showAddCardDialog() async {
    final count = await _dbHelper.getCardCountInFolder(widget.folderId);
    if (count >= 6) {
      _showErrorDialog('This folder can only hold 6 cards.');
      return;
    }

    final availableCards = await _dbHelper.getAvailableCards(widget.folderName);
    if (availableCards.isEmpty) {
      _showErrorDialog('No more cards available for this suit.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Card to ${widget.folderName}'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCards.length,
            itemBuilder: (context, index) {
              final card = availableCards[index];
              return ListTile(
                leading: Image.network(
                  card['image_url'],
                  width: 40,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.card_giftcard),
                ),
                title: Text('${card['name']} of ${card['suit']}'),
                onTap: () async {
                  await _dbHelper.addCardToFolder(card['id'], widget.folderId);
                  Navigator.pop(context);
                  _loadCards();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Card added successfully')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(int cardId, String cardName) async {
    final count = await _dbHelper.getCardCountInFolder(widget.folderId);
    if (count <= 3) {
      _showErrorDialog('You need at least 3 cards in this folder.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Card'),
        content: Text('Remove "$cardName" from this folder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.removeCardFromFolder(cardId);
              Navigator.pop(context);
              _loadCards();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Card removed successfully')),
              );
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: Colors.blue,
      ),
      body: _cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No cards in this folder', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to add cards', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          card['image_url'],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.card_giftcard, size: 80),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              '${card['name']} of ${card['suit']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCard(
                                card['id'],
                                '${card['name']} of ${card['suit']}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Card',
      ),
    );
  }
}
