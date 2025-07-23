import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Untuk penyimpanan PIN yang lebih aman

enum AuthMethod { biometric, pin }

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  // PERBAIKAN: Mengubah FluttersekureStorage() menjadi FlutterSecureStorage()
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Memeriksa apakah perangkat mendukung biometrik dan biometrik tersedia.
  Future<bool> _checkBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print("Error checking biometrics: $e");
      return false;
    }
  }

  /// Melakukan autentikasi menggunakan sidik jari (atau biometrik lain).
  /// Menampilkan Snackbar jika biometrik tidak didukung.
  Future<bool> authenticateWithFingerprint(BuildContext context) async {
    try {
      // Penundaan singkat untuk mencegah glitch UI
      await Future.delayed(const Duration(milliseconds: 500));
      final bool canCheckBiometrics = await _checkBiometrics();
      if (!canCheckBiometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perangkat tidak mendukung autentikasi biometrik"),
          ),
        );
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan sidik jari untuk masuk', // Pesan ke pengguna
        options: const AuthenticationOptions(
          biometricOnly: true, // Hanya izinkan biometrik
          stickyAuth: true, // Dialog tetap terlihat sampai diinteraksi
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print("Auth error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      return false;
    }
  }

  /// Autentikasi komprehensif: Coba biometrik, fallback ke PIN jika gagal/tidak tersedia.
  Future<bool> authenticate(BuildContext context) async {
    try {
      final isBiometricSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isBiometricAvailable = isBiometricSupported && canCheckBiometrics;

      if (isBiometricAvailable) {
        // Coba autentikasi biometrik terlebih dahulu
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Verifikasi identitas Anda untuk masuk',
          options: const AuthenticationOptions(
            biometricOnly: false, // Izinkan fallback ke PIN/pattern sistem
            stickyAuth: true,
          ),
        );
        return didAuthenticate;
      } else {
        // Fallback ke PIN kustom jika biometrik tidak tersedia atau gagal
        return await _showPinAuthDialog(context);
      }
    } catch (e) {
      print("Auth error: $e");
      // Jika ada kesalahan dengan biometrik, fallback ke PIN
      return await _showPinAuthDialog(context);
    }
  }

  /// Menampilkan dialog untuk autentikasi PIN.
  Future<bool> _showPinAuthDialog(BuildContext context) async {
    final pinController = TextEditingController();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Pengguna harus berinteraksi
          builder:
              (context) => AlertDialog(
                title: const Text('Masukkan PIN'),
                content: TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true, // Sembunyikan input
                  maxLength: 4, // Asumsi PIN 4 digit
                  decoration: const InputDecoration(
                    hintText: 'Masukkan 4 digit PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final savedPin =
                          await getUserPin(); // Ambil PIN dari Secure Storage
                      if (pinController.text == savedPin) {
                        Navigator.pop(context, true); // Berhasil terautentikasi
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN salah!')),
                        );
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        ) ??
        false; // Default false jika dialog ditutup tiba-tiba
  }

  /// Menyimpan PIN pengguna ke penyimpanan aman (FlutterSecureStorage).
  Future<void> setUserPin(BuildContext context) async {
    final pinController = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buat PIN Baru'),
            content: TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: 'Masukkan 4 digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (pinController.text.length == 4) {
                    await _secureStorage.write(
                      key: 'user_pin',
                      value: pinController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN berhasil disimpan')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN harus 4 digit!')),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  /// Mengambil PIN pengguna dari penyimpanan aman (FlutterSecureStorage).
  Future<String?> getUserPin() async {
    return await _secureStorage.read(key: 'user_pin');
  }

  /// Menyimpan preferensi metode autentikasi (biometrik/PIN) ke SharedPreferences.
  Future<void> setAuthPreference(AuthMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_method', method.name);
  }

  /// Mengambil preferensi metode autentikasi dari SharedPreferences.
  Future<AuthMethod?> getAuthPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final method = prefs.getString('auth_method');
    return method != null ? AuthMethod.values.byName(method) : null;
  }
}
