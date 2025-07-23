// main_mhs.dart (This file will contain the student application's core widget)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Halaman & Model Dosen yang sudah ada (If still needed for some reason, keep them)
import 'kelas_page.dart';
import 'buat_soal_page.dart'; // Jika BuatSoalPage terpisah
import 'daftar_soal_page.dart'; // Jika DaftarSoalPage terpisah
import 'setting.dart'; // Halaman Setting Anda
import 'soal_model.dart'; // Model Soal dari Dosen
import 'soal_service.dart'; // Service Soal dari Dosen

// Impor semua komponen Mahasiswa dari file gabungan baru
import 'aplikasi_mhs.dart';

// This class encapsulates your student application's navigation and theming.
// It can be imported and used in your main.dart file.
class aplikasimhs extends StatelessWidget {
  const aplikasimhs({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kuis Mahasiswa', // Judul aplikasi
      debugShowCheckedModeBanner: false, // Menyembunyikan banner "DEBUG"
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 4, // Menambahkan sedikit elevasi ke AppBar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        cardTheme: CardThemeData(
          // Menggunakan CardTheme
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
        ),
      ),
      // Langsung menuju StudentHomePage sebagai halaman awal
      home: const StudentHomePage(), //

      routes: {
        // Rute untuk navigasi antar halaman kuis mahasiswa
        '/quiz_entry': (context) => const QuizEntryPage(), //
        '/quiz_preparation': (context) {
          // Ambil argumen yang dilewatkan dari QuizEntryPage
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          final Kelas kelas = args['kelas'] as Kelas;
          final String userNim = args['userNim'] as String;
          return QuizPreparationPage(kelas: kelas, userNim: userNim); //
        },
        '/quiz_page': (context) {
          // Ambil argumen yang dilewatkan dari QuizPreparationPage
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          final Kelas kelas = args['kelas'] as Kelas;
          final List<Soal> soalList = args['soalList'] as List<Soal>;
          final String userNim = args['userNim'] as String;
          return QuizPage(
            kelas: kelas,
            soalList: soalList,
            userNim: userNim,
          ); //
        },
        '/quiz_results': (context) {
          // Ambil argumen ID percobaan kuis dari QuizPage
          final String attemptId =
              ModalRoute.of(context)!.settings.arguments as String;
          return QuizResultsPage(quizAttemptId: attemptId); //
        },
      },
    );
  }
}
