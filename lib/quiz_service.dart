// lib/quiz_service.dart
import 'dart:math';
import 'dart:typed_data'; // Untuk Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Untuk menghasilkan UUID

class Kelas {
  final int id;
  final String idKelas; // Sesuai dengan id_kelas di tabel (uuid)
  final DateTime createdAt; // Sesuai dengan created_at di tabel (timestamptz)
  final String nama;
  final String mk;
  final String kodeKuis;
  final String? qrCodeUrl; // Kolom baru untuk URL gambar QR

  Kelas({
    required this.id,
    required this.idKelas,
    required this.createdAt,
    required this.nama,
    required this.mk,
    required this.kodeKuis,
    this.qrCodeUrl, // opsional karena bisa null
  });

  factory Kelas.fromJson(Map<String, dynamic> json) => Kelas(
    id: json['id'],
    idKelas: json['id_kelas'],
    createdAt: DateTime.parse(
      json['created_at'],
    ), // Parse string timestamp ke DateTime
    nama: json['nama'],
    mk: json['mk'],
    kodeKuis: json['kode_kuis'],
    qrCodeUrl: json['qr_code_url'], // Ambil dari JSON
  );

  // Perhatikan: toJson ini tidak akan digunakan untuk insert/update langsung di Supabase
  // jika kolom seperti 'id', 'created_at', dan 'id_kelas' dihasilkan oleh database.
  // Anda akan mengirim Map<String, dynamic> yang hanya berisi kolom yang perlu diinsert/update.
  Map<String, dynamic> toJson() => {
    'id': id,
    'id_kelas': idKelas,
    'created_at': createdAt.toIso8601String(),
    'nama': nama,
    'mk': mk,
    'kode_kuis': kodeKuis,
    'qr_code_url': qrCodeUrl,
  };
}

class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'kelas'; // Nama tabel kelas Anda di Supabase
  final String _qrBucketName =
      'qr-codes'; // <<<--- UPDATED: Nama bucket storage untuk QR codes

  // Mendapatkan semua entri kelas
  Future<List<Kelas>> getKelas() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      if (response.isNotEmpty) {
        return (response as List).map((json) => Kelas.fromJson(json)).toList();
      }
      return [];
    } on PostgrestException catch (e) {
      print('Supabase Postgrest Error getting Kelas: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error getting Kelas: $e');
      rethrow;
    }
  }

  // Menambahkan entri kelas baru
  Future<void> addKelas(String nama, String mk) async {
    try {
      final uuid = const Uuid().v4(); // Generate UUID untuk id_kelas
      final kodeKuis = _generateRandomCode(
        6,
      ); // Generate kode kuis acak 6 karakter

      await _supabase.from(_table).insert({
        'id_kelas': uuid, // UUID untuk id_kelas
        'nama': nama,
        'mk': mk,
        'kode_kuis': kodeKuis,
      });
    } on PostgrestException catch (e) {
      print('Supabase Postgrest Error adding Kelas: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error adding Kelas: $e');
      rethrow;
    }
  }

  // Memperbarui entri kelas yang sudah ada
  Future<void> updateKelas(int id, String nama, String mk) async {
    try {
      await _supabase
          .from(_table)
          .update({'nama': nama, 'mk': mk})
          .eq('id', id);
    } on PostgrestException catch (e) {
      print('Supabase Postgrest Error updating Kelas details: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error updating Kelas details: $e');
      rethrow;
    }
  }

  // Menghapus entri kelas berdasarkan ID
  Future<void> deleteKelas(int id) async {
    // Tipe ID adalah int
    try {
      // Optional: Anda bisa menambahkan logika di sini untuk menghapus file QR dari storage juga.
      // Ini akan membutuhkan Anda untuk mendapatkan `qr_code_url` atau nama filenya terlebih dahulu
      // dari database sebelum menghapus entri kelas.
      // Contoh (perlu parsing URL untuk mendapatkan nama file):
      // final response = await _supabase.from(_table).select('qr_code_url').eq('id', id).single();
      // if (response != null && response['qr_code_url'] != null) {
      //   final String qrUrl = response['qr_code_url'];
      //   final Uri uri = Uri.parse(qrUrl);
      //   final String fileName = uri.pathSegments.last; // Ambil bagian terakhir dari path URL
      //   await _supabase.storage.from(_qrBucketName).remove([fileName]);
      // }

      await _supabase.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      print('Supabase Postgrest Error deleting Kelas: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error deleting Kelas: $e');
      rethrow;
    }
  }

  // Mencari kelas berdasarkan nama atau mata kuliah
  Future<List<Kelas>> searchKelas(String query) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .or('nama.ilike.%$query%,mk.ilike.%$query%')
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        return (response as List).map((json) => Kelas.fromJson(json)).toList();
      }
      return [];
    } on PostgrestException catch (e) {
      print('Supabase Postgrest Error searching Kelas: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error searching Kelas: $e');
      rethrow;
    }
  }

  // Memperbarui URL QR Code di database
  Future<void> updateKelasQrCodeUrl(int id, String qrCodeUrl) async {
    try {
      await _supabase
          .from(_table)
          .update({'qr_code_url': qrCodeUrl})
          .eq('id', id);
    } on PostgrestException catch (e) {
      print('Supabase Postgrest Error updating QR Code URL: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error updating QR Code URL: $e');
      rethrow;
    }
  }

  // Fungsi untuk menghasilkan kode kuis acak
  String _generateRandomCode(int length) {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Metode untuk mengunggah gambar QR ke Supabase Storage (yang dipanggil dari kelas_page.dart)
  Future<String> uploadQrCodeImage(
    Uint8List imageBytes,
    String qrCodeText,
  ) async {
    try {
      final String fileName =
          'qr_${qrCodeText}_${const Uuid().v4()}.png'; // Gunakan UUID untuk nama file unik
      final String storagePath = 'public/$fileName'; // Path di dalam bucket

      await _supabase.storage
          .from(_qrBucketName)
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              cacheControl: '3600',
              upsert:
                  true, // Akan menimpa jika file dengan nama yang sama sudah ada
            ),
          );

      final String publicUrl = _supabase.storage
          .from(_qrBucketName)
          .getPublicUrl(storagePath);
      return publicUrl;
    } on StorageException catch (e) {
      print('Supabase Storage Error uploading QR code: ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error uploading QR code: $e');
      rethrow;
    }
  }
}
