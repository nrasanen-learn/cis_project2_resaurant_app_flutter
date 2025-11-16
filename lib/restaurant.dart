import 'dart:ui';

class Restaurant {
  late String id;
  late String name;
  late String type;
  late String description;
  late List menuItem;
  late double rating;
  late double price;
  late Image image;



  @override
  String toString() {
    return 'Restaurant{name: $name, type: $type, description: $description }';
  }
}