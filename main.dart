import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

List<CameraDescription> cameras = [];
List<String> siniflar = [];
Interpreter? interpreter;
final FlutterTts tts = FlutterTts();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await modelYukle();
  await tts.setLanguage('tr-TR');
  await tts.setSpeechRate(0.6);
  await tts.setVolume(1.0);
  runApp(const EserTanimaApp());
}

Future<void> modelYukle() async {
  try {
    final jsonStr = await rootBundle.loadString('assets/siniflar.json');
    siniflar = List<String>.from(jsonDecode(jsonStr));
    interpreter = await Interpreter.fromAsset('assets/eser_tanima.tflite');
    print('✓ TFLite model yüklendi: ${siniflar.length} sınıf');
  } catch (e) {
    print('Model yükleme hatası: $e');
  }
}

Map<String, dynamic> tahminYap(String fotoYolu) {
  if (interpreter == null) return {'basarili': false};
  try {
    final bytes = File(fotoYolu).readAsBytesSync();
    final gorsel = img.decodeImage(bytes)!;
    final yeniBoyut = img.copyResize(gorsel, width: 224, height: 224);

    final input = List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final piksel = yeniBoyut.getPixel(x, y);
          return [
            piksel.r.toDouble() / 255.0,
            piksel.g.toDouble() / 255.0,
            piksel.b.toDouble() / 255.0,
          ];
        })
      )
    );

    final output = List.generate(1, (_) => List.filled(116, 0.0));
    interpreter!.run(input, output);

    final skorlar = output[0];
    int enIyiIdx = 0;
    double enIyiSkor = skorlar[0];
    for (int i = 1; i < skorlar.length; i++) {
      if (skorlar[i] > enIyiSkor) {
        enIyiSkor = skorlar[i];
        enIyiIdx = i;
      }
    }

    return {
      'basarili': true,
      'eser': siniflar[enIyiIdx],
      'guven': enIyiSkor,
    };
  } catch (e) {
    print('Tahmin hatası: $e');
    return {'basarili': false};
  }
}

class EserTanimaApp extends StatelessWidget {
  const EserTanimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eser Tanıma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF03DAC6).withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Text('ESER TANIMA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    )),
                const SizedBox(height: 8),
                Container(width: 60, height: 2,
                    color: const Color(0xFF6C63FF)),
                const SizedBox(height: 8),
                const Text('Tarihi eserleri anında keşfet',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                        letterSpacing: 1)),
                const Spacer(),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            KameraEkrani(camera: cameras.first),
                      ),
                    ),
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6C63FF), Color(0xFF3D35CC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 64, color: Colors.white),
                          SizedBox(height: 8),
                          Text('TARA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BilgiKutu(ikon: Icons.museum_outlined, yazi: '116\nEser'),
                      _BilgiKutu(ikon: Icons.psychology_outlined, yazi: 'AI\nDestekli'),
                      _BilgiKutu(ikon: Icons.volume_up_outlined, yazi: 'Sesli\nAnlatım'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BilgiKutu extends StatelessWidget {
  final IconData ikon;
  final String yazi;
  const _BilgiKutu({required this.ikon, required this.yazi});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(ikon, color: const Color(0xFF6C63FF), size: 24),
        const SizedBox(height: 4),
        Text(yazi,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, height: 1.3)),
      ],
    );
  }
}

class KameraEkrani extends StatefulWidget {
  final CameraDescription camera;
  const KameraEkrani({super.key, required this.camera});

  @override
  State<KameraEkrani> createState() => _KameraEkraniState();
}

