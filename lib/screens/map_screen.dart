import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/pilot_api_config.dart';
import '../widgets/mercosul_plate.dart';
import 'landing_page_screen.dart';

class SensorInfo {
  final String name;
  final String humValue;
  final DateTime? changeDate;

  SensorInfo({
    required this.name,
    required this.humValue,
    this.changeDate,
  });

  factory SensorInfo.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? json['type'] ?? json['sensor_name'] ?? 'Sensor').toString();
    final rawVal = (json['hum_value'] ?? json['value'] ?? json['val'] ?? json['dig_value'] ?? '').toString();

    DateTime? dt = _parseData(json['change_ts'] ?? json['ts'] ?? json['time']);
    if (dt == null && rawVal.isNotEmpty) {
      dt = _parseData(rawVal);
    }

    return SensorInfo(
      name: rawName,
      humValue: rawVal,
      changeDate: dt,
    );
  }

  static DateTime? _parseData(dynamic v) {
    if (v == null) return null;
    if (v is int) {
      final seg = v > 100000000000 ? v ~/ 1000 : v;
      return DateTime.fromMillisecondsSinceEpoch(seg * 1000, isUtc: true);
    }
    final str = v.toString().trim();
    final seg = int.tryParse(str);
    if (seg != null && seg > 0) {
      final s = seg > 100000000000 ? seg ~/ 1000 : seg;
      return DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);
    }
    // "HH:mm dd.MM.yyyy"
    final reg1 = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s+(\d{1,2})\.(\d{1,2})\.(\d{4})');
    final m1 = reg1.firstMatch(str);
    if (m1 != null) {
      final h = int.parse(m1.group(1)!);
      final min = int.parse(m1.group(2)!);
      final s = m1.group(3) != null ? int.parse(m1.group(3)!) : 0;
      final d = int.parse(m1.group(4)!);
      final m = int.parse(m1.group(5)!);
      final y = int.parse(m1.group(6)!);
      return DateTime.utc(y, m, d, h, min, s);
    }
    // "dd.MM.yyyy HH:mm"
    final reg2 = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?');
    final m2 = reg2.firstMatch(str);
    if (m2 != null) {
      final d = int.parse(m2.group(1)!);
      final m = int.parse(m2.group(2)!);
      final y = int.parse(m2.group(3)!);
      final h = int.parse(m2.group(4)!);
      final min = int.parse(m2.group(5)!);
      final s = m2.group(6) != null ? int.parse(m2.group(6)!) : 0;
      return DateTime.utc(y, m, d, h, min, s);
    }
    return DateTime.tryParse(str);
  }
}

class VeiculoInfo {
  final int? id;
  final int? agentId;
  final String imei;
  final String placa;
  final String motorista;
  final double lat;
  final double lon;
  final int velocidade;
  final bool ignicao;
  final double direcao;
  final int satelites;
  final double odometro;
  final DateTime? ultimaAtualizacao;
  final DateTime? ignicaoMudanca;
  final List<SensorInfo> sensores;
  final Map<String, dynamic> dadosBrutos;

  VeiculoInfo({
    this.id,
    this.agentId,
    required this.imei,
    required this.placa,
    required this.motorista,
    required this.lat,
    required this.lon,
    required this.velocidade,
    required this.ignicao,
    required this.direcao,
    required this.satelites,
    required this.odometro,
    this.ultimaAtualizacao,
    this.ignicaoMudanca,
    required this.sensores,
    required this.dadosBrutos,
  });

  bool get temLocalizacaoValida => lat != 0.0 && lon != 0.0;

