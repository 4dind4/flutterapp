import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentKelasPage extends StatefulWidget {
  const StudentKelasPage({super.key});

  @override
  State<StudentKelasPage> createState() => _StudentKelasPageState();
}

class _StudentKelasPageState extends State<StudentKelasPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> kelasList = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllKelas();
  }

  Future<void> loadAllKelas() async {
    setState(() => isLoading = true);
    try {
      final kelasData = await supabase
          .from('kelas')
          .select('id_kelas, mk, kode_kuis, qr_code_url, nama')
          .order('nama', ascending: true);
      setState(() {
        kelasList = List<Map<String, dynamic>>.from(kelasData);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        kelasList = [];
        isLoading = false;
      });
      _showSnackBar('Gagal memuat data kelas: $e');
    }
  }

  Future<void> searchKelas(String query) async {
    setState(() => isLoading = true);
    try {
      final kelasData = await supabase
          .from('kelas')
          .select('id_kelas, mk, kode_kuis, qr_code_url, nama')
          .or('nama.ilike.%$query%,mk.ilike.%$query%,kode_kuis.ilike.%$query%')
          .order('nama', ascending: true);
      setState(() {
        kelasList = List<Map<String, dynamic>>.from(kelasData);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        kelasList = [];
        isLoading = false;
      });
      _showSnackBar('Gagal mencari kelas: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showQrCodeDialog(Map<String, dynamic> kelas) async {
    final imageUrl = kelas['qr_code_url'];
    if (imageUrl == null || imageUrl.isEmpty) {
      _showSnackBar("QR Code belum tersedia.");
      return;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Class QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quiz Code: ${kelas['kode_kuis'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load QR image');
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas Saya'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Cari Kelas',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            loadAllKelas();
                          },
                        ),
                      ),
                      onChanged: (query) {
                        if (query.isEmpty) {
                          loadAllKelas();
                        } else {
                          searchKelas(query);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Daftar Kelas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    kelasList.isEmpty
                        ? const Center(
                            child: Text('Belum ada kelas yang tersedia'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: kelasList.length,
                            itemBuilder: (context, index) {
                              final k = kelasList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ListTile(
                                    title: Text(
                                      k['nama'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Mata Kuliah: ${k['mk'] ?? '-'}'),
                                        Text('Quiz Code: ${k['kode_kuis'] ?? '-'}'),
                                        Text('Class ID: ${k['id_kelas'] ?? '-'}'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.qr_code,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _showQrCodeDialog(k),
                                    ),
                                  ),
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
