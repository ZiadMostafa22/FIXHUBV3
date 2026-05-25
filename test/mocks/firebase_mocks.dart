// test/mocks/firebase_mocks.dart
// Central mock declaration file.
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// This generates firebase_mocks.mocks.dart automatically.

import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';

@GenerateMocks([
  // Firebase core
  FirebaseAuth,
  FirebaseFirestore,
  User,
  UserCredential,

  // Firestore internals (needed to chain calls like .collection().doc().get())
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,

  // App datasources
  AuthRemoteDataSource,
  BookingRemoteDataSource,

  // App repositories
  AuthRepository,
  BookingRepository,
])
void main() {}
