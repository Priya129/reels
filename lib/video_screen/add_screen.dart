import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../global/app_colors.dart';


class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  Uint8List? file;
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  VideoPlayerController? _videoPlayerController;
  bool _isUploading = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoPlayerController?.dispose();

    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        File videoFile = File(pickedFile.path);
        _videoPlayerController = VideoPlayerController.file(videoFile)
          ..initialize().then((_) {
            setState(() {
              _videoPlayerController?.play();
            });
          });
        setState(() {
          file = videoFile.readAsBytesSync();
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _uploadRecipe() async {
    if (file == null) {
      print('Please select a video');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('videos/$fileName');
      UploadTask uploadTask = storageRef.putData(file!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      String uid = _firebaseAuth.currentUser?.uid ?? '';
      String postId = const Uuid().v1();

      await FirebaseFirestore.instance.collection('videos').doc(postId).set({
        'postId': postId,
        'description': _descriptionController.text,
        'videoUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': uid,
        'likes': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully')),
      );

      setState(() {
        file = null;
        _descriptionController.clear();
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
      });
    } catch (e) {
      print('Error uploading recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading video')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Upload new Video Recipe',
          style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.mainColor,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mainColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          _isUploading
              ? const Padding(
            padding: EdgeInsets.only(right: 25.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
            ),
          )
              : GestureDetector(
            onTap:
            _uploadRecipe,
            child: const Padding(
              padding: EdgeInsets.only(right: 25.0),
              child: Text(
                "Post",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: AppColors.mainColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
              child: GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: screenHeight * 0.6,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.mainColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: file != null
                      ? _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoPlayerController!.value.size.width,
                        height: _videoPlayerController!.value.size.height,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    ),
                  )
                      : const Center(child: CircularProgressIndicator())
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 50, color: AppColors.mainColor),
                      SizedBox(height: 8),
                      Text(
                        'Upload Video',
                        style: TextStyle(color: AppColors.mainColor, fontSize: 16),
                      ),
                      Text(
                        'Click here to upload a video',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
              child: TextField(
                maxLines: 2,
                maxLength: 300,
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: AppColors.mainColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}