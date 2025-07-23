import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TabSoalEssay extends StatefulWidget {
  const TabSoalEssay({super.key});

  @override
  State<TabSoalEssay> createState() => _TabSoalEssayState();
}

class _TabSoalEssayState extends State<TabSoalEssay> {
  final TextEditingController _kodeKuisController = TextEditingController();
  bool _kuisValid = false;
  bool _isSubmitted = false;

  List<Map<String, dynamic>> _soalEssay = [];
  final Map<int, TextEditingController> _jawabanControllers = {};

  Future<void> _fetchSoalFromSupabase(String kodeKuis) async {
    final response = await Supabase.instance.client
        .from('soal')
        .select()
        .eq('kode_kuis', kodeKuis);

    if (response.isNotEmpty) {
      setState(() {
        _soalEssay = List<Map<String, dynamic>>.from(response);
        _kuisValid = true;
        _isSubmitted = false;
        _jawabanControllers.clear();
        for (int i = 0; i < _soalEssay.length; i++) {
          _jawabanControllers[i] = TextEditingController();
        }
      });
    } else {
      setState(() {
        _kuisValid = false;
        _soalEssay = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode Kuis tidak ditemukan atau tidak ada soal!'),
        ),
      );
    }
  }

  void _cekKodeKuis() {
    final kode = _kodeKuisController.text.trim();
    if (kode.isNotEmpty) {
      _fetchSoalFromSupabase(kode);
    }
  }

  Future<void> _submitJawaban() async {
    try {
      for (int i = 0; i < _soalEssay.length; i++) {
        final soal = _soalEssay[i];
        final jawaban = _jawabanControllers[i]?.text ?? '';
        // Pastikan ada kolom id pada soal
        final soalId = soal['id'];
        if (soalId != null) {
          await Supabase.instance.client
              .from('soal')
              .update({'jawaban_essay': jawaban})
              .eq('id', soalId);
        }
      }
      setState(() {
        _isSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban berhasil disimpan ke database!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan jawaban: $e')));
    }
  }

  @override
  void dispose() {
    _kodeKuisController.dispose();
    for (var c in _jawabanControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan Kode Kuis:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kodeKuisController,
                  decoration: const InputDecoration(
                    labelText: 'Input Kode Kuis Random',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _cekKodeKuis,
                icon: const Icon(Icons.check),
                label: const Text('Cek Kode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_kuisValid)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Soal Essay:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _soalEssay.length,
                  itemBuilder: (context, i) {
                    final soal = _soalEssay[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Soal ${i + 1}: ${soal['pertanyaan']}'),
                            const SizedBox(height: 8),
                            if (soal['gambar_url'] != null &&
                                soal['gambar_url'].toString().isNotEmpty)
                              Image.network(
                                soal['gambar_url'],
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            const SizedBox(height: 8),
                            if (!_isSubmitted)
                              TextField(
                                controller: _jawabanControllers[i],
                                minLines: 2,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Jawaban Essay',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            if (_isSubmitted)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jawaban Anda: ${_jawabanControllers[i]?.text ?? ""}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Jawaban Benar: ${soal['jawaban_benar'] ?? "-"}',
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (!_isSubmitted)
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitJawaban,
                      child: const Text('Submit Semua Jawaban'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                if (_isSubmitted)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Jawaban telah disubmit!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
