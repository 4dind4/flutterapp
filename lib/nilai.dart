import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InputNilaiManualPage extends StatefulWidget {
  const InputNilaiManualPage({super.key});

  @override
  State<InputNilaiManualPage> createState() => _InputNilaiManualPageState();
}

class _InputNilaiManualPageState extends State<InputNilaiManualPage> {
  final TextEditingController nimController = TextEditingController();
  final TextEditingController kodeQuizController = TextEditingController();
  final Map<int, TextEditingController> nilaiControllers = {};
  bool isLoading = false;
  List<Map<String, dynamic>> soalList = [];
  Map<String, dynamic>? quizAttempt;
  bool isOnSecondPage = false;
  bool isSubmitted = false; // Tambahan

  Future<void> fetchDataByNimAndQuiz(String nim, String kodeQuiz) async {
    setState(() {
      isLoading = true;
      soalList.clear();
      nilaiControllers.clear();
      quizAttempt = null;
    });

    try {
      // Ambil quiz_attempts untuk NIM dan kode quiz
      final attempts = await Supabase.instance.client
          .from('quiz_attempts')
          .select()
          .eq('user_nim', nim)
          .eq('quiz_code', kodeQuiz);

      if (attempts == null || attempts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data quiz tidak ditemukan')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      quizAttempt = Map<String, dynamic>.from(attempts[0]);

      // Ambil soal untuk kode quiz
      final soalData = await Supabase.instance.client
          .from('soal')
          .select()
          .eq('kode_kuis', kodeQuiz);

      soalList = List<Map<String, dynamic>>.from(soalData);

      // Siapkan controller nilai
      for (var soal in soalList) {
        nilaiControllers[soal['id']] = TextEditingController(
          text: soal['nilai']?.toString() ?? '',
        );
      }

      setState(() {
        isOnSecondPage = true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> simpanNilai(int idSoal, String nilai) async {
    await Supabase.instance.client
        .from('soal')
        .update({'nilai': nilai})
        .eq('id', idSoal);
  }

  Future<void> submitAllNilai() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Buat map nilai: {idSoal: nilai}
      final Map<String, dynamic> nilaiMap = {};
      for (var soal in soalList) {
        final id = soal['id'];
        final nilai = nilaiControllers[id]?.text.trim() ?? '';
        nilaiMap[id.toString()] = nilai;
      }

      // Update kolom 'nilai' di tabel quiz_attempts
      await Supabase.instance.client
          .from('quiz_attempts')
          .update({'nilai': nilaiMap})
          .eq('id', quizAttempt?['id']);

      setState(() {
        isSubmitted = true;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban anda sudah ke submit')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal submit nilai: $e')));
    }
  }

  @override
  void dispose() {
    nimController.dispose();
    kodeQuizController.dispose();
    for (var controller in nilaiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai Manual'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue.shade700,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.blue.shade50,
        child: isOnSecondPage ? buildSecondPage() : buildFirstPage(),
      ),
    );
  }

  Widget buildFirstPage() {
    return Center(
      child: SingleChildScrollView(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cari Data Quiz Mahasiswa',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nimController,
                  decoration: InputDecoration(
                    labelText: 'Masukkan NIM Mahasiswa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kodeQuizController,
                  decoration: InputDecoration(
                    labelText: 'Masukkan Kode Quiz',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.quiz),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        isLoading
                            ? null
                            : () => fetchDataByNimAndQuiz(
                              nimController.text.trim(),
                              kodeQuizController.text.trim(),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label:
                        isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Tampilkan Quiz Mahasiswa',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSecondPage() {
    final answers = Map<String, dynamic>.from(quizAttempt?['answers'] ?? {});
    final nim = quizAttempt?['user_nim'] ?? '-';
    final kodeQuiz = quizAttempt?['quiz_code'] ?? '-';

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIM Mahasiswa: $nim',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode Quiz: $kodeQuiz',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: soalList.length,
                  itemBuilder: (context, index) {
                    final soal = soalList[index];
                    final soalId = soal['id'];
                    final pertanyaan = soal['pertanyaan'];
                    final jawabanBenar = soal['jawaban_benar'] ?? '';
                    final gambarUrl = soal['gambar_url'];
                    final jawabanMahasiswa = answers[soalId.toString()] ?? '-';
                    final nilaiController = nilaiControllers[soalId]!;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pertanyaan: $pertanyaan"),
                            if (gambarUrl != null &&
                                gambarUrl.toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Image.network(gambarUrl),
                              ),
                            Text("Jawaban Benar: $jawabanBenar"),
                            Text("Jawaban Mahasiswa: $jawabanMahasiswa"),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nilaiController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Nilai Jawaban Essay",
                                border: OutlineInputBorder(),
                              ),
                              enabled: !isSubmitted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!isSubmitted)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitAllNilai,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Submit Semua Nilai",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              if (isSubmitted)
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Jawaban anda sudah ke submit.",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isOnSecondPage = false;
                            isSubmitted = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Halaman Input Nilai',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
  }
}
