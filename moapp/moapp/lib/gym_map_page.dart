import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Gym {
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  String? imageUrl;
  double rating;

  Gym({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.rating = 0.0,
  });

  factory Gym.fromDocument(DocumentSnapshot doc) {
    return Gym(
      name: doc['name'],
      description: doc['description'],
      latitude: doc['latitude'],
      longitude: doc['longitude'],
      imageUrl: doc['imageUrl'],
      rating: doc['rating'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}

class GymMapPage extends StatefulWidget {
  @override
  _GymMapPageState createState() => _GymMapPageState();
}

class _GymMapPageState extends State<GymMapPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 10.0,
  );
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((_) {
      _initializeMarkers();
      _isMapInitialized = true;
      setState(() {});
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.0,
      );
    });
  }

  void _initializeMarkers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('gyms').get();
    for (var doc in snapshot.docs) {
      final gym = Gym.fromDocument(doc);
      markers.add(
        Marker(
          markerId: MarkerId(gym.name),
          position: LatLng(gym.latitude, gym.longitude),
          infoWindow: InfoWindow(
            title: gym.name,
            snippet:
                '${gym.description}\nRating: ${gym.rating.toStringAsFixed(1)}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GymDetailPage(gym: gym),
                ),
              );
            },
          ),
        ),
      );
    }
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _goToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    mapController.animateCamera(CameraUpdate.newLatLng(
      LatLng(position.latitude, position.longitude),
    ));
  }

  void _addMarker(LatLng position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController descriptionController = TextEditingController();
        double rating = 0.0;

        return AlertDialog(
          title: Text("Add Gym"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Gym Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              Text('Rating'),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (ratingValue) {
                  rating = ratingValue;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final gym = Gym(
                  name: nameController.text,
                  description: descriptionController.text,
                  latitude: position.latitude,
                  longitude: position.longitude,
                  rating: rating,
                );

                await FirebaseFirestore.instance
                    .collection('gyms')
                    .add(gym.toMap());

                _initializeMarkers();

                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gym Locations'),
      ),
      body: Stack(
        children: [
          if (_isMapInitialized)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCameraPosition,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onLongPress: _addMarker,
            ),
          if (!_isMapInitialized)
            Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              child: Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class GymDetailPage extends StatefulWidget {
  final Gym gym;

  GymDetailPage({required this.gym});

  @override
  _GymDetailPageState createState() => _GymDetailPageState();
}

class _GymDetailPageState extends State<GymDetailPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  double _commentRating = 0.0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
    _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final firebaseStorageRef =
        FirebaseStorage.instance.ref().child('gym_images').child(fileName);

    final uploadTask = firebaseStorageRef.putFile(_image!);
    final taskSnapshot = await uploadTask.whenComplete(() => {});

    final downloadUrl = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('gyms')
        .where('name', isEqualTo: widget.gym.name)
        .get()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.update({'imageUrl': downloadUrl});
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('이미지가 변경되었습니다!'),
      ),
    );
    setState(() {
      widget.gym.imageUrl = downloadUrl;
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      User? user = _auth.currentUser;
      String? userName = user?.displayName ?? 'Anonymous'; // 로그인된 사용자의 이름

      await _firestore
          .collection('gyms')
          .doc(widget.gym.name)
          .collection('comments')
          .add({
        'text': _commentController.text,
        'user': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'rating': _commentRating,
        'userId': user?.uid,
      });

      _updateGymRating();

      _commentController.clear();
      setState(() {
        _commentRating = 0.0;
      });
    }
  }

  Future<void> _updateGymRating() async {
    QuerySnapshot commentsSnapshot = await _firestore
        .collection('gyms')
        .doc(widget.gym.name)
        .collection('comments')
        .get();

    if (commentsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in commentsSnapshot.docs) {
        totalRating += doc['rating'];
      }
      double averageRating = totalRating / commentsSnapshot.docs.length;

      await _firestore
          .collection('gyms')
          .doc(widget.gym.name)
          .update({'rating': averageRating});

      setState(() {
        widget.gym.rating = averageRating;
      });
    }
  }

  Future<void> _deleteComment(DocumentSnapshot comment) async {
    await _firestore
        .collection('gyms')
        .doc(widget.gym.name)
        .collection('comments')
        .doc(comment.id)
        .delete();

    _updateGymRating();
  }

  Stream<QuerySnapshot> _getCommentsStream() {
    return _firestore
        .collection('gyms')
        .doc(widget.gym.name)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gym.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.gym.imageUrl != null)
              Image.network(
                widget.gym.imageUrl!,
                fit: BoxFit.cover,
              )
            else
              Text('No image available'),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.gym.description,
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '체육관 후기를 남겨주세요!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _commentRating = rating;
                      });
                    },
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: '이곳에서의 운동은 어땠나요...?',
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addComment,
                    child: Text('Post'),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _getCommentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No comments yet.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var comment = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(comment['text']),
                      subtitle: Text(
                        '${comment['user']} - ${comment['timestamp'] != null ? comment['timestamp'].toDate().toString() : 'Just now'} - Rating: ${comment['rating'].toString()}',
                      ),
                      trailing: comment['userId'] == _auth.currentUser?.uid
                          ? IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteComment(comment),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
