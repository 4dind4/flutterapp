import 'dart:io';
import 'dart:typed_data';
import 'package:adin_tubes/kelas_student_page.dart';
import 'package:adin_tubes/kode_kuis_random.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'kelas_page.dart';
import 'setting.dart';
//import 'kode_kuis_random.dart';
import 'jawab_soal.dart';
import 'nilai.dart';
import 'kelas_student_page.dart';
import 'biometric_auth_service.dart'; // Ini service biometrik yang sudah kita buat sebelumnya

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lropygtxwhpmbgojqejc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyb3B5Z3R4d2hwbWJnb2pxZWpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIxNzc2MjMsImV4cCI6MjA1Nzc1MzYyM30.cGL7xhS0aZRo-ed_PgwFsPKitkeTvbmjtSEIR32r6H8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => const SettingsPage(),
        '/soal_essay': (context) => TabSoalEssay(),
        '/student': (context) => StudentKelasPage(),
      },
    );
  }
}

// =================== AUTH PAGE ===================
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Register controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final supabase = Supabase.instance.client;

  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _nimController.dispose();
    _statusController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TabHomePage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login gagal')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    }
  }

  Future<void> _register() async {
    final namaLengkap = _namaController.text.trim();
    final nim = _nimController.text.trim();
    final status = _statusController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password tidak sama')));
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email tidak boleh kosong')));
      return;
    }
    try {
      await supabase.auth.signUp(email: email, password: password);
      await supabase.from('User').insert({
        'Nama Lengkap': namaLengkap,
        'NIM/NIP': nim,
        'Status': status,
        'Email': email,
        'Password': password,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registrasi berhasil')));
      _namaController.clear();
      _nimController.clear();
      _statusController.clear();
      _regEmailController.clear();
      _regPasswordController.clear();
      _confirmPasswordController.clear();
      _tabController.animateTo(0); // Pindah ke tab login
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal registrasi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Group 5 Mobile App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[100],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Login Tab
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _login, child: const Text('Login')),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text('Forget Password?'),
                      ),

                      IconButton(
                        onPressed: () async {
                          // Gunakan _biometricAuthService yang sudah diinisialisasi
                          bool authenticated = await _biometricAuthService
                              .authenticate(context);

                          if (authenticated) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TabHomePage(),
                              ), // Ganti dengan halaman tujuan
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Autentikasi gagal"),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.fingerprint, size: 32),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Register Tab
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nimController,
                      decoration: const InputDecoration(
                        labelText: 'NIM/NIP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _statusController,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        String? selectedStatus =
                            _statusController.text.isNotEmpty
                                ? _statusController.text
                                : 'Student';
                        final status = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            String tempStatus = selectedStatus;
                            return AlertDialog(
                              title: const Text('Pilih Status'),
                              content: StatefulBuilder(
                                builder: (context, setState) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RadioListTile<String>(
                                        title: const Text('Student'),
                                        value: 'Student',
                                        groupValue: tempStatus,
                                        onChanged: (value) {
                                          setState(() {
                                            tempStatus = value!;
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: const Text('Teacher'),
                                        value: 'Teacher',
                                        groupValue: tempStatus,
                                        onChanged: (value) {
                                          setState(() {
                                            tempStatus = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, null),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      () => Navigator.pop(context, tempStatus),
                                  child: const Text('Pilih'),
                                ),
                              ],
                            );
                          },
                        );
                        if (status != null) {
                          setState(() {
                            _statusController.text = status;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _regEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _regPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmed Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Settings Tab
          const SettingsPage(),
        ],
      ),
    );
  }
}

// =================== FORGOT PASSWORD PAGE ===================
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email tidak boleh kosong')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP telah dikirim ke email Anda.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim OTP: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPassController.text;
    if (otp.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP dan Password baru wajib diisi')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 1. Verifikasi OTP
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: otp,
      );
      // 2. Update password setelah OTP diverifikasi
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah! Silakan login kembali.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Kode OTP dari Email',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassController,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Ubah Password'),
              ),
            ] else ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Kirim OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =================== TAB HOME PAGE ===================
class TabHomePage extends StatefulWidget {
  const TabHomePage({super.key});

  @override
  State<TabHomePage> createState() => _TabHomePageState();
}

class _TabHomePageState extends State<TabHomePage> {
  int _selectedIndex = 0;
  String? userStatus;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isUploading = false;

  List<Map<String, String>> groupMembers = [];

  List<Map<String, dynamic>> anggotaSupabase = [];

  @override
  void initState() {
    super.initState();
    fetchUserStatus();
    fetchAnggota();
  }

  Future<void> fetchUserStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data =
          await Supabase.instance.client
              .from('User')
              .select('Status')
              .eq('Email', user.email!)
              .single();
      setState(() {
        userStatus = (data['Status'] ?? '').toString().trim().toLowerCase();
        isLoading = false;
      });
    } else {
      setState(() {
        userStatus = null;
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedImage = pickedFile;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<String?> uploadImageToFotohome(Uint8List imageBytes) async {
    try {
      final fileName = '${const Uuid().v4()}.jpg';
      final path = 'public/$fileName';
      await Supabase.instance.client.storage
          .from('fotohome')
          .uploadBinary(path, imageBytes);
      final publicUrl = Supabase.instance.client.storage
          .from('fotohome')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> addMember() async {
    final name = nameController.text.trim();
    final nim = nimController.text.trim();
    if (name.isEmpty || nim.isEmpty || _pickedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, NIM, dan Foto wajib diisi')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final fotoUrl = await uploadImageToFotohome(_pickedImageBytes!);
      if (fotoUrl == null) {
        throw 'Gagal upload foto';
      }
      await Supabase.instance.client.from('home').insert({
        'Nama Anggota': name,
        'Nomor Induk Mahasiswa': nim,
        'Foto_url': fotoUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anggota berhasil ditambahkan')),
      );
      setState(() {
        nameController.clear();
        nimController.clear();
        _pickedImage = null;
        _pickedImageBytes = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambah anggota: $e')));
    }
    setState(() => _isUploading = false);
  }

  Future<void> fetchAnggota() async {
    final response = await Supabase.instance.client
        .from('home')
        .select()
        .order('id', ascending: false);
    setState(() {
      anggotaSupabase = List<Map<String, dynamic>>.from(response);
    });
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("HOME"),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar dan header
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _pickedImageBytes != null
                                ? MemoryImage(_pickedImageBytes!)
                                : null,
                        child:
                            _pickedImageBytes == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField("Nama Anggota", nameController),
                    const SizedBox(height: 10),
                    _buildInputField("NIM", nimController),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _isUploading ? null : addMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isUploading
                              ? const CircularProgressIndicator()
                              : const Text('Tambah Anggota'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "THIS IS GROUP 5",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              "Daftar Anggota:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            anggotaSupabase.isNotEmpty
                ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: anggotaSupabase.length,
                  itemBuilder: (context, index) {
                    final member = anggotaSupabase[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading:
                            member['Foto_url'] != null
                                ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    member['Foto_url'],
                                  ),
                                  radius: 24,
                                )
                                : const CircleAvatar(
                                  child: Icon(Icons.person),
                                  radius: 24,
                                ),
                        title: Text(
                          member['Nama Anggota'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "NIM: ${member['Nomor Induk Mahasiswa'] ?? ''}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Konfirmasi sebelum hapus
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Hapus Anggota'),
                                    content: const Text(
                                      'Yakin ingin menghapus anggota ini?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              await deleteAnggota(member['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                )
                : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Belum ada anggota ditambahkan.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void editMember(int index) {
    // Example: Show a dialog to edit member's name and NIM
    final member = groupMembers[index];
    final TextEditingController editNameController = TextEditingController(
      text: member['name'],
    );
    final TextEditingController editNimController = TextEditingController(
      text: member['nim'],
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Anggota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(labelText: 'Nama Anggota'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editNimController,
                decoration: const InputDecoration(labelText: 'NIM'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  groupMembers[index] = {
                    'name': editNameController.text.trim(),
                    'nim': editNimController.text.trim(),
                  };
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void deleteMember(int index) {
    setState(() {
      groupMembers.removeAt(index);
    });
  }

  Future<void> deleteAnggota(int id) async {
    try {
      await Supabase.instance.client.from('home').delete().eq('id', id);
      await fetchAnggota(); // Refresh daftar anggota
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anggota berhasil dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus anggota: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Tab dan page untuk Teacher
    final List<Widget> teacherPages = [
      _buildHomeScreen(),
      const KelasPage(),
      // const aplikasimhs(),
      const InputNilaiManualPage(),
      const SettingsPage(),
    ];
    final List<BottomNavigationBarItem> teacherTabs = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Kelas'),
      // const BottomNavigationBarItem(
      //   icon: Icon(Icons.book),
      //   label: 'Soal Essay',
      // ),
      const BottomNavigationBarItem(icon: Icon(Icons.grade), label: 'Nilai'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Setting',
      ),
    ];

    // Tab dan page untuk Student
    final List<Widget> studentPages = [
      _buildHomeScreen(),
      const StudentKelasPage(),
      const aplikasimhs(),
      const SettingsPage(),
    ];
    final List<BottomNavigationBarItem> studentTabs = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Kelas'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Soal Essay',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Setting',
      ),
    ];

    final isTeacher = userStatus == 'teacher';

    // Pastikan _selectedIndex tidak melebihi jumlah tab
    final maxIndex =
        isTeacher ? teacherPages.length - 1 : studentPages.length - 1;
    if (_selectedIndex > maxIndex) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body:
          isTeacher
              ? teacherPages[_selectedIndex]
              : studentPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: isTeacher ? teacherTabs : studentTabs,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.blue[200],
        onTap: _onItemTapped,
      ),
    );
  }
}
