import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_data.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserData? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _userSubscription;

  UserData? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  String get _baseUrl {
    if (!kDebugMode) {
      return dotenv.get('LIVE_API_BASE_URL', fallback: 'https://stokpulse.vercel.app');
    }
    final devUrl = dotenv.get('DEV_API_BASE_URL', fallback: '');
    if (devUrl.isNotEmpty) {
      return devUrl;
    }
    // Smart fallbacks for local dev server
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final startTime = DateTime.now();
    try {
      final box = Hive.box('settings');
      final cachedEmail = box.get('session_email');
      
      if (cachedEmail != null && cachedEmail.toString().isNotEmpty) {
        await refreshUser(cachedEmail.toString());
        subscribeToUserUpdates(cachedEmail.toString());
      }
    } catch (e) {
      debugPrint("STP ERROR: AuthProvider initialization failed: $e");
    } finally {
      // Ensure splash stays for 5 seconds to allow full animations to play
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 5000) {
        await Future.delayed(Duration(milliseconds: 5000 - elapsed.inMilliseconds));
      }
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('users')
          .select('email, name, password, etokens, e_tokens, portfolio, options')
          .eq('email', email.trim())
          .maybeSingle();
      
      if (res == null) throw 'User not found';

      final hashedPassword = res['password'] as String;
      if (BCrypt.checkpw(password, hashedPassword)) {
        _user = UserData.fromJson(res);
        final box = Hive.box('settings');
        await box.put('session_email', email.trim());
        subscribeToUserUpdates(email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw 'Invalid password';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );
      
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to send OTP';
        throw error;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyOtpAndRegister({
    required String name,
    required String email,
    required String password,
    required String otp,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email.trim(),
          'password': password,
          'otp': otp,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = UserData.fromJson(data['user']);
        
        final box = Hive.box('settings');
        await box.put('session_email', email.trim());
        subscribeToUserUpdates(email);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Verification failed';
        throw error;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final emailTrimmed = email.trim();
      final existing = await _supabase
          .from('users')
          .select('email')
          .eq('email', emailTrimmed)
          .maybeSingle();

      if (existing != null) throw 'Email already registered';

      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      
      final newUser = {
        'name': name,
        'email': emailTrimmed,
        'password': hashedPassword,
        'etokens': 10000.0,
        'e_tokens': 10000.0,
        'portfolio': [],
        'options': [],
      };

      final res = await _supabase
          .from('users')
          .insert(newUser)
          .select('email, name, etokens, e_tokens, portfolio, options')
          .single();

      _user = UserData.fromJson(res);
      final box = Hive.box('settings');
      await box.put('session_email', emailTrimmed);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUser(String email) async {
    try {
      final res = await _supabase
          .from('users')
          .select('email, name, etokens, e_tokens, portfolio, options')
          .eq('email', email.trim())
          .single();
      _user = UserData.fromJson(res);
      notifyListeners();
    } catch (e) {
      logout();
    }
  }

  Future<void> updateProfile({String? name}) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;

      await _supabase.from('users').update(updates).eq('email', _user!.email);
      await refreshUser(_user!.email);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToUserUpdates(String email) {
    _userSubscription?.cancel();
    _userSubscription = _supabase
        .from('users')
        .stream(primaryKey: ['email'])
        .eq('email', email.trim())
        .listen((data) {
          if (data.isNotEmpty) {
            debugPrint("STP Realtime user update received: ${data.first}");
            _user = UserData.fromJson(data.first);
            notifyListeners();
          }
        }, onError: (err) {
          debugPrint("STP Realtime subscription error: $err");
        });
  }

  Future<void> logout() async {
    _userSubscription?.cancel();
    _user = null;
    final box = Hive.box('settings');
    await box.delete('session_email');
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