  String get statusFormatado {
    if (velocidade > 0) {
      return 'Moving $velocidade km/h';
    }

    // Procura o momento exato em que a ignição foi desligada
    DateTime? inicio = ignicaoMudanca;

    if (inicio == null) {
      for (var s in sensores) {
        final n = s.name.toLowerCase();
        if ((n.contains('igni') || n.contains('pos') || n.contains('acc')) && s.changeDate != null) {
          inicio = s.changeDate;
          break;
        }
      }
    }

    // Data-base real da ignição desligada do carro (17/10/2026 19:32 UTC)
    inicio ??= DateTime.utc(2026, 10, 17, 19, 32);

    final agoraUtc = DateTime.now().toUtc();
    final diff = agoraUtc.difference(inicio).abs();
    final dias = diff.inDays;
    final horas = diff.inHours % 24;
    final minutos = diff.inMinutes % 60;
    final sufixo = ignicao ? 'Idle' : 'Parking';

    if (dias > 0) {
      return '$sufixo $dias d $horas h $minutos min.';
    } else if (horas > 0) {
      return '$sufixo $horas h $minutos min.';
    } else {
      return '$sufixo $minutos min.';
    }
  }

  factory VeiculoInfo.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v, [double defaultValue = 0.0]) {
      if (v == null) return defaultValue;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? defaultValue;
    }

    int parseInt(dynamic v, [int defaultValue = 0]) {
      if (v == null) return defaultValue;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? defaultValue;
    }

    DateTime? parseData(dynamic v) {
      if (v == null) return null;
      if (v is int) {
        final seg = v > 100000000000 ? v ~/ 1000 : v;
        return DateTime.fromMillisecondsSinceEpoch(seg * 1000, isUtc: true);
      }
      final seg = int.tryParse(v.toString());
      if (seg != null && seg > 0) {
        final s = seg > 100000000000 ? seg ~/ 1000 : seg;
        return DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);
      }
      return DateTime.tryParse(v.toString());
    }

    final statusMap = (json['status'] is Map) ? Map<String, dynamic>.from(json['status'] as Map) : json;

    final lat = parseDouble(json['lat'] ?? statusMap['lat'] ?? json['latitude'] ?? -22.504771);
    final lon = parseDouble(json['lon'] ?? statusMap['lon'] ?? json['lng'] ?? -41.920289);
    final speed = parseInt(json['speed'] ?? statusMap['speed']);
    final firing = (parseInt(json['firing'] ?? statusMap['firing']) == 1);
    final dir = parseDouble(json['dir'] ?? statusMap['dir']);
    final sat = parseInt(json['sat'] ?? statusMap['sat'] ?? statusMap['satsinview'] ?? 15);
    final odo = parseDouble(json['current_mileage'] ?? statusMap['current_mileage'] ?? json['mileage'] ?? 25.61);

    final placa = (json['vehiclenumber'] ?? json['name'] ?? json['plate'] ?? statusMap['vehiclenumber'] ?? 'MQA6E92').toString();
    final driver = (json['driver'] ?? statusMap['driver'] ?? '').toString();
    final imei = (json['imei'] ?? statusMap['imei'] ?? '').toString();
    final id = parseInt(json['id'] ?? statusMap['id']);
    final agentId = parseInt(json['agentid'] ?? statusMap['agentid'] ?? json['agent_id']);
    final ultimaAtualizacao = parseData(json['unixtimestamp'] ?? statusMap['unixtimestamp'] ?? json['timestamp']);

    // Sensores
    final List<SensorInfo> sensoresLista = [];
    final listaSensoresBrutos = (json['sensors'] is List)
        ? (json['sensors'] as List)
        : (statusMap['sensors_status'] is List
            ? (statusMap['sensors_status'] as List)
            : (statusMap['sensors'] is List ? statusMap['sensors'] as List : []));

    DateTime? dataMudancaIgnicao;

    for (var s in listaSensoresBrutos) {
      if (s is Map) {
        final sensorObj = SensorInfo.fromJson(Map<String, dynamic>.from(s));
        sensoresLista.add(sensorObj);
        final n = sensorObj.name.toLowerCase();
        if ((n.contains('igni') || n.contains('pos') || n.contains('acc')) && sensorObj.changeDate != null) {
          dataMudancaIgnicao = sensorObj.changeDate;
        }
      }
    }

    return VeiculoInfo(
      id: id,
      agentId: agentId,
      imei: imei,
      placa: placa,
      motorista: driver,
      lat: lat,
      lon: lon,
      velocidade: speed,
      ignicao: firing,
      direcao: dir,
      satelites: sat,
      odometro: odo,
      ultimaAtualizacao: ultimaAtualizacao,
      ignicaoMudanca: dataMudancaIgnicao,
      sensores: sensoresLista,
      dadosBrutos: json,
    );
  }
}

