import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart'; // generated: dart run build_runner build

class Cars extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  IntColumn get bodyStyle => integer().withDefault(const Constant(0))(); // CarBodyStyle.index
  IntColumn get accentColorValue => integer().nullable()();
  TextColumn get make => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get plate => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class ParkEvents extends Table {
  TextColumn get id => text()();
  TextColumn get carId => text().nullable().references(Cars, #id)(); // null = pending
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyMeters => real().nullable()();
  DateTimeColumn get parkedAt => dateTime()();
  DateTimeColumn get departedAt => dateTime().nullable()();
  IntColumn get source => integer()(); // ParkSource.index
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get sweepingScheduleId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class SweepingSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get cityCode => text()();
  TextColumn get routeId => text()();
  IntColumn get weekdayMask => integer()(); // bit0=Mon..bit6=Sun
  IntColumn get weekOfMonthMask => integer()(); // bit0=week1..bit4=week5
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  IntColumn get side => integer()(); // StreetSide.index
  TextColumn get skipDatesJson => text().withDefault(const Constant('[]'))();
  TextColumn get polygonJson => text()(); // [[lat,lng],...]; bbox cols below for prefilter
  RealColumn get minLat => real()();
  RealColumn get maxLat => real()();
  RealColumn get minLng => real()();
  RealColumn get maxLng => real()();
  DateTimeColumn get sourceUpdatedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Cars, ParkEvents, SweepingSchedules])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'parked'));
  @override
  int get schemaVersion => 1;
}
