// lib/pages/daftar_soal_page.dart

import 'package:flutter/material.dart';
import 'kelas_page.dart'; // Ganti path
import 'soal_model.dart'; // Ganti path
import 'soal_service.dart'; // Ganti path
// import 'buat_soal_page.dart';

class DaftarSoalPage extends StatefulWidget {
  final Kelas kelas;
  const DaftarSoalPage({super.key, required this.kelas});

  @override
  State<DaftarSoalPage> createState() => _DaftarSoalPageState();
}

class _DaftarSoalPageState extends State<DaftarSoalPage> {
  final SoalService _soalService = SoalService();
  List<Soal> _soalList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    try {
      final data = await _soalService.getSoalByKodeKuis(widget.kelas.kodeKuis);
      setState(() {
        _soalList = data;
      });
    } catch (e) {
      _showSnackBar("Error memuat soal: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSoal(int id) async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text('Apakah Anda yakin ingin menghapus soal ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _soalService.deleteSoal(id);
        _showSnackBar('Soal berhasil dihapus');
        _loadSoal(); // Refresh list
      } catch (e) {
        _showSnackBar('Gagal menghapus soal: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soal - ${widget.kelas.nama}'),
        backgroundColor: Colors.indigo,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _soalList.isEmpty
              ? const Center(child: Text('Tidak ada soal untuk kelas ini.'))
              : RefreshIndicator(
                onRefresh: _loadSoal,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _soalList.length,
                  itemBuilder: (context, index) {
                    final soal = _soalList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soal #${index + 1}: ${soal.pertanyaan}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (soal.gambarUrl != null) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: Image.network(
                                  soal.gambarUrl!,
                                  height: 150,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text('Jawaban Benar: ${soal.jawabanBenar}'),
                            if (soal.jawabanEssay != null &&
                                soal.jawabanEssay!.isNotEmpty)
                              Text('Jawaban Essay: ${soal.jawabanEssay}'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    // Logika edit akan membuka modal yang sama dengan di halaman buat soal
                                    _showSnackBar(
                                      "Fitur edit akan membuka modal.",
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteSoal(soal.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
