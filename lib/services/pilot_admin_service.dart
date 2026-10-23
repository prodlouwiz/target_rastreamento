import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dados necessários para o cadastro de um novo cliente e veículo.
class ClientRegistrationData {
  final String name;
  final String cpfCnpj;
  final String email;
  final String phone;
  final String password;
  final String plate;
  final String imei;
  final String? simCard;
  final String? vehicleModel;

  ClientRegistrationData({
    required this.name,
    required this.cpfCnpj,
    required this.email,
    required this.phone,
    required this.password,
    required this.plate,
    required this.imei,
    this.simCard,
    this.vehicleModel,
  });

  /// Determina se é Pessoa Jurídica (1) ou Pessoa Física (2) baseado na quantidade de dígitos do documento.
  int get orgType => cpfCnpj.replaceAll(RegExp(r'\D'), '').length > 11 ? 1 : 2;

  String get cleanCpfCnpj => cpfCnpj.replaceAll(RegExp(r'\D'), '');
  String get cleanPhone => phone.replaceAll(RegExp(r'\D'), '');
  String get cleanPlate => plate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  String get cleanImei => imei.replaceAll(RegExp(r'\D'), '');
}

/// Resposta do processo completo de cadastro.
class RegistrationResult {
  final bool success;
  final String message;
  final String? accountId;
  final int? userId;
  final String? agentId;
  final String? vehId;
  final String? login;
  final String? password;

  RegistrationResult({
    required this.success,
    required this.message,
    this.accountId,
    this.userId,
    this.agentId,
    this.vehId,
    this.login,
    this.password,
  });
}

/// Serviço de integração com as APIs de Administração do PILOT GPS.
/// Gerencia os comandos:
/// 1. `accountadd` (/ax/api.php)
/// 2. `create_user` (/backend/api.php)
/// 3. `vehadd` (/backend/api.php)
class PilotAdminService {
  String serverAddress;
  int node;
  int billPrice;
  int defaultVehModel;

  PilotAdminService({
    this.serverAddress = 'global.pilot-gps.com',
    this.node = 1,
    this.billPrice = 143,
    this.defaultVehModel = 13,
  });