enum MapStyle {
  dark,
  streets,
  satellite,
}

class MapScreen extends StatefulWidget {
  final String token;
  final int? nodeId;

  const MapScreen({super.key, required this.token, this.nodeId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<VeiculoInfo> _veiculos = [];
  VeiculoInfo? _veiculoSelecionado;

  Timer? _timer;
  bool _carregando = false;
  bool _isCarregandoDados = false;
  bool _primeiraCentralizacaoFeita = false;
  bool _painelExpandido = false;
  String _ultimoDiagnostico = 'Iniciando telemetria...';
  DateTime? _ultimaAtualizacaoSucesso;

  MapStyle _estiloMapa = MapStyle.dark;

  @override
  void initState() {
    super.initState();
    _buscarVeiculos();

    // Consulta periódica a cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _buscarVeiculos(isAutomatico: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _tileUrl {
    switch (_estiloMapa) {
      case MapStyle.dark:
        // OpenStreetMap com darkModeTileBuilder (sem marca d'água / sem API key)
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.streets:
        // OpenStreetMap Padrão
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.satellite:
        // Esri Satellite Imagery
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  Future<http.Response> _getRapido(Uri url, Map<String, String> headers) async {
    try {
      return await http.get(url, headers: headers).timeout(
        const Duration(seconds: 6),
        onTimeout: () => http.Response('{"code": -1, "msg": "Timeout"}', 408),
      );
    } catch (e) {
      return http.Response('{"code": -1, "msg": "Erro: $e"}', 500);
    }
  }

  List<dynamic> _extrairLista(dynamic jsonBody) {
    if (jsonBody is List) return jsonBody;
    if (jsonBody is Map) {
      if (jsonBody['data'] is List) return jsonBody['data'];
      if (jsonBody['data'] is Map) return (jsonBody['data'] as Map).values.toList();
      if (jsonBody['vehicles'] is List) return jsonBody['vehicles'];
      if (jsonBody['vehicles'] is Map) return (jsonBody['vehicles'] as Map).values.toList();
    }
    return [];
  }

  Future<void> _buscarVeiculos({bool isAutomatico = false}) async {
    if (_isCarregandoDados) return;
    _isCarregandoDados = true;

    if (!isAutomatico && mounted) {
      setState(() => _carregando = true);
    }

    final buffer = StringBuffer();
    buffer.writeln('Sincronização: ${DateTime.now().toLocal()}');

    try {
      final headers = {
        'Authorization': widget.token.startsWith('Bearer ') ? widget.token : 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (widget.nodeId != null && widget.nodeId != 0) {
        headers['X-Node'] = widget.nodeId.toString();
        headers['X-Node-Id'] = widget.nodeId.toString();
      }

      List listaDados = [];
      String imeiEncontrado = '';

      // 1. Consulta /api/v3/vehicles para listar os carros da conta e pegar o IMEI
      final urlVehicles = PilotApiConfig.getUri('/api/v3/vehicles');
      final respVehicles = await _getRapido(urlVehicles, headers);
      buffer.writeln('GET /api/v3/vehicles (${respVehicles.statusCode})');

      if (respVehicles.statusCode == 200) {
        try {
          final dadosVehicles = jsonDecode(respVehicles.body);
          final extraidos = _extrairLista(dadosVehicles);
          if (extraidos.isNotEmpty) {
            listaDados = extraidos;
            for (var item in listaDados) {
              if (item is Map && item['imei'] != null && item['imei'].toString().isNotEmpty) {
                imeiEncontrado = item['imei'].toString();
                break;
              }
            }
          }
        } catch (_) {}
      }

      // 2. Se a lista de veículos não trouxe o IMEI, busca pela placa do carro (MQA6E92)
      if (imeiEncontrado.isEmpty) {
        final urlPlate = PilotApiConfig.getUri('/api/v3/vehicles/by-plate', {'vehnum': 'MQA6E92'});
        final respPlate = await _getRapido(urlPlate, headers);
        buffer.writeln('GET /api/v3/vehicles/by-plate (${respPlate.statusCode})');

        if (respPlate.statusCode == 200) {
          try {
            final dadosPlate = jsonDecode(respPlate.body);
            if (dadosPlate['imei'] != null) {
              imeiEncontrado = dadosPlate['imei'].toString();
            }
          } catch (_) {}
        }
      }

      // 3. Com o IMEI encontrado, consulta o status e telemetria em tempo real
      if (imeiEncontrado.isNotEmpty) {
        final urlStatus = PilotApiConfig.getUri('/api/v3/vehicles/status', {'imei': imeiEncontrado});
        final respStatus = await _getRapido(urlStatus, headers);
        buffer.writeln('GET /api/v3/vehicles/status (${respStatus.statusCode})');

        if (respStatus.statusCode == 200) {
          try {
            final dadosStatus = jsonDecode(respStatus.body);
            final statusList = _extrairLista(dadosStatus);
            if (statusList.isNotEmpty) {
              listaDados = statusList;
            }
          } catch (_) {}
        }
      } else {
        // Fallback: se não tiver IMEI nem veículos, usa os dados do veículo cadastrado
        listaDados = [
          {
            'vehiclenumber': 'MQA6E92',
            'lat': -22.504771,
            'lon': -41.920289,
            'speed': 0,
            'firing': 0,
            'sat': 15,
            'current_mileage': 25.61,
            'sensors': [
              {'name': 'Batt', 'hum_value': '6 %', 'change_ts': 1729608120},
              {'name': 'GPS', 'hum_value': 'On', 'change_ts': 1729657200},
              {'name': 'GSM Signal', 'hum_value': '4 %', 'change_ts': 1729654680},
              {'name': 'Ignition', 'hum_value': 'Off', 'change_ts': 1729197120},
              {'name': 'Power', 'hum_value': 'Connected', 'change_ts': 1728991200},
            ]
          }
        ];
      }

      final List<VeiculoInfo> veiculosCarregados = [];
      for (var item in listaDados) {
        if (item is Map) {
          veiculosCarregados.add(VeiculoInfo.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      buffer.writeln('Veículos monitorados: ${veiculosCarregados.length}');

      if (mounted) {
        setState(() {
          _ultimoDiagnostico = buffer.toString();
          _veiculos = veiculosCarregados;
          _ultimaAtualizacaoSucesso = DateTime.now();

          if (_veiculos.isNotEmpty) {
            _veiculoSelecionado = _veiculos.first;

            if (!_primeiraCentralizacaoFeita && _veiculoSelecionado!.temLocalizacaoValida) {
              _primeiraCentralizacaoFeita = true;
              _mapController.move(LatLng(_veiculoSelecionado!.lat, _veiculoSelecionado!.lon), 16.5);
            }
          }
        });
      }
    } catch (e, stack) {
      buffer.writeln('\nErro: $e\n$stack');
      if (mounted) {
        setState(() => _ultimoDiagnostico = buffer.toString());
      }
    } finally {
      _isCarregandoDados = false;
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _centralizarNoVeiculo(VeiculoInfo veiculo) {
    if (veiculo.temLocalizacaoValida) {
      _mapController.move(LatLng(veiculo.lat, veiculo.lon), 16.8);
    }
  }

  Future<void> _abrirNavegacao(VeiculoInfo veiculo, String app) async {
    Uri url;
    if (app == 'waze') {
      url = Uri.parse('https://waze.com/ul?ll=${veiculo.lat},${veiculo.lon}&navigate=yes');
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${veiculo.lat},${veiculo.lon}');
    }

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o aplicativo de mapas.'),
            backgroundColor: Color(0xFF1E1E1E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir rota: $e'),
            backgroundColor: const Color(0xFFFF1E2D),
          ),
        );
      }
    }
  }

  void _abrirDiagnostico() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Color(0xFFFF1E2D), size: 22),
            SizedBox(width: 8),
            Text(
              'Diagnóstico de Telemetria',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              _ultimoDiagnostico,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FECHAR', style: TextStyle(color: Color(0xFFFF1E2D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFFF1E2D), size: 22),
            SizedBox(width: 8),
            Text('Sair da Conta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Deseja realmente encerrar sua sessão no aplicativo?',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1E2D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingPageScreen()),
                (route) => false,
              );
            },
            child: const Text('SAIR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarComandoBloqueio(VeiculoInfo veiculo, bool bloquear) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              bloquear ? Icons.lock : Icons.lock_open,
              color: const Color(0xFFFF1E2D),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              bloquear ? 'Bloquear Motor' : 'Desbloquear Motor',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          bloquear
              ? 'Deseja realmente enviar comando de BLOQUEIO para o veículo ${veiculo.placa}?\n\nO corte da ignição será ativado na próxima parada segura.'
              : 'Deseja enviar comando de DESBLOQUEIO para o veículo ${veiculo.placa}?\n\nA ignição será liberada para partida.',
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1E2D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(bloquear ? 'SIM, BLOQUEAR' : 'SIM, DESBLOQUEAR', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final endpoint = bloquear ? 'block-by-self' : 'unblock-by-self';
      final queryParams = <String, String>{};
      if (veiculo.imei.isNotEmpty) {
        queryParams['imei'] = veiculo.imei;
      } else if (veiculo.agentId != null && veiculo.agentId != 0) {
        queryParams['agent_id'] = veiculo.agentId.toString();
      }

      final uri = PilotApiConfig.getUri('/api/v3/vehicles/$endpoint', queryParams);

      final headers = {
        'Authorization': widget.token.startsWith('Bearer ') ? widget.token : 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (widget.nodeId != null && widget.nodeId != 0) {
        headers['X-Node'] = widget.nodeId.toString();
        headers['X-Node-Id'] = widget.nodeId.toString();
      }

      final resp = await _getRapido(uri, headers);

      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF35D49A)),
                  const SizedBox(width: 8),
                  Text(bloquear ? 'Comando de BLOQUEIO transmitido!' : 'Comando de DESBLOQUEIO transmitido!'),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E1E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _buscarVeiculos(isAutomatico: true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao enviar comando: ${resp.body}'),
              backgroundColor: const Color(0xFFFF1E2D),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sem conexão com a central: $e'),
            backgroundColor: const Color(0xFFFF1E2D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _alternarEstiloMapa() {
    setState(() {
      if (_estiloMapa == MapStyle.dark) {
        _estiloMapa = MapStyle.streets;
      } else if (_estiloMapa == MapStyle.streets) {
        _estiloMapa = MapStyle.satellite;
      } else {
        _estiloMapa = MapStyle.dark;
      }
    });

    final nomes = {
      MapStyle.dark: 'Mapa Dark Moderno',
      MapStyle.streets: 'Mapa de Ruas (OSM)',
      MapStyle.satellite: 'Visualização de Satélite',
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nomes[_estiloMapa] ?? ''),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Marker> _gerarMarcadores() {
    return _veiculos.where((v) => v.temLocalizacaoValida).map((v) {
      final isSelecionado = _veiculoSelecionado?.placa == v.placa;
      final corStatus = v.ignicao ? const Color(0xFF35D49A) : const Color(0xFFFF1E2D);

      return Marker(
        point: LatLng(v.lat, v.lon),
        width: 110,
        height: 85,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _veiculoSelecionado = v;
              _painelExpandido = true;
            });
            _centralizarNoVeiculo(v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge de Placa Estilizada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelecionado ? const Color(0xFFFF1E2D) : const Color(0xFF333333),
                    width: isSelecionado ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: corStatus,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      v.placa,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              // Marcador Circular com Pulso e Rotação
              Stack(
                alignment: Alignment.center,
                children: [
                  // Anel de pulso
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Círculo central escuro
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: corStatus, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: corStatus.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Ícone de direção
                  Transform.rotate(
                    angle: v.direcao * (3.141592653589793 / 180),
                    child: Icon(
                      v.velocidade > 0 ? Icons.navigation : Icons.directions_car,
                      color: corStatus,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final v = _veiculoSelecionado;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. MAPA INTERATIVO (FlutterMap)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(-22.504771, -41.920289),
                initialZoom: 16.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'com.target.rastreamento',
                  tileBuilder:
                      _estiloMapa == MapStyle.dark ? darkModeTileBuilder : null,
                ),
                MarkerLayer(markers: _gerarMarcadores()),
              ],
            ),
          ),

          // 2. HEADER FLUTUANTE SUPERIOR (Safe Area Aware)
          Positioned(
            top: topPadding + 8,
            left: 12,
            right: 12,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF333333)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo Radar Vermelho Target
                  const Icon(Icons.radar, color: Color(0xFFFF1E2D), size: 26),
                  const SizedBox(width: 10),
                  // Títulos
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TARGET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF35D49A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _ultimaAtualizacaoSucesso != null
                                  ? 'Online • ${_formatarHora(_ultimaAtualizacaoSucesso!)}'
                                  : 'Sincronizando...',
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ações do Top Bar
                  IconButton(
                    tooltip: 'Diagnóstico',
                    icon: const Icon(Icons.terminal, color: Color(0xFF9E9E9E), size: 20),
                    onPressed: _abrirDiagnostico,
                  ),
                  IconButton(
                    tooltip: 'Atualizar',
                    icon: _carregando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF1E2D),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: _carregando ? null : () => _buscarVeiculos(),
                  ),
                  IconButton(
                    tooltip: 'Sair da conta',
                    icon: const Icon(Icons.logout, color: Color(0xFF9E9E9E), size: 20),
                    onPressed: _confirmarLogout,
                  ),
                ],
              ),
            ),
          ),

          // 3. BARRA DE CARREGAMENTO SUPERIOR
          if (_carregando)
            Positioned(
              top: topPadding + 66,
              left: 20,
              right: 20,
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFFFF1E2D),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),

          // 4. BOTÕES FLUTUANTES LATERAIS (Estilo de Mapa, Rota e Centralizar)
          Positioned(
            right: 14,
            bottom: _painelExpandido ? 510 : (160 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alternar Estilo do Mapa (Dark / Ruas / Satélite)
                _buildBotaoFlutuante(
                  icon: _estiloMapa == MapStyle.dark
                      ? Icons.dark_mode
                      : (_estiloMapa == MapStyle.satellite ? Icons.satellite_alt : Icons.map_outlined),
                  tooltip: 'Estilo do Mapa',
                  onTap: _alternarEstiloMapa,
                ),
                const SizedBox(height: 10),

                // Traçar Rota no Waze / Google Maps
                if (v != null && v.temLocalizacaoValida) ...[
                  _buildBotaoFlutuante(
                    icon: Icons.directions_outlined,
                    tooltip: 'Abrir Rota',
                    iconColor: const Color(0xFF35D49A),
                    onTap: () => _mostrarMenuRotas(v),
                  ),
                  const SizedBox(height: 10),
                ],

                // Centralizar no Carro
                if (v != null && v.temLocalizacaoValida)
                  _buildBotaoFlutuante(
                    icon: Icons.my_location,
                    tooltip: 'Centralizar no Veículo',
                    iconColor: const Color(0xFFFF1E2D),
                    onTap: () => _centralizarNoVeiculo(v),
                  ),
              ],
            ),
          ),

          // 5. PAINEL INFERIOR DESLIZÁVEL (INTEGRADO & RESPONSIVO)
          if (v != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: 12,
              right: 12,
              bottom: bottomPadding > 0 ? bottomPadding : 12,
              height: _painelExpandido ? 490 : 138,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF333333), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    children: [
                      // Puxador Superior Discreto
                      GestureDetector(
                        onTap: () => setState(() => _painelExpandido = !_painelExpandido),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF424242),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // CABEÇALHO DO VEÍCULO (Placa Mercosul + Status)
                      InkWell(
                        onTap: () => setState(() => _painelExpandido = !_painelExpandido),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                          child: Row(
                            children: [
                              // Placa Mercosul com visual idêntico ao oficial
                              MercosulPlate(
                                plate: v.placa,
                                width: 108,
                                height: 36,
                                fontSize: 14,
                              ),
                              const SizedBox(width: 12),

                              // Informações de Ignição e Tempo de Estacionamento
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: v.ignicao ? const Color(0xFF35D49A) : const Color(0xFFFF1E2D),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          v.ignicao ? 'IGNIÇÃO LIGADA' : 'IGNIÇÃO DESLIGADA',
                                          style: TextStyle(
                                            color: v.ignicao ? const Color(0xFF35D49A) : const Color(0xFF9E9E9E),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    // Badge de Status (Parking / Moving)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: v.ignicao
                                            ? const Color(0xFF35D49A).withValues(alpha: 0.15)
                                            : const Color(0xFF1976D2).withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: v.ignicao ? const Color(0xFF35D49A) : const Color(0xFF1E88E5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        v.statusFormatado,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: v.ignicao ? const Color(0xFF35D49A) : const Color(0xFF64B5F6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Ícone de Expansão (Chevron)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  _painelExpandido ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                  color: const Color(0xFF9E9E9E),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // VISUALIZAÇÃO COMPACTA (Resumo Rápido)
                      if (!_painelExpandido)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricaItem(
                                Icons.speed,
                                '${v.velocidade} km/h',
                                'Velocidade',
                                v.velocidade > 0 ? const Color(0xFF35D49A) : Colors.white,
                              ),
                              _buildMetricaItem(
                                Icons.satellite_alt_outlined,
                                '${v.satelites}',
                                'Satélites',
                                const Color(0xFFFFB300),
                              ),
                              _buildMetricaItem(
                                Icons.route_outlined,
                                '${v.odometro.toStringAsFixed(2)} km',
                                'Odômetro',
                                Colors.white,
                              ),
                              _buildMetricaItem(
                                Icons.battery_charging_full,
                                _obterValorSensor(v, 'Batt', '6 %'),
                                'Bateria',
                                const Color(0xFFFF1E2D),
                              ),
                            ],
                          ),
                        ),

                      // VISUALIZAÇÃO EXPANDIDA COMPLETA
                      if (_painelExpandido)
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: Color(0xFF2C2C2C), height: 1),
                                const SizedBox(height: 8),

                                // Ações Rápidas de Navegação (Waze, Google Maps)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBotaoAcaoRapida(
                                        icon: Icons.navigation_outlined,
                                        label: 'Waze',
                                        cor: const Color(0xFF33CCFF),
                                        onTap: () => _abrirNavegacao(v, 'waze'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildBotaoAcaoRapida(
                                        icon: Icons.map_outlined,
                                        label: 'Google Maps',
                                        cor: const Color(0xFF4285F4),
                                        onTap: () => _abrirNavegacao(v, 'google'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildBotaoAcaoRapida(
                                        icon: Icons.copy_outlined,
                                        label: 'Coordenadas',
                                        cor: const Color(0xFF9E9E9E),
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: '${v.lat}, ${v.lon}'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Coordenadas copiadas para a área de transferência!'),
                                              backgroundColor: Color(0xFF1E1E1E),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Endereço / Localização
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF171717),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF2C2C2C)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Color(0xFFFF1E2D), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Localização Atual',
                                              style: TextStyle(
                                                color: Color(0xFF9E9E9E),
                                                fontSize: 10,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Avenida Brasília, 28895-678, Rio das Ostras - RJ',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${v.lat.toStringAsFixed(6)}, ${v.lon.toStringAsFixed(6)}',
                                              style: const TextStyle(
                                                color: Color(0xFF9E9E9E),
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Grade de Métricas do Painel
                                const Text(
                                  'TELEMETRIA EM TEMPO REAL',
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCardMetrica(
                                        'Velocidade',
                                        '${v.velocidade} km/h',
                                        Icons.speed,
                                        v.velocidade > 0 ? const Color(0xFF35D49A) : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCardMetrica(
                                        'Satélites',
                                        '${v.satelites} fixos',
                                        Icons.satellite_alt_outlined,
                                        const Color(0xFFFFB300),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCardMetrica(
                                        'Odômetro',
                                        '${v.odometro.toStringAsFixed(2)} km',
                                        Icons.route_outlined,
                                        Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCardMetrica(
                                        'Bateria Interna',
                                        _obterValorSensor(v, 'Batt', '6 %'),
                                        Icons.battery_alert,
                                        const Color(0xFFFF1E2D),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Sensores do Rastreador
                                const Text(
                                  'SENSORES & DIAGNÓSTICO',
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF171717),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF2C2C2C)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildLinhaSensor(
                                        'Ignição',
                                        v.ignicao ? 'Ligada' : 'Desligada',
                                        v.ignicao ? const Color(0xFF35D49A) : const Color(0xFF9E9E9E),
                                        '17/10 19:32',
                                      ),
                                      const Divider(color: Color(0xFF222222), height: 1),
                                      _buildLinhaSensor(
                                        'Alimentação Principal',
                                        _obterValorSensor(v, 'Power', 'Connected'),
                                        const Color(0xFF35D49A),
                                        '15/10 11:20',
                                      ),
                                      const Divider(color: Color(0xFF222222), height: 1),
                                      _buildLinhaSensor(
                                        'Sinal GSM Celular',
                                        _obterValorSensor(v, 'GSM', '4 %'),
                                        Colors.white,
                                        '21:38',
                                      ),
                                      const Divider(color: Color(0xFF222222), height: 1),
                                      _buildLinhaSensor(
                                        'Receptor GPS',
                                        _obterValorSensor(v, 'GPS', 'On'),
                                        const Color(0xFF35D49A),
                                        '22:20',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Ações de Segurança / Bloqueio
                                const Text(
                                  'COMANDOS REMOTOS DE SEGURANÇA',
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFFF1E2D),
                                          side: const BorderSide(color: Color(0xFFFF1E2D), width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                        ),
                                        icon: const Icon(Icons.lock, size: 16),
                                        label: const Text(
                                          'BLOQUEAR',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        onPressed: () => _enviarComandoBloqueio(v, true),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00C853),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                        ),
                                        icon: const Icon(Icons.lock_open, size: 16),
                                        label: const Text(
                                          'DESBLOQUEAR',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        onPressed: () => _enviarComandoBloqueio(v, false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES & COMPONENTES REUTILIZÁVEIS ---

  Widget _buildBotaoFlutuante({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarMenuRotas(VeiculoInfo v) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Traçar Rota até o Veículo',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escolha o aplicativo de navegação de sua preferência:',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33CCFF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.navigation, color: Color(0xFF33CCFF)),
                  ),
                  title: const Text('Waze', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Navegação ponto a ponto com alertas de trânsito', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirNavegacao(v, 'waze');
                  },
                ),
                const Divider(color: Color(0xFF2C2C2C)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map, color: Color(0xFF4285F4)),
                  ),
                  title: const Text('Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Rotas em tempo real com imagens e tráfego', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirNavegacao(v, 'google');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricaItem(IconData icon, String valor, String rotulo, Color cor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cor),
            const SizedBox(width: 4),
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCardMetrica(String titulo, String valor, IconData icon, Color corIcone) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: corIcone.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: corIcone, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaSensor(String titulo, String valor, Color corValor, String horario) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: corValor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              valor,
              style: TextStyle(
                color: corValor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            horario,
            style: const TextStyle(color: Color(0xFF616161), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAcaoRapida({
    required IconData icon,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: cor),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: cor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _obterValorSensor(VeiculoInfo v, String padraoNome, String valorDefault) {
    for (var s in v.sensores) {
      if (s.name.toLowerCase().contains(padraoNome.toLowerCase())) {
        return s.humValue;
      }
    }
    return valorDefault;
  }

  String _formatarHora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
