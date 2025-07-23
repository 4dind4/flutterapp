import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class LihatNilaiTotalPage extends StatefulWidget {
  final String? userNim;
  final String? kodeKuis;
  const LihatNilaiTotalPage({super.key, this.userNim, this.kodeKuis});

  @override
  State<LihatNilaiTotalPage> createState() => _LihatNilaiTotalPageState();
}

class _LihatNilaiTotalPageState extends State<LihatNilaiTotalPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> nilaiList = [];
  String? nim;
  String? kodeKuis;
  Map<String, dynamic> nilaiPerSoal = {};
  double? nilaiTotal;

  @override
  void initState() {
    super.initState();
    nim = widget.userNim;
    kodeKuis = widget.kodeKuis;
    fetchNilai();
  }

  Future<void> fetchNilai() async {
    setState(() => isLoading = true);
    try {
      if (nim == null || nim!.isEmpty) {
        setState(() {
          nilaiList = [];
          isLoading = false;
        });
        return;
      }

      // Ambil quiz_attempts untuk NIM dan kode kuis
      final attempts = await Supabase.instance.client
          .from('quiz_attempts')
          .select()
          .eq('user_nim', nim!)
          .eq('quiz_code', kodeKuis ?? '');

      if (attempts.isNotEmpty) {
        final attempt = attempts[0];

        // Ambil nilai per soal (Map/JSON)
        if (attempt['nilai'] is Map) {
          nilaiPerSoal = Map<String, dynamic>.from(attempt['nilai']);
        } else if (attempt['nilai'] is String && attempt['nilai'].toString().isNotEmpty) {
          try {
            nilaiPerSoal = Map<String, dynamic>.from(jsonDecode(attempt['nilai']));
          } catch (_) {
            nilaiPerSoal = {};
          }
        } else {
          nilaiPerSoal = {};
        }

        // Ambil soal berdasarkan kode kuis
        final soalList = await Supabase.instance.client
            .from('soal')
            .select('id, pertanyaan, jawaban_benar')
            .eq('kode_kuis', attempt['quiz_code']);

        // Hitung nilai total (rata-rata)
        double total = 0;
        int jumlahSoal = soalList.length;
        for (var soal in soalList) {
          final soalId = soal['id'].toString();
          final n = double.tryParse(nilaiPerSoal[soalId]?.toString() ?? '0') ?? 0;
          total += n;
        }
        nilaiTotal = jumlahSoal > 0 ? total / jumlahSoal : 0;

        setState(() {
          nilaiList = [
            {
              'kode_kuis': attempt['quiz_code'],
              'user_nim': nim,
              'soal_list': soalList,
              'total_nilai': nilaiTotal,
            },
          ];
          isLoading = false;
        });
      } else {
        setState(() {
          nilaiList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        nilaiList = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat nilai: $e')));
    }
  }

  void _showInputDialog() async {
    final TextEditingController nimController = TextEditingController(
      text: nim ?? '',
    );
    List<String> kodeKuisPilihan = [];
    String? tempKodeKuis = kodeKuis;

    // Fetch kode kuis sesuai NIM jika NIM sudah ada
    if (nimController.text.trim().isNotEmpty) {
      final attempts = await Supabase.instance.client
          .from('quiz_attempts')
          .select('quiz_code')
          .eq('user_nim', nimController.text.trim());
      final kodeSet = <String>{};
      for (var a in attempts) {
        if (a['quiz_code'] != null && a['quiz_code'].toString().isNotEmpty) {
          kodeSet.add(a['quiz_code'].toString());
        }
      }
      kodeKuisPilihan = kodeSet.toList();
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text('Lihat Nilai Berdasarkan NIM & Kode Kuis'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nimController,
                        decoration: const InputDecoration(labelText: 'NIM'),
                        onChanged: (val) async {
                          // Update kode kuis pilihan saat NIM berubah
                          final attempts = await Supabase.instance.client
                              .from('quiz_attempts')
                              .select('quiz_code')
                              .eq('user_nim', val.trim());
                          final kodeSet = <String>{};
                          for (var a in attempts) {
                            if (a['quiz_code'] != null &&
                                a['quiz_code'].toString().isNotEmpty) {
                              kodeSet.add(a['quiz_code'].toString());
                            }
                          }
                          setStateDialog(() {
                            kodeKuisPilihan = kodeSet.toList();
                            tempKodeKuis = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: tempKodeKuis,
                        items:
                            kodeKuisPilihan
                                .map(
                                  (kode) => DropdownMenuItem(
                                    value: kode,
                                    child: Text(kode),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            tempKodeKuis = val;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Kode Kuis',
                        ),
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
                          nim = nimController.text.trim();
                          kodeKuis = tempKodeKuis;
                        });
                        Navigator.pop(context);
                        fetchNilai();
                      },
                      child: const Text('Lihat Nilai'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat Nilai'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Input NIM & Kode Kuis',
            onPressed: _showInputDialog,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : nilaiList.isEmpty
              ? const Center(child: Text('Belum ada nilai yang tersedia'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: nilaiList.length,
                itemBuilder: (context, index) {
                  final data = nilaiList[index];
                  final soalList = data['soal_list'] as List;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode Kuis: ${data['kode_kuis']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('NIM: ${data['user_nim']}'),
                          const SizedBox(height: 10),
                          const Text(
                            'Nilai Per Soal:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...soalList.map(
                            (soal) {
                              final soalId = soal['id'].toString();
                              final nilaiSoal = nilaiPerSoal[soalId]?.toString() ?? '-';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pertanyaan: ${soal['pertanyaan'] ?? 'Pertanyaan'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jawaban Benar: ${soal['jawaban_benar'] ?? '-'}',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                    Text(
                                      'Nilai: $nilaiSoal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Nilai (rata-rata):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                nilaiTotal != null
                                    ? nilaiTotal!.toStringAsFixed(2)
                                    : '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInputDialog,
        icon: const Icon(Icons.search),
        label: const Text('Input NIM & Kode Kuis'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
