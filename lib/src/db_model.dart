import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_dart/mongo_dart.dart';

abstract class DBModel<T> {
  DBModel(this.collection, {this.id});

  @JsonKey(name: '_id', includeIfNull: false)
  ObjectId? id;

  @JsonKey(ignore: true)
  DbCollection collection;

  Future<Map<String, Object?>?> save() async {
    if (id != null) {
      final result = await collection.modernUpdate(
        where.eq('_id', id),
        toJson(),
        upsert: true,
      );

      return result;
    } else {
      final payload = toJson();
      final result = await collection.insertOne(payload);
      final document = result.document;
      if (document != null) {
        id = result.document?['_id'] as ObjectId?;
      }
      return result.document;
    }
  }

  Future<List<T>> find([dynamic query]) async {
    final data = await collection.find(query).toList();
    return data.map<T>(fromJson).toList();
  }

  Stream<T> findStream([dynamic query]) async* {
    await for (final item in collection.find(query)) {
      yield fromJson(item);
    }
  }

  Future<T?> findOne([dynamic query]) async {
    final data = await collection.findOne(query);
    if (data != null) {
      if (data[r'\$err'] == null) {
        return fromJson(data);
      } else {
        throw Exception(data[r'\$err']);
      }
    } else {
      return null;
    }
  }

  Future<T?> byId(dynamic id) {
    return findOne(<String, dynamic>{'_id': id});
  }

  Future<void> delete() async {
    await collection.remove(<String, dynamic>{'_id': id});
    return;
  }

  Map<String, dynamic> toJson();
  T fromJson(Map<String, dynamic> json);
}
