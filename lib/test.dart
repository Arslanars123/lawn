import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:product_mughees/login.dart';
import 'dart:convert'; // For JSON decoding
import 'package:widget_zoom/widget_zoom.dart'; // For galleries, if needed
import 'package:url_launcher/url_launcher.dart'; // For opening URLs in a browser
import 'package:shared_preferences/shared_preferences.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _imageData = [];

  // Function to fetch images from an API using POST request
  Future<void> _fetchImages() async {
    try {
      // Make the POST request
      final response = await http.post(
        Uri.parse('https://sonny-backend.vercel.app/fetch-images'), // Replace with your API endpoint
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'param1': 'value1', // Adjust your request body as needed
        }),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Decode the JSON response
        final data = json.decode(response.body);
        final List<dynamic> images = data['images'];

        // Update the state with the image data (imgSrc and href)
        setState(() {
          _imageData = images
              .map((image) => {
                    '_id':image['_id'],
                    'imgSrc': image['imgSrc'],
                    'href': image['href'],
                  })
              .toList();
        });
      } else {
        // Handle error response
        throw Exception('Failed to load images');
      }
    } catch (error) {
      print('Error fetching images: $error');
      // Handle the error (display error message or retry)
    }
  }

  // Function to handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to launch URLs in browser
  Future<void> _launchUrl(String url) async {
  try {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  } catch (e) {
    print('Error launching URL: $e');
  }
}
 // Function to check reaction for a specific image as it's loaded
  Future<void> _checkReactionStatus(String imageId, int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId != null) {
      try {
        final response = await http.post(
          Uri.parse('https://sonny-backend.vercel.app/check-image-status'), // Replace with your API endpoint
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'userId': userId,
            'imageId': imageId,
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final reactionData = jsonDecode(response.body);
          String? reaction = reactionData['reaction']; // 'like', 'dislike', or null
          setState(() {
            _imageData[index]['reaction'] = reaction == 'liked' ? 'like' : (reaction == 'disliked' ? 'dislike' : null);
            _imageData[index]['reactionChecked'] = true; // Mark as checked
          });
        } else {
          throw Exception('Failed to check reaction for image $imageId');
        }
      } catch (e) {
        print('Error checking reaction: $e');
      }
    } else {
      print('User not logged in');
    }
  }

  // Like an image (UI update first, then API call)
  void _likeImage(String imageId, int index) {
    // Update UI first
    setState(() {
      _imageData[index]['reaction'] = 'like';
    });

    // Perform API call in the background
    _performLikeApiCall(imageId, index);
  }

  // Dislike an image (UI update first, then API call)
  void _dislikeImage(String imageId, int index) {
    // Update UI first
    setState(() {
      _imageData[index]['reaction'] = 'dislike';
    });

    // Perform API call in the background
    _performDislikeApiCall(imageId, index);
  }

  // Perform the like API call
  Future<void> _performLikeApiCall(String imageId, int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId != null) {
      try {
        final response = await http.post(
          Uri.parse('https://sonny-backend.vercel.app/like'),
          headers: <String, String>{ 'Content-Type': 'application/json' },
          body: jsonEncode(<String, dynamic>{ 'imageId': imageId, 'userId': userId }),
        );

        if (!(response.statusCode == 200 || response.statusCode == 201)) {
          // If the API call fails, you might want to revert the reaction state
          setState(() {
            _imageData[index]['reaction'] = null; // Revert reaction
          });
          throw Exception('Failed to like image');
        }
      } catch (e) {
        print('Error liking image: $e');
        // Optionally revert UI on error
        setState(() {
          _imageData[index]['reaction'] = null; // Revert reaction
        });
      }
    } else {
      print('User not logged in');
    }
  }

  // Perform the dislike API call
  Future<void> _performDislikeApiCall(String imageId, int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId != null) {
      try {
        final response = await http.post(
          Uri.parse('https://sonny-backend.vercel.app/dislike'),
          headers: <String, String>{ 'Content-Type': 'application/json' },
          body: jsonEncode(<String, dynamic>{ 'imageId': imageId, 'userId': userId }),
        );

        if (!(response.statusCode == 200 || response.statusCode == 201)) {
          // If the API call fails, you might want to revert the reaction state
          setState(() {
            _imageData[index]['reaction'] = null; // Revert reaction
          });
          throw Exception('Failed to dislike image');
        }
      } catch (e) {
        print('Error disliking image: $e');
        // Optionally revert UI on error
        setState(() {
          _imageData[index]['reaction'] = null; // Revert reaction
        });
      }
    } else {
      print('User not logged in');
    }
  }

  // Widget for the Home tab (Vertical swiping images)
  Widget _buildHomeTab() {
    if (_imageData.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(), // Show a loader while waiting for images
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical, // Enable vertical swiping
      itemCount: _imageData.length,
      itemBuilder: (context, index) {
        String imageId = _imageData[index]['_id']!;
        String? currentReaction = _imageData[index]['reaction']; // Get current reaction
        bool reactionChecked = _imageData[index]['reactionChecked'] ?? false; // Check if status has been checked

        // Call the check reaction status when the image is loaded, but only once
        if (!reactionChecked) {
          _checkReactionStatus(imageId, index);
        }

        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Image in the background
              Positioned.fill(
                child: Image.network(
                  _imageData[index]['imgSrc']!,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              // Button overlay positioned at the top
              Positioned(
                top: 20.0, // Adjust this value to control the vertical position of the button
                left: 20.0, // Adjust this value to control the horizontal position of the button
                child: ElevatedButton(
                  onPressed: () {
                    _launchUrl(_imageData[index]['href']!); // Open URL on button click
                  },
                  child: const Text('View'),
                ),
              ),
              // Like button
              Positioned(
                top: 80.0, // Adjust this value to control the vertical position of the button
                left: 20.0, // Adjust this value to control the horizontal position of the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentReaction == 'like' ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    _likeImage(imageId, index); // Like image when clicked
                  },
                  child: const Text('Like'),
                ),
              ),
              // Dislike button
              Positioned(
                top: 140.0, // Adjust this value to control the vertical position of the button
                left: 20.0, // Adjust this value to control the horizontal position of the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentReaction == 'dislike' ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    _dislikeImage(imageId, index); // Dislike image when clicked
                  },
                  child: const Text('Dislike'),
                ),
              ),
            ],
          ),
        );
      },
    );
  } // Widget for the Search tab (Horizontal scrollable slider)
  Widget _buildSearchTab() {
    if (_imageData.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(), // Show a loader while waiting for images
      );
    }

    return Column(
      children: [
        const Text('Trending'),
        Expanded(
          child: SizedBox(
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Horizontal scrolling
              itemCount: _imageData.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0), // Add some spacing between items
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0), // Rounded corners for images
                        child: Image.network(
                          _imageData[index]['imgSrc']!,
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width * 0.6, // Set width to show 2 images and half of the third one
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Failed to load image', style: TextStyle(color: Colors.black)),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _launchUrl(_imageData[index]['href']!); // Open URL on button click
                          },
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const Text('Most Liked'),
        Expanded(
          child: SizedBox(
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Horizontal scrolling
              itemCount: _imageData.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0), // Add some spacing between items
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0), // Rounded corners for images
                        child: Image.network(
                          _imageData[index]['imgSrc']!,
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width * 0.6, // Set width to show 2 images and half of the third one
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Failed to load image', style: TextStyle(color: Colors.black)),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _launchUrl(_imageData[index]['href']!); // Open URL on button click
                          },
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

// Function to handle logout
Future<void> _logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId'); // Remove userId from Shared Preferences

  // Navigate back to the main screen
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()), // Replace with your main app screen
    (Route<dynamic> route) => false,
  );
}

  // Define a list of pages for each tab
  // Define a list of pages for each tab
List<Widget> get _pages {
  return <Widget>[
    _buildHomeTab(), // Home tab with vertical swiping
    _buildSearchTab(), // Search tab with horizontal slider
    _buildProfileTab(), // Profile tab with logout button
  ];
}

// Widget for the Profile tab
Widget _buildProfileTab() {
  return Center(
    child: ElevatedButton(
      onPressed: _logout,
      child: const Text('Logout'),
    ),
  );
}

  @override
  void initState() {
    super.initState();
    _fetchImages(); // Fetch the images when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipable Image Feed'),
      ),
      body: _pages[_selectedIndex], // Display the appropriate tab content
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Trending/Liked',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
