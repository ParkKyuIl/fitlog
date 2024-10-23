import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  ReviewDetailPage({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(imageUrl),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
            ),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      children: [
        Text(
          '후기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        _buildCommentsList(),
        _buildCommentInputField(),
      ],
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .doc(title)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        var comments = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: comments.length,
          itemBuilder: (context, index) {
            var comment = comments[index];
            return ListTile(
              title: Text(comment['text']),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    TextEditingController _controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: '이곳에서의 운동은 어땠나요?'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              var text = _controller.text;
              if (text.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('reviews')
                    .doc(title)
                    .collection('comments')
                    .add({'text': text});
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
