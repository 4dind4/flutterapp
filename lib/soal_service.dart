// lib/services/soal_service.dart

import 'dart:typed_data'; // Tambahkan import ini
import 'kelas_page.dart'; // Ganti dengan path model Kelas Anda
import 'soal_model.dart'; // Ganti dengan path model Soal Anda
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SoalService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _soalTable = 'soal';
  final String _kelasTable = 'kelas';
  final String _soalImageBucket =
      'soal-images'; // Nama bucket untuk gambar soal

  // Menambah soal baru
  Future<void> addSoal({
    required String kodeKuis,
    required String pertanyaan,
    String? gambarUrl,
    String? jawabanEssay,
    required String jawabanBenar,
  }) async {
    await _supabase.from(_soalTable).insert({
      'kode_kuis': kodeKuis,
      'pertanyaan': pertanyaan,
      'gambar_url': gambarUrl,
      'jawaban_essay': jawabanEssay,
      'jawaban_benar': jawabanBenar,
    });
  }

  // Mengupdate soal yang ada
  Future<void> updateSoal({
    required int id,
    required String pertanyaan,
    String? gambarUrl,
    String? jawabanEssay,
    required String jawabanBenar,
  }) async {
    await _supabase
        .from(_soalTable)
        .update({
          'pertanyaan': pertanyaan,
          'gambar_url': gambarUrl,
          'jawaban_essay': jawabanEssay,
          'jawaban_benar': jawabanBenar,
        })
        .eq('id', id);
  }

  // Mengunggah gambar soal ke Supabase Storage (Menerima Uint8List)
  Future<String?> uploadSoalImage(Uint8List imageBytes) async {
    // Perubahan dari File imageFile
    try {
      final fileName = '${const Uuid().v4()}.jpg';
      final path =
          'public/$fileName'; // Anda bisa menyesuaikan path jika ingin subfolder lain

      print(
        'Attempting to upload image to bucket: $_soalImageBucket, path: $path',
      );
      print(
        'Image bytes length: ${imageBytes.lengthInBytes}',
      ); // Tambahkan logging ukuran bytes

      await _supabase.storage
          .from(_soalImageBucket)
          .uploadBinary(
            // Menggunakan uploadBinary
            path,
            imageBytes, // Langsung gunakan bytes
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType:
                  'image/jpeg', // Sesuaikan dengan tipe gambar yang diharapkan
            ),
          );

      final publicUrl = _supabase.storage
          .from(_soalImageBucket)
          .getPublicUrl(path);
      print(
        'Image uploaded successfully. Public URL: $publicUrl',
      ); // Logging URL sukses
      return publicUrl;
    } catch (e, s) {
      // Tambahkan StackTrace 's'
      print("Error uploading image: $e");
      print("StackTrace: $s"); // Cetak stack trace untuk detail lebih lanjut
      return null;
    }
  }

  // Mendapatkan daftar kelas yang sudah memiliki soal
  Future<List<Kelas>> getKelasWithSoal() async {
    // 1. Dapatkan semua kode kuis unik dari tabel soal
    final responseSoal = await _supabase.from(_soalTable).select('kode_kuis');
    final uniqueKodeKuis =
        (responseSoal as List)
            .map<String>((item) => item['kode_kuis'] as String)
            .toSet()
            .toList();

    if (uniqueKodeKuis.isEmpty) {
      return [];
    }

    // 2. Dapatkan data kelas berdasarkan kode kuis yang unik
    // Menggunakan .in_() sesuai rekomendasi error sebelumnya
    final responseKelas = await _supabase
        .from(_kelasTable)
        .select()
        .inFilter('kode_kuis', uniqueKodeKuis) // Menggunakan in_()
        .order('created_at', ascending: false);

    return (responseKelas as List).map((json) => Kelas.fromJson(json)).toList();
  }

  // Mendapatkan semua soal berdasarkan kode kuis
  Future<List<Soal>> getSoalByKodeKuis(String kodeKuis) async {
    final response = await _supabase
        .from(_soalTable)
        .select()
        .eq('kode_kuis', kodeKuis)
        .order('created_at', ascending: true);
    return (response as List).map((json) => Soal.fromJson(json)).toList();
  }

  // Menghapus soal
  Future<void> deleteSoal(int id) async {
    await _supabase.from(_soalTable).delete().eq('id', id);
  }
}
