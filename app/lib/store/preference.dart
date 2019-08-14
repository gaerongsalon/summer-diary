import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preference {
  String _userId;
  String _userName;
  String _userImageUrl;

  String get userId => this._userId;
  String get userName => this._userName;
  String get userImageUrl => this._userImageUrl;

  SharedPreferences _internal;

  static final _instance = new Preference._();

  Preference._();

  factory Preference() {
    return _instance;
  }

  Future<void> warmUp() async {
    this._internal = await SharedPreferences.getInstance();
    this._userId = await this
        ._initializeOrGet("userId", ifAbsent: () => Uuid().v4().toString());
    this._userName = this._internal.getString('userName');
    this._userImageUrl = this._internal.getString('userImageUrl');

    print('Preference is ready.');
  }

  Future<void> updateProfile(String name, String imageUrl) async {
    await this._internal.setString('userName', name);
    await this._internal.setString('userImageUrl', imageUrl);
    this._userName = name;
    this._userImageUrl = imageUrl;
  }

  Future<String> _initializeOrGet(String key,
      {String Function() ifAbsent}) async {
    final value = this._internal.getString(key);
    if (value != null) {
      return value;
    }
    final defaultValue = ifAbsent();
    await this._internal.setString(key, defaultValue);
    return defaultValue;
  }
}

String getUserId() => Preference().userId;
