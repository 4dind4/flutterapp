import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  File? _profileImage;
  String? _fotoUrl; // Untuk menyimpan url foto dari Supabase

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data =
            await Supabase.instance.client
                .from('User')
                .select()
                .eq('Email', user.email!)
                .single();
        String? namaLengkap = data['Nama Lengkap'];
        String? fotoUrl;

        if (namaLengkap != null && namaLengkap.isNotEmpty) {
          final fotoData =
              await Supabase.instance.client
                  .from('home')
                  .select('Foto_url')
                  .eq('Nama Anggota', namaLengkap)
                  .maybeSingle();
          fotoUrl = fotoData?['Foto_url'];
        }

        setState(() {
          userData = data;
          _fotoUrl = fotoUrl;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          userData = null;
          _fotoUrl = null;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userData = null;
        _fotoUrl = null;
        isLoading = false;
      });
    }
  }

  Future<void> ubahPassword(String passwordBaru) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: passwordBaru),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah password: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text('Data pengguna tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: Colors.lightBlue[300],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hapus GestureDetector dan icon camera, hanya tampilkan foto profil saja
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                        ? NetworkImage(_fotoUrl!)
                        : const AssetImage('images/fotokel.jpg')
                            as ImageProvider,
              ),
              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nama: ${userData?['Nama Lengkap'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "NIM: ${userData?['NIM/NIP'] ?? '-'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Status: ${userData?['Status'] ?? '-'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Email: ${userData?['Email'] ?? '-'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset),
                label: const Text("Ubah Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[300],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UbahPasswordPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UbahPasswordPage extends StatefulWidget {
  const UbahPasswordPage({super.key});

  @override
  State<UbahPasswordPage> createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  final TextEditingController passLama = TextEditingController();
  final TextEditingController passBaru = TextEditingController();
  bool _isLoading = false;

  Future<void> _ubahPassword() async {
    final oldPass = passLama.text.trim();
    final newPass = passBaru.text.trim();
    if (oldPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Re-authenticate user dengan password lama
      final user = Supabase.instance.client.auth.currentUser;
      final email = user?.email;
      if (email == null) throw "User tidak ditemukan";
      // Sign in ulang untuk verifikasi password lama
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: oldPass,
      );
      // Jika sukses, update password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password berhasil diubah")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengubah password: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ubah Password"),
        backgroundColor: Colors.lightBlue[300],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: passLama,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Lama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passBaru,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _ubahPassword,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Simpan Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[300],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
