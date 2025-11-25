import 'package:cis_project2_resaurant_app/restaurant.dart';
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

class _RestaurantAppState extends State<RestaurantApp> {
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

  // Controller for the input field
  final TextEditingController _RestaurantName = TextEditingController();
  final TextEditingController _RestaurantType = TextEditingController();
  final TextEditingController _RestaurantDescription = TextEditingController();
  final TextEditingController _RestaurantMenuItem = TextEditingController();
  final TextEditingController _RestaurantRating = TextEditingController();
  final TextEditingController _RestaurantPrice = TextEditingController();
  // final TextEditingController _RestaurantImage = TextEditingController();

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


  // Local list of restaurants (Phase 1: local; Phase 2: Firestore stream replaces this).
  late final CollectionReference<Map<String, dynamic>> restaurants;

  @override
  void initState() {
    super.initState();
    restaurants = FirebaseFirestore.instance.collection('RESTAURANTS');
  }

  // add one restaurant from the TextField to the local list.
  void _addRestaurant() {
    final newRestaurantName = _RestaurantName.text.trim();
    final newRestaurantType = _RestaurantType.text.trim();
    final newRestaurantDescription = _RestaurantDescription.text.trim();
    final newRestaurantMenuItem = _RestaurantMenuItem.text.trim();
    final newRestaurantRating = _RestaurantRating.text.trim();
    final newRestaurantPrice = _RestaurantPrice.text.trim();
    // final newRestaurantImage = _RestaurantName.text.trim();

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
            // 'typeOfRestaurant': newRestaurantType,
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

  // ACTION: remove the restaurant with the given fire base id.
  void _removeRestaurantAt(String id) {
    setState(() {
      restaurants.doc(id).delete(); // remove restaurant from fireStore
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Restaurants')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // ====== Restaurant Input  ======
            EnterNewRestaurantWidget(),

            /*const SizedBox(height: 24),
            Expanded(
              child: ElevatedButton(onPressed: /*sortingMethod*/, child: Text("Sort by Price"))
            ),
            Expanded(
                child: ElevatedButton(onPressed: /*sortingMethod*/, child: Text("Sort by Restaurant Name"))
            ),
            Expanded(
                child: ElevatedButton(onPressed: /*sortingMethod*/, child: Text("Sort by Rating"))
            ),
             */

            SortSelector(),
            // ====== Spacer for formating ======
            const SizedBox(height: 24),
            Expanded(
              // ====== Restaurant List ======
              child: RestaurantListWidget(),
            ),
          ],
        ),
      ),
    );
  }

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
                // ====== Item Tile ======
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

  Widget EnterNewRestaurantWidget() {
    return Row(
      children: [
        // ====== Item Name TextField ======
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
        // ====== Add Item Button ======
        FilledButton(onPressed: _addRestaurant, child: const Text('Add')),
      ],
    );
  }

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

  //Widget PriceSort(List restaurants) {
  //  restaurants.sort(_RestaurantPrice);
  //}

}
