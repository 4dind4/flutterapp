// import 'dart:io';
import 'dart:typed_data'; // Tambahkan import ini
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Pastikan ImagePicker diimpor
import 'package:mobile_scanner/mobile_scanner.dart'; // Jika masih menggunakan QR scanner
import 'kelas_page.dart'; // Ganti path sesuai lokasi Kelas model dan KelasService
import 'soal_model.dart'; // Ganti path sesuai lokasi Soal model
import 'soal_service.dart'; // Ganti path sesuai lokasi SoalService
import 'daftar_soal_page.dart'; // Jika ada halaman DaftarSoalPage

class BuatSoalPage extends StatefulWidget {
  const BuatSoalPage({super.key});

  @override
  State<BuatSoalPage> createState() => _BuatSoalPageState();
}

class _BuatSoalPageState extends State<BuatSoalPage> {
  final SoalService _soalService = SoalService();
  final TextEditingController _kodeKuisController = TextEditingController();
  List<Kelas> _kelasList = [];
  bool _isLoading = true;

  // Variabel untuk manajemen gambar
  Uint8List?
  _pickedImageBytes; // Menyimpan bytes gambar yang dipilih untuk pratinjau
  XFile? _pickedXFile; // Menyimpan XFile dari image_picker untuk diunggah

  bool _isSavingSoal = false; // Untuk indikator loading saat menyimpan soal

  @override
  void initState() {
    super.initState();
    _loadKelasWithSoal();
    // Tambahkan listener untuk _kodeKuisController agar memicu rebuild saat teks berubah
    _kodeKuisController.addListener(_onKodeKuisChanged);
  }

  @override
  void dispose() {
    // Hapus listener saat widget di-dispose
    _kodeKuisController.removeListener(_onKodeKuisChanged);
    _kodeKuisController.dispose();
    super.dispose();
  }

  // Metode baru untuk menangani perubahan pada _kodeKuisController
  void _onKodeKuisChanged() {
    // Panggil setState untuk memicu rebuild widget dan memperbarui kondisi tombol
    setState(() {
      // Tidak perlu melakukan apa-apa di sini, hanya memicu rebuild
    });
  }

