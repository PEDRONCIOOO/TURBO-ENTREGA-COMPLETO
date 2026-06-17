import 'dart:convert';
import 'package:http/http.dart' as http;

/// Adaptador para lidar com diferentes tipos de respostas HTTP
class ResponseAdapter {
  /// Converte qualquer tipo de resposta para um Map
  static Map<String, dynamic> toMap(dynamic response) {
    if (response == null) return {};
    
    // Se for uma resposta do pacote http
    if (response is http.Response) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {'body': response.body};
      }
    }
    
    // Se for uma resposta do get_connect
    if (response is Response) {
      if (response.body is Map) {
        return response.body as Map<String, dynamic>;
      }
      try {
        return jsonDecode(response.body.toString()) as Map<String, dynamic>;
      } catch (e) {
        return {'body': response.body.toString()};
      }
    }
    
    // Se jÃ¡ for um Map
    if (response is Map) {
      return response as Map<String, dynamic>;
    }
    
    // Se for uma String, tenta fazer parse
    if (response is String) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (e) {
        return {'body': response};
      }
    }
    
    // Se nÃ£o for nenhum dos tipos acima, retorna vazio
    return {};
  }
  
  /// ObtÃ©m o status code de qualquer tipo de resposta
  static int getStatusCode(dynamic response) {
    if (response == null) return 500;
    
    if (response is http.Response) return response.statusCode;
    if (response is Response) return response.statusCode ?? 200;
    
    return 200; // Default para outros tipos
  }
  
  /// ObtÃ©m o status text de qualquer tipo de resposta
  static String getStatusText(dynamic response) {
    if (response == null) return 'No response';
    
    if (response is http.Response) return response.reasonPhrase ?? '';
    if (response is Response) return response.statusText ?? '';
    
    return ''; // Default para outros tipos
  }
  
  /// Extrai o corpo da resposta como String
  static String getBodyAsString(dynamic response) {
    if (response == null) return '';
    
    if (response is http.Response) return response.body;
    if (response is Response) return response.body.toString();
    if (response is String) return response;
    
    return response.toString();
  }
}

// Classes de compatibilidade
class Response {
  final dynamic body;
  final int? statusCode;
  final String? statusText;
  
  Response({
    required this.body,
    this.statusCode = 200,
    this.statusText = '',
  });
  
  // Construtor a partir de http.Response
  factory Response.fromHttpResponse(http.Response httpResponse) {
    return Response(
      body: httpResponse.body,
      statusCode: httpResponse.statusCode,
      statusText: httpResponse.reasonPhrase,
    );
  }
}

