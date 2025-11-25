import 'package:cis_project2_resaurant_app/restaurant.dart'; // never used the restaurant class to create instances
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// main async method to initialise the application
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
      title: 'Favorite Restaurant Meals',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFC8A2C8)),
      home: const RestaurantApp(),
    );
  }
}

class RestaurantApp extends StatefulWidget {
  const RestaurantApp({super.key});

  @override
  State<RestaurantApp> createState() => _RestaurantAppState();
}
// the app state which will update the users screen if any changes are made to the components within this state
class _RestaurantAppState extends State<RestaurantApp> {
  // sorting variables and variableshow to make the different criteria for sorting ascending or descending with booleans
  String _sortField = 'createdAt'; // default sort
  bool get _isDescending {   //_isDescending taken from ai
    switch (_sortField) {
      case 'price':
      case 'rating':
        return true;  // sort high → low
      case 'restaurant':
      case 'createdAt':
      default:
        return false; // sort low → high
    }
  }

  // Controllers for the input field
  final TextEditingController _RestaurantName = TextEditingController();
  final TextEditingController _RestaurantType = TextEditingController();
  final TextEditingController _RestaurantDescription = TextEditingController();
  final TextEditingController _RestaurantMenuItem = TextEditingController();
  final TextEditingController _RestaurantRating = TextEditingController();
  final TextEditingController _RestaurantPrice = TextEditingController();
  // final TextEditingController _RestaurantImage = TextEditingController();