  Future<void> _loadKelasWithSoal() async {
    setState(() => _isLoading = true);
    try {
      final data = await _soalService.getKelasWithSoal();
      setState(() {
        _kelasList = data;
      });
    } catch (e) {
      _showSnackBar("Error memuat data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (result != null) {
      setState(() {
        _kodeKuisController.text = result;
        // Panggil listener secara manual jika perubahan datang dari QR scanner
        _onKodeKuisChanged();
      });
    }
  }

  void _showBuatSoalModal({Soal? soalToEdit}) {
    final pertanyaanController = TextEditingController(
      text: soalToEdit?.pertanyaan ?? '',
    );
    final jawabanBenarController = TextEditingController(
      text: soalToEdit?.jawabanBenar ?? '',
    );
    final jawabanEssayController = TextEditingController(
      text: soalToEdit?.jawabanEssay ?? '',
    );
    String? currentImageUrl =
        soalToEdit?.gambarUrl; // URL gambar yang sudah ada dari Supabase

    // Reset picked image state for new modal or clear previous pick if editing
    _pickedXFile = null;
    _pickedImageBytes = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      soalToEdit == null ? 'Buat Soal Baru' : 'Edit Soal',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pertanyaanController,
                      decoration: const InputDecoration(
                        labelText: 'Pertanyaan',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: jawabanBenarController,
                      decoration: const InputDecoration(
                        labelText: 'Jawaban Benar',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: jawabanEssayController,
                      decoration: const InputDecoration(
                        labelText: 'Jawaban Essay (Opsional)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logika untuk menampilkan pratinjau gambar
                    if (_isSavingSoal) // Menggunakan state loading terpisah untuk menyimpan soal
                      const Center(child: CircularProgressIndicator())
                    else if (_pickedImageBytes !=
                        null) // Jika ada gambar baru yang dipilih
                      Image.memory(_pickedImageBytes!, height: 150)
                    else if (currentImageUrl != null &&
                        currentImageUrl!
                            .isNotEmpty) // Jika ada gambar lama dari URL
                      Image.network(
                        currentImageUrl!,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('Gagal memuat gambar dari URL');
                        },
                      ),

                    TextButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                        _pickedImageBytes != null
                            ? 'Ganti Gambar'
                            : (currentImageUrl != null &&
                                    currentImageUrl!.isNotEmpty
                                ? 'Ganti Gambar'
                                : 'Upload Gambar'),
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setModalState(() async {
                            _pickedXFile =
                                pickedFile; // Simpan XFile yang baru dipilih
                            _pickedImageBytes =
                                await pickedFile
                                    .readAsBytes(); // Baca bytes untuk pratinjau
                            currentImageUrl =
                                null; // Kosongkan URL gambar lama jika ada gambar baru dipilih
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (pertanyaanController.text.isEmpty ||
                                jawabanBenarController.text.isEmpty) {
                              _showSnackBar(
                                'Pertanyaan dan Jawaban Benar tidak boleh kosong!',
                              );
                              return;
                            }
                            setModalState(
                              () => _isSavingSoal = true,
                            ); // Set loading state untuk modal

                            try {
                              String? finalImageUrl =
                                  currentImageUrl; // Default ke URL yang sudah ada
                              if (_pickedXFile != null) {
                                // Jika ada gambar baru yang dipilih
                                finalImageUrl = await _soalService
                                    .uploadSoalImage(
                                      await _pickedXFile!.readAsBytes(),
                                    );
                              }

                              if (soalToEdit == null) {
                                // Buat Soal Baru
                                await _soalService.addSoal(
                                  kodeKuis: _kodeKuisController.text.trim(),
                                  pertanyaan: pertanyaanController.text,
                                  jawabanBenar: jawabanBenarController.text,
                                  jawabanEssay: jawabanEssayController.text,
                                  gambarUrl: finalImageUrl,
                                );
                                _showSnackBar('Soal berhasil disimpan!');
                              } else {
                                // Update Soal
                                await _soalService.updateSoal(
                                  id: soalToEdit.id,
                                  pertanyaan: pertanyaanController.text,
                                  jawabanBenar: jawabanBenarController.text,
                                  jawabanEssay: jawabanEssayController.text,
                                  gambarUrl: finalImageUrl,
                                );
                                _showSnackBar('Soal berhasil diperbarui!');
                              }

                              Navigator.pop(context); // Tutup modal
                              _loadKelasWithSoal(); // Refresh daftar kelas
                            } catch (e) {
                              _showSnackBar("Gagal menyimpan soal: $e");
                            } finally {
                              setModalState(
                                () => _isSavingSoal = false,
                              ); // Hentikan loading state
                            }
                          },
                          child: Text(soalToEdit == null ? 'Simpan' : 'Update'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        title: const Text('Buat Soal Kuis'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _loadKelasWithSoal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _kodeKuisController,
                decoration: InputDecoration(
                  labelText: 'Masukkan Kode Kuis',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQR,
                  ),
                ),
                onChanged: (text) {
                  setState(
                    () {},
                  ); // Memicu rebuild untuk mengaktifkan/menonaktifkan tombol
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    _kodeKuisController.text.trim().isEmpty ||
                            _isSavingSoal // Nonaktifkan saat sedang menyimpan
                        ? null
                        : () => _showBuatSoalModal(),
                icon: const Icon(Icons.add),
                label: const Text('Create Soal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Daftar Kelas (dengan Soal)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _kelasList.isEmpty
                        ? const Center(
                          child: Text('Belum ada soal yang dibuat.'),
                        )
                        : ListView.builder(
                          itemCount: _kelasList.length,
                          itemBuilder: (context, index) {
                            final kelas = _kelasList[index];
                            return Card(
                              child: ListTile(
                                title: Text(kelas.nama),
                                subtitle: Text(
                                  'MK: ${kelas.mk}\nKode: ${kelas.kodeKuis}',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              DaftarSoalPage(kelas: kelas),
                                    ),
                                  ).then(
                                    (_) => _loadKelasWithSoal(),
                                  ); // Refresh saat kembali
                                },
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Halaman terpisah untuk QR Scanner agar lebih rapi
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
