import 'package:barrel_annotation/barrel_annotation.dart';

@BarrelConfig(exclude: ['lib/lib.barrel.dart', 'lib/excluded/**'])
void main() {
  print('Hello, World!');
}