  // sorting method that allows the user to select from a dropdown menu
  Widget SortSelector() {
    return DropdownButton<String>(
      value: _sortField,
      items: const [
        DropdownMenuItem(value: 'price', child: Text("Sort by Price")),
        DropdownMenuItem(value: 'restaurant', child: Text("Sort by Name")),
        DropdownMenuItem(value: 'rating', child: Text("Sort by Rating")),
        DropdownMenuItem(value: 'createdAt', child: Text("Newest First")),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _sortField = value);
        }
      },
    );
  }


  // Local list of restaurants
  late final CollectionReference<Map<String, dynamic>> restaurants;

  @override
  void initState() {
    super.initState();
    restaurants = FirebaseFirestore.instance.collection('RESTAURANTS');
  }

  // add one restaurant from the TextField to the local list including the code a few lines down.
  void _addRestaurant() {
    final newRestaurantName = _RestaurantName.text.trim();
    final newRestaurantType = _RestaurantType.text.trim();
    final newRestaurantDescription = _RestaurantDescription.text.trim();
    final newRestaurantMenuItem = _RestaurantMenuItem.text.trim();
    final newRestaurantRating = _RestaurantRating.text.trim();
    final newRestaurantPrice = _RestaurantPrice.text.trim();
    // final newRestaurantImage = _RestaurantName.text.trim();

    // makes sure all fields are filled before adding to the database
    if (newRestaurantName.isEmpty && newRestaurantType.isEmpty && newRestaurantPrice.isEmpty
        && newRestaurantRating.isEmpty && newRestaurantMenuItem.isEmpty && newRestaurantDescription.isEmpty
        /* && newRestaurantImage.isEmpty */) return;
    setState(() {
      restaurants.add(
          {'restaurant': newRestaurantName,
            'typeOfRestaurant': newRestaurantType,
            'description': newRestaurantDescription,
            'menuItem': newRestaurantMenuItem,
            'rating': double.tryParse(newRestaurantRating) ?? 0.0,
            'price': double.tryParse(newRestaurantPrice) ?? 0.0,
            'createdAt': FieldValue.serverTimestamp(),}
      );
      _RestaurantName.clear();
      _RestaurantType.clear();
      _RestaurantDescription.clear();
      _RestaurantMenuItem.clear();
      _RestaurantRating.clear();
      _RestaurantPrice.clear();
      // _RestaurantImage.clear();

    });
  }

  // remove the restaurant with the given fire base id. (never used/ started for future improvements)
  void _removeRestaurantAt(String id) {
    setState(() {
      restaurants.doc(id).delete(); // remove restaurant from fireStore
    });
  }

  // build method which compiles all of my functions to display to the uses
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Restaurants')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // Restaurant Input
            EnterNewRestaurantWidget(),
            // Spacer for formating
            const SizedBox(height: 24),
            // Sorting Dropdown
            SortSelector(),
            // Spacer for formating
            const SizedBox(height: 24),
            Expanded(
              // Restaurant List
              child: RestaurantListWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // this contains my list builder which creates the list from the data of the database and it is comprised of cards and listTiles
  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> RestaurantListWidget() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: restaurants.orderBy(_sortField, descending: _isDescending).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap){
          if (snap.hasError) {
            return Text('Firebase Snapshot Error: ${snap.error}');
          }
          if (snap.connectionState == ConnectionState.waiting)  {
            return const Text('loading....');
          }
          if (snap.data == null || snap.data!.docs.isEmpty) {
            return const Text('No Restaurants Yet...');
          }
          return ListView.builder(
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final String restaurantId = doc.id;
              final String restaurantName = (doc.data()['restaurant'] ?? 'Unnamed Restaurant');
              final String restaurantType = (doc.data()['typeOfRestaurant'] ?? 'Unknown Food Type');
              final String restaurantDescription = (doc.data()['description'] ?? 'No Description');
              final String restaurantMenuItem = (doc.data()['menuItem'] ?? 'Unnamed Dish');
              final String restaurantRating = (doc.data()['rating'] != null ? doc.data()['rating'].toString() : 'No Rating');
              final String restaurantPrice = (doc.data()['price'] != null ? doc.data()['price'].toString() : 'No Price');
              return Dismissible(
                key: ValueKey(restaurantId),
                // A card and listTile to format the data to the user
                child: Card(
                  color:  Color(0xFFC8A2C8),
                  shadowColor: Color(0xFF000000),
                  child: ListTile(
                    leading: const Icon(Icons.fastfood),
                    title: Text("$restaurantMenuItem at $restaurantName, Rating: $restaurantRating"),
                    subtitle: Text("$restaurantType food, Price: $restaurantPrice, Description: $restaurantDescription"),
                  ),
                ),
              );
            },
          );
        }
    );
  }

  // this is my method that allows the user to enter in a new instance of a restaurant and add it to the list
  // it does this by getting the TextInput method below and giving it the connected restaurant data types and labels
  Widget EnterNewRestaurantWidget() {
    return Row(
      children: [
        // Item Name TextField
        Expanded(
          child: TextInput(_RestaurantName, "Name:")
        ),
        const SizedBox(width: 12),
        Expanded(
            child: TextInput(_RestaurantType, "Type:")
        ),
        const SizedBox(width: 12),
        Expanded(
            child: TextInput(_RestaurantDescription, "Description:")
        ),
        const SizedBox(width: 12),
        Expanded(
            child: TextInput(_RestaurantMenuItem, "Menu Item:")
        ),
        const SizedBox(width: 12),
        Expanded(
            child: TextInput(_RestaurantRating, "Rating:")
        ),
        const SizedBox(width: 12),
        Expanded(
            child: TextInput(_RestaurantPrice, "Price:")
        ),
        const SizedBox(width: 12),
        // Add Item Button
        FilledButton(onPressed: _addRestaurant, child: const Text('Add')),
      ],
    );
  }

  // this gets called in EnterNewRestaurantWidget and is the individual text fields that comprise the method above
  // it also contains the cosmetic features of the input fields
  // this method is separated to make code more readable by not have the same code six times over
  Widget TextInput(TextEditingController restaurantAttribute, String name) {
    return TextField(
      controller: restaurantAttribute,
      onSubmitted: (_) => _addRestaurant(),
      decoration: InputDecoration(
        labelText: '$name',
        border: const OutlineInputBorder(),
        fillColor: Color(0xFFCFBFCE),
        filled: true,
        //focusColor: Color(0xFF05F851),
      ),
    );
  }
}
