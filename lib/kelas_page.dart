import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

// Import halaman BuatSoalPage
import 'buat_soal_page.dart'; // Asumsi nama file adalah buat_soal_page.dart

class Kelas {
  final int id;
  final String idKelas;
  final DateTime createdAt;
  final String nama;
  final String mk;
  final String kodeKuis;
  final String? qrCodeUrl;

  Kelas({
    required this.id,
    required this.idKelas,
    required this.createdAt,
    required this.nama,
    required this.mk,
    required this.kodeKuis,
    this.qrCodeUrl,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) => Kelas(
    id: json['id'],
    idKelas: json['id_kelas'],
    createdAt: DateTime.parse(json['created_at']),
    nama: json['nama'],
    mk: json['mk'],
    kodeKuis: json['kode_kuis'],
    qrCodeUrl: json['qr_code_url'],
  );
}

class KelasService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'kelas';

  Future<List<Kelas>> getKelas() async {
    final response = await _supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => Kelas.fromJson(json)).toList();
  }

  Future<void> addKelas(String nama, String mk) async {
    final uuid = Uuid().v4();
    final kodeKuis = _generateRandomCode(6);

    await _supabase.from(_table).insert({
      'id_kelas': uuid,
      'nama': nama,
      'mk': mk,
      'kode_kuis': kodeKuis,
    });
  }

  Future<void> updateKelas(int id, String nama, String mk) async {
    await _supabase.from(_table).update({'nama': nama, 'mk': mk}).eq('id', id);
  }

  Future<void> deleteKelas(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }

  Future<List<Kelas>> searchKelas(String query) async {
    final response = await _supabase
        .from(_table)
        .select()
        .or('nama.ilike.%$query%,mk.ilike.%$query%')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Kelas.fromJson(json)).toList();
  }

  Future<void> updateKelasQrCodeUrl(int id, String qrCodeUrl) async {
    await _supabase
        .from(_table)
        .update({'qr_code_url': qrCodeUrl})
        .eq('id', id);
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}

class KelasPage extends StatefulWidget {
  const KelasPage({super.key});

  @override
  State<KelasPage> createState() => _KelasPageState();
}

class _KelasPageState extends State<KelasPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController mkController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final KelasService kelasService = KelasService();
  List<Kelas> kelasList = [];
  String? _currentQrCodeTextForGeneration;
  Kelas? kelasToEdit;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await kelasService.getKelas();
      setState(() {
        kelasList = data;
      });
    } catch (e) {
      _showSnackBar("Error loading data: ${e.toString()}");
    }
  }

  Future<void> handleAddOrUpdate() async {
    if (mkController.text.isEmpty) {
      _showSnackBar("Mata Kuliah cannot be empty");
      return;
    }

    try {
      if (kelasToEdit == null) {
        // Add new class
        await kelasService.addKelas(
          "Class-${DateTime.now().millisecondsSinceEpoch}", // Auto-generated class name
          mkController.text,
        );
        _showSnackBar("Class added successfully!");
      } else {
        // Update existing class
        await kelasService.updateKelas(
          kelasToEdit!.id,
          namaController.text,
          mkController.text,
        );
        _showSnackBar("Class updated successfully!");
      }
      clearForm();
      loadData();
    } catch (e) {
      _showSnackBar("Failed to save class: ${e.toString()}");
    }
  }

  Future<void> _generateAndUploadQrCode(Kelas kelas) async {
    setState(() {
      _currentQrCodeTextForGeneration = kelas.kodeKuis;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final fileName = 'qr_${kelas.id}.png';
      final storagePath = 'public/$fileName';

      await Supabase.instance.client.storage
          .from('qr-codes')
          .uploadBinary(
            storagePath,
            pngBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('qr-codes')
          .getPublicUrl(storagePath);
      await kelasService.updateKelasQrCodeUrl(kelas.id, publicUrl);
      _showSnackBar("QR Code generated and saved!");
      setState(() {
        _currentQrCodeTextForGeneration = null;
      });
      loadData();
    } catch (e) {
      _showSnackBar("Failed to generate QR Code: ${e.toString()}");
      setState(() {
        _currentQrCodeTextForGeneration = null;
      });
    }
  }

  Future<void> _showQrCodeDialog(Kelas kelas) async {
    String? imageUrl = kelas.qrCodeUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      _showSnackBar("Generating QR Code...");
      await _generateAndUploadQrCode(kelas);
      // After generation, reload data to get the updated Kelas object with qrCodeUrl
      final updatedKelasList = await kelasService.getKelas();
      kelas = updatedKelasList.firstWhere((k) => k.id == kelas.id);
      imageUrl = kelas.qrCodeUrl;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Class QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quiz Code: ${kelas.kodeKuis}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.network(
                  imageUrl!,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Failed to load QR image');
                  },
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download QR Code'),
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(imageUrl!))) {
                      await launchUrl(Uri.parse(imageUrl));
                    } else {
                      _showSnackBar('Cannot open URL');
                    }
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void handleEdit(Kelas kelas) {
    setState(() {
      kelasToEdit = kelas;
      namaController.text = kelas.nama;
      mkController.text = kelas.mk;
    });
  }

  Future<void> handleDelete(int id) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this class?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await kelasService.deleteKelas(id);
                  _showSnackBar("Class deleted successfully!");
                  loadData();
                } catch (e) {
                  _showSnackBar("Failed to delete class: ${e.toString()}");
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void clearForm() {
    setState(() {
      namaController.clear();
      mkController.clear();
      kelasToEdit = null;
    });
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
        centerTitle: true,
        title: const Text('Input Quiz'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: mkController,
                decoration: const InputDecoration(
                  labelText: 'Mata Kuliah',
                  prefixIcon: Icon(Icons.book),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: handleAddOrUpdate,
                icon: Icon(kelasToEdit == null ? Icons.add : Icons.update),
                label: Text(kelasToEdit == null ? 'Add Class' : 'Update Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      kelasToEdit == null ? Colors.green : Colors.orange,
                ),
              ),
              if (kelasToEdit != null) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: clearForm,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search Class',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      loadData();
                    },
                  ),
                ),
                onChanged: (query) async {
                  if (query.isEmpty) {
                    loadData();
                  } else {
                    final filteredData = await kelasService.searchKelas(query);
                    setState(() {
                      kelasList = filteredData;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Class List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              kelasList.isEmpty
                  ? const Center(child: Text('No classes available'))
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kelasList.length,
                    itemBuilder: (context, index) {
                      final k = kelasList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ListTile(
                            title: Text(
                              k.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mata Kuliah: ${k.mk}'),
                                Text('Quiz Code: ${k.kodeKuis}'),
                                Text('Class ID: ${k.idKelas}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.qr_code,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showQrCodeDialog(k),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => handleEdit(k),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => handleDelete(k.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              if (_currentQrCodeTextForGeneration != null)
                Center(
                  // <--- TAMBAHKAN WIDGET CENTER DI SINI
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: QrImageView(
                      data: _currentQrCodeTextForGeneration!,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // --- PENAMBAHAN FLOATING ACTION BUTTON DI SINI ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke BuatSoalPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BuatSoalPage()),
          );
        },
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Buat Soal Baru',
      ),
      // ----------------------------------------------------
    );
  }
}
