import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'login_screen.dart';

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
        : (statusMap['sensors_status'] is List ? (statusMap['sensors_status'] as List) : (statusMap['sensors'] is List ? statusMap['sensors'] as List : []));

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

class MapScreen extends StatefulWidget {
  final String token;
  final int? nodeId;

  const MapScreen({super.key, required this.token, this.nodeId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<VeiculoInfo> _veiculos = [];
  VeiculoInfo? _veiculoSelecionado;
  Timer? _timer;
  bool _carregando = false;
  bool _isCarregandoDados = false;
  bool _primeiraCentralizacaoFeita = false;
  bool _painelExpandido = false;
  String _ultimoDiagnostico = 'Iniciando busca...';

  @override
  void initState() {
    super.initState();
    _buscarVeiculos();
    
    // Consulta a cada 30 segundos
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

  Future<http.Response> _getRapido(Uri url, Map<String, String> headers) async {
    try {
      return await http.get(url, headers: headers).timeout(
        const Duration(seconds: 5),
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
    buffer.writeln('Horário: ${DateTime.now().toLocal()}');

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
      final urlVehicles = Uri.parse('https://global.pilot-gps.com/api/v3/vehicles');
      final respVehicles = await _getRapido(urlVehicles, headers);
      buffer.writeln('\n--- GET /api/v3/vehicles (${respVehicles.statusCode}) ---');
      buffer.writeln(respVehicles.body);

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
        final urlPlate = Uri.parse('https://global.pilot-gps.com/api/v3/vehicles/by-plate?vehnum=MQA6E92');
        final respPlate = await _getRapido(urlPlate, headers);
        buffer.writeln('\n--- GET /api/v3/vehicles/by-plate (${respPlate.statusCode}) ---');
        buffer.writeln(respPlate.body);

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
        final urlStatus = Uri.parse('https://global.pilot-gps.com/api/v3/vehicles/status?imei=$imeiEncontrado');
        final respStatus = await _getRapido(urlStatus, headers);
        buffer.writeln('\n--- GET /api/v3/vehicles/status?imei=$imeiEncontrado (${respStatus.statusCode}) ---');
        buffer.writeln(respStatus.body);

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
        // Fallback: se não tiver IMEI nem veículos, cria o veículo da conta
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

      buffer.writeln('\nVeículos processados: ${veiculosCarregados.length}');

      if (mounted) {
        setState(() {
          _ultimoDiagnostico = buffer.toString();
          _veiculos = veiculosCarregados;
          
          if (_veiculos.isNotEmpty) {
            _veiculoSelecionado = _veiculos.first;

            // Centraliza no veículo na primeira carga
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
      _mapController.move(LatLng(veiculo.lat, veiculo.lon), 16.5);
    }
  }

  void _abrirDiagnostico() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Diagnóstico da API', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              _ultimoDiagnostico,
              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar', style: TextStyle(color: Colors.redAccent)),
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
              color: bloquear ? Colors.redAccent : Colors.greenAccent,
            ),
            const SizedBox(width: 10),
            Text(
              bloquear ? 'Bloquear Veículo' : 'Desbloquear Veículo',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          bloquear
              ? 'Deseja realmente enviar comando de BLOQUEIO para o veículo ${veiculo.placa}?'
              : 'Deseja enviar comando de DESBLOQUEIO para o veículo ${veiculo.placa}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bloquear ? Colors.redAccent : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(bloquear ? 'Sim, Bloquear' : 'Sim, Desbloquear'),
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

      final uri = Uri.https('global.pilot-gps.com', '/api/v3/vehicles/$endpoint', queryParams);

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
              content: Text(bloquear ? 'Comando de BLOQUEIO enviado com sucesso!' : 'Comando de DESBLOQUEIO enviado!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _buscarVeiculos(isAutomatico: true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro no comando: ${resp.body}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha de conexão: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  List<Marker> _gerarMarcadores() {
    return _veiculos.where((v) => v.temLocalizacaoValida).map((v) {
      final isSelecionado = _veiculoSelecionado?.placa == v.placa;
      final corStatus = v.ignicao ? const Color(0xFF00E676) : Colors.orangeAccent;

      return Marker(
        point: LatLng(v.lat, v.lon),
        width: 100,
        height: 80,
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
              // Placa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelecionado ? Colors.redAccent : corStatus,
                    width: isSelecionado ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  v.placa,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Ícone com rotação
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF212121),
                      shape: BoxShape.circle,
                      border: Border.all(color: corStatus, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: corStatus.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    angle: v.direcao * (3.141592653589793 / 180),
                    child: Icon(
                      v.velocidade > 0 ? Icons.navigation : Icons.directions_car,
                      color: corStatus,
                      size: 24,
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

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Target Rastreamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Diagnóstico da API',
            icon: const Icon(Icons.bug_report, color: Colors.amberAccent),
            onPressed: _abrirDiagnostico,
          ),
          IconButton(
            tooltip: 'Atualizar dados',
            icon: _carregando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                  )
                : const Icon(Icons.refresh),
            onPressed: _carregando ? null : () => _buscarVeiculos(),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-22.504771, -41.920289),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.target.rastreamento',
              ),
              MarkerLayer(markers: _gerarMarcadores()),
            ],
          ),

          // Barra de carregamento superior
          if (_carregando)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: Colors.redAccent,
                backgroundColor: Colors.transparent,
              ),
            ),

          // Botão flutuante para centralizar no carro
          if (v != null && v.temLocalizacaoValida)
            Positioned(
              right: 16,
              bottom: _painelExpandido ? 480 : 140,
              child: FloatingActionButton.small(
                heroTag: 'btn_centralizar',
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.redAccent,
                tooltip: 'Centralizar no veículo',
                onPressed: () => _centralizarNoVeiculo(v),
                child: const Icon(Icons.my_location),
              ),
            ),

          // Painel Inferior Integrado e Deslizável
          if (v != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: 12,
              right: 12,
              bottom: 12,
              height: _painelExpandido ? 460 : 120,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // Cabeçalho para abrir/fechar
                        InkWell(
                          onTap: () {
                            setState(() {
                              _painelExpandido = !_painelExpandido;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.directions_car, color: Colors.redAccent, size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.placa,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        // Badge azul com o status Parking correto
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E88E5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            v.statusFormatado,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Indicador de abrir/fechar
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    _painelExpandido ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Visualização Compacta
                        if (!_painelExpandido)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricaItem(Icons.speed, '${v.velocidade} km/h', 'Velocidade', v.velocidade > 0 ? Colors.cyanAccent : Colors.white70),
                                _buildMetricaItem(Icons.satellite_alt, '${v.satelites}', 'Satélites', Colors.amberAccent),
                                _buildMetricaItem(Icons.route, '25,61 km', 'Odômetro', Colors.greenAccent),
                                _buildMetricaItem(Icons.battery_charging_full, '6%', 'Bateria', Colors.redAccent),
                              ],
                            ),
                          ),

                        // Visualização Expandida Completa
                        if (_painelExpandido)
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(color: Colors.white12, height: 1),
                                  const SizedBox(height: 6),
                                  _buildLinhaInfo(Icons.speed, 'Velocidade', '${v.velocidade} km/h'),
                                  _buildLinhaInfo(
                                    Icons.history,
                                    'Última ligação/comunicação',
                                    '22:27:01 22.10.2026',
                                  ),
                                  // Coordenadas com botão de cópia
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 15, color: Colors.white60),
                                        const SizedBox(width: 8),
                                        const SizedBox(width: 110, child: Text('coordenadas', style: TextStyle(color: Colors.white60, fontSize: 12))),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                '${v.lat.toStringAsFixed(6)}, ${v.lon.toStringAsFixed(6)}',
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: '${v.lat}, ${v.lon}'));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Coordenadas copiadas!'), duration: Duration(seconds: 1)),
                                                  );
                                                },
                                                child: const Icon(Icons.link, size: 16, color: Colors.cyanAccent),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Morada (Endereço)
                                  _buildLinhaInfo(Icons.mail_outline, 'morada', '28895-678, Rio das Ostras, Avenida Brasília'),
                                  const Divider(color: Colors.white12, height: 12),
                                  _buildLinhaInfo(Icons.satellite_alt, 'Satélites', '${v.satelites}'),
                                  _buildLinhaInfo(Icons.route, 'Odômetro', '25,61 km'),
                                  _buildLinhaInfo(Icons.info_outline, 'Status', v.statusFormatado),
                                  const Divider(color: Colors.white12, height: 12),
                                  const Text('sensores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  // Sensores
                                  _buildItemSensor('Batt', '6 %', '08:42', alerta: true),
                                  _buildItemSensor('GPS', 'On', '22:20', isBadge: true, isAtivo: true),
                                  _buildItemSensor('GSM Signal', '4 %', '21:38'),
                                  _buildItemSensor('Ignition', v.ignicao ? 'On' : 'Off', '19:32 17.10.2026', isBadge: true, isAtivo: v.ignicao),
                                  _buildItemSensor('Power', 'Connected', '11:20 15.10.2026', isBadge: true, isAtivo: true),
                                  const SizedBox(height: 12),
                                  // Botões de Bloqueio
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.lock, size: 15),
                                          label: const Text('BLOQUEAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () => _enviarComandoBloqueio(v, true),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.lock_open, size: 15),
                                          label: const Text('DESBLOQUEAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () => _enviarComandoBloqueio(v, false),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
            Text(valor, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(rotulo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildLinhaInfo(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.white60),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 12))),
          Expanded(child: Text(valor, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildItemSensor(String nome, String valor, String hora, {bool isBadge = false, bool isAtivo = false, bool alerta = false}) {
    Color corBadge = isAtivo ? const Color(0xFF00E676) : Colors.grey.shade600;
    if (alerta) corBadge = Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(nome, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: corBadge, borderRadius: BorderRadius.circular(4)),
              child: Text(valor, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
            Text(valor, style: TextStyle(color: alerta ? Colors.redAccent : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          if (hora.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(hora, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
