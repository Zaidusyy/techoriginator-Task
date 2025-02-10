import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'VideoPlayerScreen.dart';


//add your api key 
const String apiKey = "api key";


class PixabaySearchScreen extends StatefulWidget {
  final String username; // Accepts username

  const PixabaySearchScreen({super.key, required this.username});

  @override
  _PixabaySearchScreenState createState() => _PixabaySearchScreenState();
}

class _PixabaySearchScreenState extends State<PixabaySearchScreen> {
  String searchQuery = "";
  String filterType = "image";
  List<dynamic> results = [];
  bool isLoading = false;
  Timer? _debounce;

  Future<void> fetchData() async {
    if (searchQuery.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    String url = "https://pixabay.com/api/?key=$apiKey&q=$searchQuery";

    if (filterType == "image") {
      url += "&image_type=photo";
    } else if (filterType == "video") {
      url = "https://pixabay.com/api/videos/?key=$apiKey&q=$searchQuery";
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          results = data['hits'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch data");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
      });
      fetchData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _playVideo(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: videoUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome, ${widget.username} !")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: filterType,
                  items: ["image", "video"].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        filterType = value;
                      });
                      fetchData();
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : results.isEmpty
                  ? Center(child: Text("No results found"))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  if (filterType == "image") {
                    return Image.network(
                      results[index]['previewURL'],
                      fit: BoxFit.cover,
                    );
                  } else {
                    String videoUrl = results[index]['videos']['medium']['url'];
                    String thumbnailUrl = results[index]['videos']['medium']['thumbnail'];

                    return GestureDetector(
                      onTap: () => _playVideo(videoUrl),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(thumbnailUrl, fit: BoxFit.cover),
                          Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