class _KameraEkraniState extends State<KameraEkrani> {
  late CameraController _controller;
  late Future<void> _initFuture;
  bool _yukleniyor = false;
  int _geriSayim = 5;
  Timer? _geriSayimTimer;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initFuture = _controller.initialize();
    _initFuture.then((_) => _otomatikBaslat());
  }

  void _otomatikBaslat() {
    _geriSayimTimer?.cancel();
    setState(() => _geriSayim = 5);
    _geriSayimTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _geriSayim--);
      if (_geriSayim <= 0) {
        timer.cancel();
        _fotografCekVeTani();
      }
    });
  }

  @override
  void dispose() {
    _geriSayimTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fotografCekVeTani() async {
    _geriSayimTimer?.cancel();
    setState(() {
      _yukleniyor = true;
      _geriSayim = 0;
    });

    try {
      await _initFuture;
      final foto = await _controller.takePicture();
      final bytes = await File(foto.path).readAsBytes();

      // Önce TFLite model ile tahmin yap
      final tahmin = tahminYap(foto.path);
      String eserAdi = '';
      bool modeldenTandi = false;
      bool gorselsiz = false;

      if (tahmin['basarili'] == true) {
        final guven = tahmin['guven'] as double;
        eserAdi = tahmin['eser'] as String;

        if (guven > 0.85) {
          // Yüksek güven → görsel gönderme, sadece eser adını ver
          modeldenTandi = true;
          gorselsiz = true;
          print('✓ Model yüksek güvenle tanıdı: $eserAdi (skor: $guven)');
        } else if (guven > 0.5) {
          // Orta güven → görseli de gönder, ipucu ver
          modeldenTandi = true;
          gorselsiz = false;
          print('~ Model orta güvenle tanıdı: $eserAdi (skor: $guven)');
        }
        // 0.5 altı → model sonucunu yoksay, API görseli analiz etsin
      }

      await _openAIdenBilgiAl(foto.path, bytes, eserAdi, modeldenTandi, gorselsiz: gorselsiz);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      setState(() => _yukleniyor = false);
      _otomatikBaslat();
    }
  }

  Future<void> _openAIdenBilgiAl(
      String fotoYolu, Uint8List bytes, String modelEseri, bool modeldenTandi,
      {bool gorselsiz = false}) async {
    try {
      

      final modelIpucu = modeldenTandi
          ? 'ÖNEMLİ: Özel eğitilmiş görüntü tanıma modelim bu eserin KESİNLİKLE "$modelEseri" olduğunu tespit etti. Bu bilgiyi kullan.'
          : '';

      final prompt = '''${gorselsiz ? 'Türkiye tarihi eseri: $modelEseri' : 'Bu fotoğraftaki Türkiye tarihi eserini tanı.'} $modelIpucu

Eserin türüne göre anlatıcı seç:
- Saray, köşk, kasır → Osmanlı saray görevlisi 👳
- Cami, türbe, külliye → Bilge imam 🕌
- Kale, sur, hisar → Savaşçı asker ⚔️
- Antik kalıntılar, tapınak → Antik çağ filozofu 🏛️
- Kilise, manastır → Yaşlı keşiş ⛪
- Deniz yapıları, kule → Yaşlı denizci ⚓
- Müze, ören yeri → Heyecanlı arkeolog 🏺
- Diğer → Gizemli anlatıcı 🎭

SADECE şu formatta yaz:

ESER: [eserin TAM adı]
KARAKTER: [karakter adı ve emoji]
KARAKTER_TANIM: [karakterin 1 cümlelik tanımı]
SAHNE1: [Karakterin ağzından çarpıcı giriş. 2-3 cümle.]
SAHNE2: [En şaşırtıcı tarihi sır. 2-3 cümle.]
SAHNE3: [İlginç efsane veya hikaye. 2-3 cümle.]
SAHNE4: [Tarihi önemi. 2-3 cümle.]
SAHNE5: [Ziyaretçiye samimi tavsiye. 2-3 cümle.]

Eğer tarihi eser yoksa: BULUNAMADI''';

      // Mesaj içeriğini hazırla
      List<Map<String, dynamic>> messageContent = [];

      if (!gorselsiz) {
        // Görseli base64'e çevir ve ekle
        final base64Image = base64Encode(bytes);
        messageContent = [
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$base64Image',
              'detail': 'low',
            },
          },
          {
            'type': 'text',
            'text': prompt,
          },
        ];
      } else {
        // Sadece metin gönder
        messageContent = [
          {
            'type': 'text',
            'text': prompt,
          },
        ];
      }

      final response = await http.post(
        Uri.parse('https://bitirme-odevi.onrender.com/chat'),
        headers: {
          'Content-Type': 'application/json',
      
        },
        body: jsonEncode({
          'model': gorselsiz ? 'gpt-4o-mini' : 'gpt-4o-mini',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': messageContent,
            }
          ],
        }),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception('API hatası: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final metin = jsonResponse['choices'][0]['message']['content'] as String;

      if (metin.contains('BULUNAMADI')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarihi eser bulunamadı, tekrar deneniyor...'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _yukleniyor = false);
        _otomatikBaslat();
        return;
      }

      final veri = _ayristir(metin);
      if (modeldenTandi) veri['MODEL_TANDI'] = modelEseri;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SonucEkrani(veri: veri, fotoYolu: fotoYolu),
        ),
      ).then((_) {
        if (mounted) _otomatikBaslat();
      });

    } catch (e) {
      if (!mounted) return;
      print('OpenAI hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API hatası: $e')),
      );
      setState(() => _yukleniyor = false);
      _otomatikBaslat();
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Map<String, String> _ayristir(String metin) {
    final Map<String, String> veri = {};
    for (final satir in metin.split('\n')) {
      final idx = satir.indexOf(':');
      if (idx != -1) {
        final anahtar = satir.substring(0, idx).trim();
        final deger = satir.substring(idx + 1).trim();
        if (deger.isNotEmpty) veri[anahtar] = deger;
      }
    }
    return veri;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller)),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text('Kamera',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_yukleniyor)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFF6C63FF)),
                          SizedBox(height: 20),
                          Text('Eser tanınıyor...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Anlatıcı hazırlanıyor...',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                if (!_yukleniyor)
                  Positioned(
                    bottom: 40, left: 0, right: 0,
                    child: Column(
                      children: [
                        if (_geriSayim > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_geriSayim saniye sonra otomatik çekiyor',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                        GestureDetector(
                          onTap: _fotografCekVeTani,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF6C63FF), width: 4),
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                            ),
                            child: const Icon(Icons.camera,
                                color: Colors.white, size: 40),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class SonucEkrani extends StatefulWidget {
  final Map<String, String> veri;
  final String fotoYolu;
  const SonucEkrani({super.key, required this.veri, required this.fotoYolu});

  @override
  State<SonucEkrani> createState() => _SonucEkraniState();
}

class _SonucEkraniState extends State<SonucEkrani>
    with SingleTickerProviderStateMixin {
  int _sahne = 0;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  String _gosterilen = '';
  Timer? _yaziTimer;
  bool _yaziyorMu = true;
  bool _sesAcik = true;

  final List<String> _sahneAnahtarlari = [
    'SAHNE1', 'SAHNE2', 'SAHNE3', 'SAHNE4', 'SAHNE5'
  ];

  final List<Color> _renkler = [
    const Color(0xFF6C63FF),
    const Color(0xFF3D8BCD),
    const Color(0xFF2E7D52),
    const Color(0xFF8B4513),
    const Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _sahneBaslat();
  }

  void _sahneBaslat() {
    _yaziTimer?.cancel();
    _gosterilen = '';
    _yaziyorMu = true;
    final anahtar = _sahneAnahtarlari[_sahne];
    final tamMetin = widget.veri[anahtar] ?? '';

    if (_sesAcik) {
      tts.stop();
      tts.speak(tamMetin);
    }

    int i = 0;
    _yaziTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) return;
      if (i < tamMetin.length) {
        setState(() => _gosterilen += tamMetin[i]);
        i++;
      } else {
        timer.cancel();
        setState(() => _yaziyorMu = false);
      }
    });
  }

  void _sonraki() {
    if (_yaziyorMu) {
      _yaziTimer?.cancel();
      final anahtar = _sahneAnahtarlari[_sahne];
      setState(() {
        _gosterilen = widget.veri[anahtar] ?? '';
        _yaziyorMu = false;
      });
      return;
    }
    tts.stop();
    if (_sahne < _sahneAnahtarlari.length - 1) {
      _animCtrl.reset();
      setState(() {
        _sahne++;
        _gosterilen = '';
      });
      _animCtrl.forward();
      _sahneBaslat();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    tts.stop();
    _yaziTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final karakter = widget.veri['KARAKTER'] ?? '🎭 Anlatıcı';
    final karakterTanim = widget.veri['KARAKTER_TANIM'] ?? '';
    final eserAdi = widget.veri['ESER'] ?? 'Tarihi Eser';
    final modelTandi = widget.veri['MODEL_TANDI'];
    final renk = _renkler[_sahne];
    final sonSahne = _sahne == _sahneAnahtarlari.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.file(File(widget.fotoYolu), fit: BoxFit.cover),
              ),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, const Color(0xFF0A0A0F)],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          tts.stop();
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(eserAdi,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            if (modelTandi != null)
                              const Text('🤖 AI modelim tanıdı',
                                  style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _sesAcik ? Icons.volume_up : Icons.volume_off,
                          color: _sesAcik
                              ? const Color(0xFF6C63FF)
                              : Colors.white38,
                        ),
                        onPressed: () {
                          setState(() => _sesAcik = !_sesAcik);
                          if (!_sesAcik) {
                            tts.stop();
                          } else {
                            final anahtar = _sahneAnahtarlari[_sahne];
                            tts.speak(widget.veri[anahtar] ?? '');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _sahneAnahtarlari.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _sahne ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= _sahne ? renk : Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100, height: 100,
                            child: Lottie.asset(
                              'assets/karakter.json',
                              fit: BoxFit.contain,
                              animate: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: renk,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(karakter,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                const SizedBox(height: 4),
                                Text(karakterTanim,
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border.all(
                                color: renk.withOpacity(0.3)),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_gosterilen,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.7)),
                                if (_yaziyorMu)
                                  Text('▋',
                                      style: TextStyle(
                                          color: renk, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _sonraki,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _yaziyorMu ? Colors.white10 : renk,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: _yaziyorMu ? Colors.white24 : renk),
                ),
                child: Text(
                  _yaziyorMu
                      ? 'Atla →'
                      : sonSahne
                          ? '🔄 Tekrar Çek'
                          : 'Devam Et →',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
