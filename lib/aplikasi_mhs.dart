import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Untuk QR Scanner
import 'kelas_page.dart';
import 'soal_model.dart'; // Model Soal dari Dosen
import 'lihat_nilai.dart';

// --- SERVICE: Quiz Attempt Service ---
// Layanan ini mengelola operasi terkait kuis mahasiswa dan interaksi Supabase.
// Pastikan tabel 'quiz_attempts' ada di Supabase dengan RLS yang sesuai.
class QuizAttemptService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _soalTable = 'soal';
  static const String _kelasTable = 'kelas';
  static const String _quizAttemptsTable =
      'quiz_attempts'; // Tabel Supabase untuk percobaan kuis

  // Mengambil detail kelas berdasarkan kode kuis.
  Future<Kelas?> getKelasByKodeKuis(String kodeKuis) async {
    try {
      final response =
          await _supabase
              .from(_kelasTable)
              .select()
              .eq('kode_kuis', kodeKuis.trim())
              .single(); // Mengambil satu baris saja

      if (response != null) {
        return Kelas.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getKelasByKodeKuis: $e');
      return null; // Mengembalikan null jika tidak ditemukan atau ada error
    }
  }

  // Mengambil daftar soal berdasarkan kode kuis.
  // Ini mirip dengan di SoalService, tetapi diulang di sini untuk self-containment.
  Future<List<Soal>> getSoalByKodeKuis(String kodeKuis) async {
    try {
      final response = await _supabase
          .from(_soalTable)
          .select()
          .eq('kode_kuis', kodeKuis.trim())
          .order('id', ascending: true); // Mengurutkan berdasarkan ID soal
      return (response as List).map((json) => Soal.fromJson(json)).toList();
    } catch (e) {
      print('Error getSoalByKodeKuis: $e');
      throw Exception('Gagal mendapatkan soal: $e');
    }
  }

  // Mengoreksi jawaban mahasiswa dan menyimpan hasil kuis ke Supabase.
  Future<String?> submitQuizAttempt({
    required String userNim,
    required String quizCode,
    required Map<String, String>
    studentAnswers, // Format: {'soal_id': 'jawaban_siswa'}
  }) async {
    try {
      // 1. Mengambil soal-soal asli dari database untuk mendapatkan jawaban yang benar.
      final List<Soal> originalSoals = await getSoalByKodeKuis(quizCode);
      final Map<String, Soal> soalMap = {
        for (var soal in originalSoals) soal.id.toString(): soal,
      };

      int totalScore = 0;
      final Map<String, int> scoresPerQuestion =
          {}; // Format: {'soal_id': score}

      // 2. Melakukan koreksi jawaban.
      studentAnswers.forEach((soalId, studentAnswer) {
        final Soal? soal = soalMap[soalId];
        if (soal != null) {
          final isCorrect =
              studentAnswer.trim().toLowerCase() ==
              soal.jawabanBenar.trim().toLowerCase();
          final score = isCorrect ? 10 : 0;
          scoresPerQuestion[soalId] = score;
          totalScore += score;
        } else {
          // Jika soal tidak ditemukan (mungkin dihapus setelah kuis dibuat), berikan skor 0.
          scoresPerQuestion[soalId] = 0;
        }
      });

      // 3. Menyimpan percobaan kuis ke tabel quiz_attempts
      final response = await _supabase
          .from(_quizAttemptsTable)
          .insert({
            'user_nim': userNim,
            'quiz_code': quizCode,
            'answers': studentAnswers, // Menyimpan jawaban siswa apa adanya
            'scores_per_question': scoresPerQuestion,
            'total_score': totalScore,
          })
          .select('id'); // Mengambil ID dari entri yang baru dibuat

      if (response != null && response.isNotEmpty) {
        return response[0]['id'].toString(); // Mengembalikan ID percobaan kuis
      }
      return null;
    } catch (e, s) {
      print('Error submitQuizAttempt: $e');
      print('StackTrace: $s');
      return null;
    }
  }

  // Mengambil hasil percobaan kuis berdasarkan ID percobaan.
  Future<Map<String, dynamic>?> getQuizAttemptResult(String attemptId) async {
    try {
      final response =
          await _supabase
              .from(_quizAttemptsTable)
              .select()
              .eq('id', attemptId)
              .single();

      if (response != null) {
        // Mengambil juga detail soalnya untuk ditampilkan bersama hasil.
        final quizCode = response['quiz_code'] as String;
        final List<Soal> originalSoals = await getSoalByKodeKuis(quizCode);
        final Map<String, Soal> soalMap = {
          for (var soal in originalSoals) soal.id.toString(): soal,
        };

        return {'attempt': response, 'original_soals': soalMap};
      }
      return null;
    } catch (e) {
      print('Error getQuizAttemptResult: $e');
      return null;
    }
  }
}