  /// 1. Cria a Conta / Contrato (cmd=accountadd)
  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String cpfCnpj,
    required String email,
    required String phone,
    required int orgType,
  }) async {
    final queryParams = {
      'cmd': 'accountadd',
      'bill_price': billPrice.toString(),
      'inn': cpfCnpj,
      'node': node.toString(),
      'bill_email': email,
      'org_name': name,
      'bill_phone': phone,
      'comment': 'Cadastro via App Target Rastreamento',
      'acc_type': '1', // 1 = postpaid
      'org_type': orgType.toString(), // 1 = PJ, 2 = PF
    };

    final uri = Uri.https(serverAddress, '/ax/api.php', queryParams);

    try {
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data is Map<String, dynamic> ? data : {'code': 0, 'data': data};
        } catch (_) {
          return {'code': -1, 'msg': 'Resposta inválida do servidor: ${response.body}'};
        }
      } else {
        return {
          'code': response.statusCode,
          'msg': 'Erro HTTP ${response.statusCode} ao criar conta: ${response.body}',
        };
      }
    } catch (e) {
      return {'code': -1, 'msg': 'Falha de conexão com a API de Contrato: $e'};
    }
  }

  /// 2. Cria o Usuário do PILOT associado à conta (cmd=create_user)
  Future<Map<String, dynamic>> createUser({
    required String accountId,
    required String login,
    required String password,
    required String name,
    required String email,
    required String phone,
    int roleId = 1,
  }) async {
    final queryParams = {
      'cmd': 'create_user',
      'login': login,
      'password': password,
      'name': name,
      'role_id': roleId.toString(),
      'phone': phone,
      'email': email,
      'accounts': accountId,
      'account_id': accountId,
    };

    final uri = Uri.https(serverAddress, '/backend/api.php', queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data is Map<String, dynamic> ? data : {'code': 0, 'data': data};
        } catch (_) {
          return {'code': -1, 'msg': 'Resposta inválida do servidor: ${response.body}'};
        }
      } else {
        return {
          'code': response.statusCode,
          'msg': 'Erro HTTP ${response.statusCode} ao criar usuário: ${response.body}',
        };
      }
    } catch (e) {
      return {'code': -1, 'msg': 'Falha de conexão com a API de Usuário: $e'};
    }
  }

  /// 3. Adiciona o Veículo ao Contrato (cmd=vehadd)
  Future<Map<String, dynamic>> addVehicle({
    required String accountId,
    required String plate,
    required String imei,
    String? msisdn,
    String? vehicleModel,
    int vehicleType = 1,
  }) async {
    final queryParams = {
      'cmd': 'vehadd',
      'account_id': accountId,
      'type': vehicleType.toString(),
      'name': plate,
      'imei': imei,
      'vehmodel': defaultVehModel.toString(),
      'node': node.toString(),
      if (msisdn != null && msisdn.isNotEmpty) 'msisdn': msisdn,
      if (vehicleModel != null && vehicleModel.isNotEmpty) 'model': vehicleModel,
    };

    final uri = Uri.https(serverAddress, '/backend/api.php', queryParams);

    try {
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data is Map<String, dynamic> ? data : {'code': 0, 'data': data};
        } catch (_) {
          return {'code': -1, 'msg': 'Resposta inválida do servidor: ${response.body}'};
        }
      } else {
        return {
          'code': response.statusCode,
          'msg': 'Erro HTTP ${response.statusCode} ao vincular veículo: ${response.body}',
        };
      }
    } catch (e) {
      return {'code': -1, 'msg': 'Falha de conexão com a API de Veículos: $e'};
    }
  }

  /// Executa o fluxo completo de cadastro:
  /// 1. Cria Conta -> 2. Cria Usuário -> 3. Vincula Veículo
  Future<RegistrationResult> registerNewClient(ClientRegistrationData data) async {
    // 1. Criar Conta
    final resAccount = await createAccount(
      name: data.name,
      cpfCnpj: data.cleanCpfCnpj,
      email: data.email,
      phone: data.cleanPhone,
      orgType: data.orgType,
    );

    String? accountId;
    String finalLogin = data.email;
    String finalPassword = data.password;

    if (resAccount['code'] == 0 && resAccount['data'] != null) {
      final accData = resAccount['data'];
      accountId = accData['id']?.toString();
      if (accData['login'] != null) finalLogin = accData['login'].toString();
      if (accData['password'] != null) finalPassword = accData['password'].toString();
    } else {
      // Se a API retornar erro ou código != 0
      final msg = resAccount['msg'] ?? 'Erro desconhecido ao criar contrato.';
      return RegistrationResult(
        success: false,
        message: 'Falha na criação da conta: $msg',
      );
    }

    if (accountId == null || accountId.isEmpty) {
      return RegistrationResult(
        success: false,
        message: 'O servidor não retornou um ID de contrato válido.',
      );
    }

    // 2. Criar Usuário
    final resUser = await createUser(
      accountId: accountId,
      login: finalLogin,
      password: finalPassword,
      name: data.name,
      email: data.email,
      phone: data.cleanPhone,
    );

    int? userId;
    if (resUser['code'] == 0) {
      userId = int.tryParse(resUser['user_id']?.toString() ?? '');
    }

    // 3. Vincular Veículo
    final resVehicle = await addVehicle(
      accountId: accountId,
      plate: data.cleanPlate,
      imei: data.cleanImei,
      msisdn: data.simCard,
      vehicleModel: data.vehicleModel,
    );

    String? agentId;
    String? vehId;

    if (resVehicle['code'] == 0) {
      agentId = resVehicle['agent_id']?.toString();
      vehId = resVehicle['veh_id']?.toString();
    }

    return RegistrationResult(
      success: true,
      message: 'Cadastro realizado com sucesso!',
      accountId: accountId,
      userId: userId,
      agentId: agentId,
      vehId: vehId,
      login: finalLogin,
      password: finalPassword,
    );
  }
}
