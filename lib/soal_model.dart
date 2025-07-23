// lib/models/soal_model.dart

class Soal {
  final int id;
  final DateTime createdAt;
  final String kodeKuis;
  final String pertanyaan;
  final String? gambarUrl;
  final String? jawabanEssay;
  final String jawabanBenar;

  Soal({
    required this.id,
    required this.createdAt,
    required this.kodeKuis,
    required this.pertanyaan,
    this.gambarUrl,
    this.jawabanEssay,
    required this.jawabanBenar,
  });

  factory Soal.fromJson(Map<String, dynamic> json) => Soal(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        kodeKuis: json['kode_kuis'],
        pertanyaan: json['pertanyaan'],
        gambarUrl: json['gambar_url'],
        jawabanEssay: json['jawaban_essay'],
        jawabanBenar: json['jawaban_benar'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'kode_kuis': kodeKuis,
        'pertanyaan': pertanyaan,
        'gambar_url': gambarUrl,
        'jawaban_essay': jawabanEssay,
        'jawaban_benar': jawabanBenar,
      };
}