// --- PAGE: Student Home Page ---
// lib/pages/student_home_page.dart
// Halaman beranda untuk mahasiswa, menyediakan titik masuk ke kuis.
class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Mahasiswa'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                'Selamat Datang, Mahasiswa!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ayo mulai mengerjakan kuis Anda.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/quiz_entry');
                },
                icon: const Icon(Icons.quiz),
                label: const Text('Mulai Kuis'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LihatNilaiTotalPage(userNim: ''),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: const Text('Lihat Nilai'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PAGE: Quiz Entry Page ---
// lib/pages/quiz_entry_page.dart
// Halaman untuk memasukkan kode kuis dan NIM mahasiswa.
class QuizEntryPage extends StatefulWidget {
  const QuizEntryPage({super.key});

  @override
  State<QuizEntryPage> createState() => _QuizEntryPageState();
}

class _QuizEntryPageState extends State<QuizEntryPage> {
  final TextEditingController _kodeKuisController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final QuizAttemptService _quizAttemptService = QuizAttemptService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _kodeKuisController.addListener(_onTextChanged);
    _nimController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _kodeKuisController.removeListener(_onTextChanged);
    _nimController.removeListener(_onTextChanged);
    _kodeKuisController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _kodeKuisController.text = result;
      });
    }
  }

  Future<void> _checkKodeKuis() async {
    if (_kodeKuisController.text.trim().isEmpty ||
        _nimController.text.trim().isEmpty) {
      _showSnackBar('Kode Kuis dan NIM tidak boleh kosong.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Kelas? kelas = await _quizAttemptService.getKelasByKodeKuis(
        _kodeKuisController.text,
      );

      if (kelas != null) {
        // Meneruskan objek Kelas dan NIM ke halaman persiapan kuis
        Navigator.pushNamed(
          context,
          '/quiz_preparation',
          arguments: {'kelas': kelas, 'userNim': _nimController.text.trim()},
        );
      } else {
        _showSnackBar('Kode Kuis tidak ditemukan.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Masukkan Kode Kuis'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nimController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Induk Mahasiswa (NIM)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _kodeKuisController,
                decoration: InputDecoration(
                  labelText: 'Kode Kuis',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQR,
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    onPressed:
                        (_kodeKuisController.text.trim().isEmpty ||
                                _nimController.text.trim().isEmpty)
                            ? null
                            : _checkKodeKuis,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Lanjutkan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable QR Scanner Page
class QRScannerPage extends StatelessWidget {
  const QRScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}

// --- PAGE: Quiz Preparation Page ---
// lib/pages/quiz_preparation_page.dart
// Halaman yang menampilkan informasi kuis sebelum dimulai.
class QuizPreparationPage extends StatefulWidget {
  final Kelas kelas; // Kelas yang dipilih
  final String userNim; // NIM mahasiswa

  const QuizPreparationPage({
    super.key,
    required this.kelas,
    required this.userNim,
  });

  @override
  State<QuizPreparationPage> createState() => _QuizPreparationPageState();
}

class _QuizPreparationPageState extends State<QuizPreparationPage> {
  final QuizAttemptService _quizAttemptService = QuizAttemptService();
  bool _isLoadingSoals = false;

  // Tidak perlu _userNim di sini lagi karena sudah ada di widget.userNim

  Future<void> _startQuiz() async {
    setState(() => _isLoadingSoals = true);
    try {
      final soalList = await _quizAttemptService.getSoalByKodeKuis(
        widget.kelas.kodeKuis,
      );
      if (soalList.isNotEmpty) {
        Navigator.pushReplacementNamed(
          context,
          '/quiz_page',
          arguments: {
            'kelas': widget.kelas,
            'soalList': soalList,
            'userNim': widget.userNim, // Meneruskan NIM dari widget
          },
        );
      } else {
        _showSnackBar('Tidak ada soal ditemukan untuk kuis ini.');
      }
    } catch (e) {
      _showSnackBar('Error memuat soal: ${e.toString()}');
    } finally {
      setState(() => _isLoadingSoals = false);
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
      appBar: AppBar(title: const Text('Persiapan Kuis'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 60,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  'Informasi Kuis',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 30, thickness: 1),
                _buildInfoRow('Mata Kuliah', widget.kelas.mk),
                _buildInfoRow('Nama Kelas', widget.kelas.nama),
                _buildInfoRow('Kode Kuis', widget.kelas.kodeKuis),
                _buildInfoRow('NIM Mahasiswa', widget.userNim), // Tampilkan NIM
                const SizedBox(height: 30),
                _isLoadingSoals
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _startQuiz,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Mulai Kuis'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

// --- PAGE: Quiz Page ---
// lib/pages/quiz_page.dart
// Halaman utama untuk mengerjakan soal kuis.
class QuizPage extends StatefulWidget {
  final Kelas kelas;
  final List<Soal> soalList;
  final String userNim;

  const QuizPage({
    super.key,
    required this.kelas,
    required this.soalList,
    required this.userNim,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Map<String, TextEditingController> _answerControllers = {};
  final QuizAttemptService _quizAttemptService = QuizAttemptService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller untuk setiap soal
    for (var soal in widget.soalList) {
      _answerControllers[soal.id.toString()] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Hapus controller saat widget di-dispose
    _answerControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);

    final Map<String, String> studentAnswers = {};
    _answerControllers.forEach((soalId, controller) {
      studentAnswers[soalId] = controller.text.trim();
    });

    try {
      // START: Tambahkan kode print di sini untuk debugging
      print('--- DEBUG: Data for submitQuizAttempt ---');
      print('user_nim: ${widget.userNim}');
      print('quiz_code: ${widget.kelas.kodeKuis}');
      print('studentAnswers: $studentAnswers');

      // Untuk mendapatkan scoresPerQuestion dan totalScore yang *akan* dihitung
      // oleh service, kita perlu sedikit memodifikasi service atau mengulang logikanya di sini.
      // Cara paling mudah untuk debugging adalah meniru logika perhitungan di QuizAttemptService
      // atau jika Anda bisa membuat metode baru di QuizAttemptService untuk menghitungnya.

      // Contoh sederhana meniru sebagian logika perhitungan untuk debugging:
      final List<Soal> originalSoals = await _quizAttemptService
          .getSoalByKodeKuis(widget.kelas.kodeKuis);
      final Map<String, Soal> soalMap = {
        for (var soal in originalSoals) soal.id.toString(): soal,
      };

      int debugTotalScore = 0;
      final Map<String, int> debugScoresPerQuestion = {};
      studentAnswers.forEach((soalId, studentAnswer) {
        final Soal? soal = soalMap[soalId];
        if (soal != null) {
          final isCorrect =
              studentAnswer.trim().toLowerCase() ==
              soal.jawabanBenar.trim().toLowerCase();
          final score = isCorrect ? 10 : 0;
          debugScoresPerQuestion[soalId] = score;
          debugTotalScore += score;
        } else {
          debugScoresPerQuestion[soalId] = 0;
        }
      });

      print(
        'scoresPerQuestion (calculated for debug): $debugScoresPerQuestion',
      );
      print('totalScore (calculated for debug): $debugTotalScore');
      print('--- END DEBUG ---');

      final String? attemptId = await _quizAttemptService.submitQuizAttempt(
        userNim: widget.userNim,
        quizCode: widget.kelas.kodeKuis,
        studentAnswers: studentAnswers,
      );

      if (attemptId != null) {
        Navigator.pushReplacementNamed(
          context,
          '/quiz_results',
          arguments: attemptId, // Kirim ID percobaan kuis ke halaman hasil
        );
      } else {
        _showSnackBar('Gagal menyimpan hasil kuis. Coba lagi.');
      }
    } catch (e) {
      _showSnackBar('Error saat submit kuis: ${e.toString()}');
      print('Submit Quiz Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
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
        title: Text('Kuis: ${widget.kelas.mk} (${widget.kelas.kodeKuis})'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: widget.soalList.length,
            itemBuilder: (context, index) {
              final soal = widget.soalList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soal ${index + 1}.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        soal.pertanyaan,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (soal.gambarUrl != null && soal.gambarUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Image.network(
                            soal.gambarUrl!,
                            height: 150,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Text('Gagal memuat gambar soal.'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _answerControllers[soal.id.toString()],
                        decoration: const InputDecoration(
                          labelText: 'Jawaban Anda',
                          border: OutlineInputBorder(),
                          hintText: 'Ketik jawaban Anda di sini',
                        ),
                        maxLines:
                            soal.jawabanEssay != null
                                ? 5
                                : 1, // Lebih banyak baris untuk essay
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child:
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                        onPressed: _submitQuiz,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAGE: Quiz Results Page ---
// lib/pages/quiz_results_page.dart
// Halaman untuk menampilkan hasil kuis mahasiswa setelah selesai.
class QuizResultsPage extends StatefulWidget {
  final String quizAttemptId;

  const QuizResultsPage({super.key, required this.quizAttemptId});

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  final QuizAttemptService _quizAttemptService = QuizAttemptService();
  Map<String, dynamic>? _quizResult;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuizResults();
  }

  Future<void> _fetchQuizResults() async {
    setState(() => _isLoading = true);
    try {
      final result = await _quizAttemptService.getQuizAttemptResult(
        widget.quizAttemptId,
      );
      if (result != null) {
        setState(() {
          _quizResult = result;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat hasil kuis.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Kuis'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghapus tombol kembali default
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _quizResult == null
              ? const Center(child: Text('Data hasil kuis tidak ditemukan.'))
              : RefreshIndicator(
                onRefresh: _fetchQuizResults,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildOverallScoreCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Detail Jawaban:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(),
                    _buildQuestionResults(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        ); // Kembali ke halaman utama
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Kembali ke Beranda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildOverallScoreCard() {
    final totalScore = _quizResult!['attempt']['total_score'] as int;
    final Map<String, int> scoresPerQuestion =
        (_quizResult!['attempt']['scores_per_question'] as Map)
            .cast<String, int>();
    final int totalQuestions = scoresPerQuestion.length;
    final int correctAnswers =
        scoresPerQuestion.values.where((score) => score == 10).length;

    return Card(
      elevation: 6,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
            const SizedBox(height: 15),
            Text(
              'Skor Total Anda:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$totalScore / ${totalQuestions * 10}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '($correctAnswers dari $totalQuestions soal benar)',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionResults() {
    final Map<String, dynamic> attempt = _quizResult!['attempt'];
    final Map<String, Soal> originalSoals = _quizResult!['original_soals'];
    final Map<String, String> studentAnswers =
        (attempt['answers'] as Map).cast<String, String>();
    final Map<String, int> scoresPerQuestion =
        (attempt['scores_per_question'] as Map).cast<String, int>();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: originalSoals.length,
      itemBuilder: (context, index) {
        final soalId = originalSoals.keys.elementAt(index);
        final Soal soal = originalSoals[soalId]!;
        final studentAnswer = studentAnswers[soalId] ?? 'Tidak menjawab';
        final score = scoresPerQuestion[soalId] ?? 0;
        final bool isCorrect = score == 10;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16.0),
          color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Soal ${index + 1}.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  soal.pertanyaan,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (soal.gambarUrl != null && soal.gambarUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Image.network(
                      soal.gambarUrl!,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Text('Gagal memuat gambar soal.'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Jawaban Anda:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  studentAnswer,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jawaban Benar:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  soal.jawabanBenar,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (!isCorrect &&
                    soal.jawabanEssay != null &&
                    soal.jawabanEssay!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Keterangan: ${soal.jawabanEssay!}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Skor: $score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- PAGE: Lihat Nilai ---
// lib/pages/lihat_nilai_page.dart
// Halaman untuk melihat nilai dan hasil kuis yang telah diambil mahasiswa.
class LihatNilaiPage extends StatelessWidget {
  final String userNim;
  const LihatNilaiPage({Key? key, required this.userNim}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lihat Nilai'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assessment, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                'Riwayat Nilai Kuis',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchQuizResults(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Belum ada hasil kuis.'));
                    } else {
                      final results = snapshot.data!;
                      return ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final result = results[index];
                          final kelas = result['kelas'] as Kelas;
                          final totalScore = result['total_score'] as int;
                          final dateTime = DateTime.parse(result['created_at']);
                          final formattedDate =
                              '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            title: Text(
                              '${kelas.mk} - ${kelas.nama}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kode Kuis: ${kelas.kodeKuis}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Tanggal: $formattedDate',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Skor: $totalScore',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        totalScore >= 70
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigasi ke halaman detail hasil kuis
                              Navigator.pushNamed(
                                context,
                                '/quiz_results',
                                arguments: result['id'],
                              );
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke halaman sebelumnya
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchQuizResults() async {
    final SupabaseClient supabase = Supabase.instance.client;
    final String userNim = this.userNim; // Menggunakan userNim dari widget

    try {
      final response = await supabase
          .from('quiz_attempts')
          .select(
            'id, quiz_code, created_at, total_score, kelas (id_kelas, nama, mk, kode_kuis)',
          )
          .eq('user_nim', userNim)
          .order('created_at', ascending: false);

      // Mengembalikan data hasil kuis beserta detail kelasnya
      return (response as List)
          .map(
            (item) => {
              'id': item['id'],
              'quiz_code': item['quiz_code'],
              'created_at': item['created_at'],
              'total_score': item['total_score'],
              'kelas': Kelas.fromJson(item['kelas']),
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching quiz results: $e');
      return [];
    }
  }
}
