import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:reelsapp/comment/comment_text_field.dart';
import 'comment_card.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  User? currentUser;
  String? profileImageUrl;
  String? username;
  String? userid;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          currentUser = user;
          profileImageUrl = userDoc['imageUrl'];
          username = userDoc['username'];
          userid = user.uid;
        });
      }
    }
  }

  void _scrollToButtom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        child: Container(
          height: screenHeight * 0.78,
          padding: EdgeInsets.only(top: screenHeight * 0.02),
          child: Column(
            children: [
              Expanded(
                  child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('videos')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {}
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error loading comments'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No comments yet'),
                          );
                        }
                        return ListView.builder(
                            controller: _scrollController,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var commentData = snapshot.data!.docs[index];
                              bool isOwnerOrCommenter =
                                  currentUser?.uid == commentData['userid'];
                              return CommentCard(
                                  commentId: commentData['commentId'],
                                  recipeId: widget.postId,
                                  username: commentData['username'],
                                  comment: commentData['text'],
                                  profileImageUrl: commentData['imageUrl'],
                                  likes:
                                      List<String>.from(commentData['likes']),
                                  isOwnerOrCommenter: isOwnerOrCommenter,
                                  onDelete: () =>
                                      _deleteComment(commentData['commentId']));
                            });
                      })),
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: CommentInputField(
                    profileImageUrl: profileImageUrl,
                    recipeId: widget.postId,
                    username: username,
                    onCommentSubmitted: _scrollToButtom,
                    userid: userid),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
