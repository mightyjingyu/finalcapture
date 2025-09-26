import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'photo_service.dart';

class GeminiService {
  final Dio _dio = Dio();
  final String _apiKey = 'AIzaSyDARcqzcmqYXHMMTwZxFB_xe2H5jh0zm0M';

  // 바이트 데이터로 이미지 OCR 및 카테고리 분류 (웹용)
  Future<OCRResult> processImageBytes(Uint8List imageBytes, String fileName) async {
    try {
      print('🔄 바이트 데이터 처리 중: $fileName');
      print('📊 이미지 크기: ${imageBytes.length} bytes');
      final base64Image = base64Encode(imageBytes);
      print('🔤 Base64 인코딩 완료: ${base64Image.length} characters');

      print('🤖 Gemini API 요청 구성 중...');
      // Gemini API 요청 구성
      final requestData = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
이 스크린샷 이미지를 분석하여 카테고리를 분류해주세요.

**분석 단계:**
1. 이미지에 있는 모든 텍스트를 OCR로 추출
2. 이미지의 시각적 요소 분석 (UI, 레이아웃, 색상 등)
3. 텍스트와 시각적 요소를 종합하여 카테고리 분류

**카테고리 분류 기준:**
- **정보/참고용**: 일반적인 정보, 뉴스, 문서, 웹페이지, 참고 자료
- **대화/메시지**: 채팅, 메신저, 카카오톡, 문자, 소셜미디어 대화
- **학습/업무 메모**: 공부 자료, 노트, 업무 문서, 프레젠테이션, 강의
- **재미/밈/감정**: 유머, 밈, 재미있는 이미지, 감정 표현
- **일정/예약**: 캘린더, 일정표, 예약 확인서, 시간표
- **증빙/거래**: 영수증, 결제 내역, 계좌 정보, 거래 증명서
- **옷**: 의류, 패션, 쇼핑몰 상품, 옷 관련 정보
- **제품**: 전자제품, 생활용품, 상품 정보, 리뷰

**응답 형식:**
{
  "extracted_text": "추출된 텍스트",
  "category": "분류된 카테고리",
  "confidence": 0.95,
  "tags": ["태그1", "태그2", "태그3"],
  "reasoning": "분류한 구체적인 이유와 근거를 상세히 설명"
}

**중요:** 텍스트가 없거나 읽을 수 없는 경우에도 이미지의 시각적 특성을 바탕으로 분류해주세요.
'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 4096,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      print('📡 Gemini API 호출 중...');
      final response = await _dio.post(
        '${AppConstants.geminiApiUrl}?key=$_apiKey',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📡 API 응답 상태: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = response.data;
        final content = responseData['candidates'][0]['content']['parts'][0]['text'];
        print('📝 API 응답 내용: $content');
        
        // JSON 응답 파싱
        try {
          print('🔍 JSON 파싱 시도 중...');
          final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            print('📋 추출된 JSON: $jsonStr');
            final parsedData = json.decode(jsonStr);
            
            final result = OCRResult(
              text: parsedData['extracted_text'] ?? '',
              category: _validateCategory(parsedData['category'] ?? '정보/참고용'),
              confidence: (parsedData['confidence'] ?? 0.8).toDouble(),
              tags: List<String>.from(parsedData['tags'] ?? []),
              reasoning: parsedData['reasoning'] ?? '분류 근거 없음',
            );
            print('✅ OCR 결과: ${result.category} (신뢰도: ${result.confidence})');
            print('📝 분류 근거: ${result.reasoning}');
            print('🏷️ 태그: ${result.tags}');
            print('📄 추출된 텍스트: ${result.text}');
            return result;
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
        }
        
        // JSON 파싱 실패 시 폴백 처리
        return _fallbackProcessing(content);
      } else {
        throw Exception('Gemini API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Gemini Service Error: $e');
      // API 호출 실패 시 기본값 반환
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['자동분류실패'],
        reasoning: 'API 호출 실패: $e',
      );
    }
  }

  // 이미지 OCR 및 카테고리 분류
  Future<OCRResult> processImage(File imageFile) async {
    try {
      print('🔄 이미지 파일 읽기 중: ${imageFile.path}');
      // 이미지를 Base64로 인코딩
      final imageBytes = await imageFile.readAsBytes();
      print('📊 이미지 크기: ${imageBytes.length} bytes');
      final base64Image = base64Encode(imageBytes);
      print('🔤 Base64 인코딩 완료: ${base64Image.length} characters');

      print('🤖 Gemini API 요청 구성 중...');
      // Gemini API 요청 구성
      final requestData = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
이 스크린샷 이미지를 분석하여 카테고리를 분류해주세요.

**분석 단계:**
1. 이미지에 있는 모든 텍스트를 OCR로 추출
2. 이미지의 시각적 요소 분석 (UI, 레이아웃, 색상 등)
3. 텍스트와 시각적 요소를 종합하여 카테고리 분류

**카테고리 분류 기준:**
- **정보/참고용**: 일반적인 정보, 뉴스, 문서, 웹페이지, 참고 자료
- **대화/메시지**: 채팅, 메신저, 카카오톡, 문자, 소셜미디어 대화
- **학습/업무 메모**: 공부 자료, 노트, 업무 문서, 프레젠테이션, 강의
- **재미/밈/감정**: 유머, 밈, 재미있는 이미지, 감정 표현
- **일정/예약**: 캘린더, 일정표, 예약 확인서, 시간표
- **증빙/거래**: 영수증, 결제 내역, 계좌 정보, 거래 증명서
- **옷**: 의류, 패션, 쇼핑몰 상품, 옷 관련 정보
- **제품**: 전자제품, 생활용품, 상품 정보, 리뷰

**응답 형식:**
{
  "extracted_text": "추출된 텍스트",
  "category": "분류된 카테고리",
  "confidence": 0.95,
  "tags": ["태그1", "태그2", "태그3"],
  "reasoning": "분류한 구체적인 이유와 근거를 상세히 설명"
}

**중요:** 텍스트가 없거나 읽을 수 없는 경우에도 이미지의 시각적 특성을 바탕으로 분류해주세요.
'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 4096,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      print('🌐 Gemini API 호출 중...');
      // API 호출
      final response = await _dio.post(
        '${AppConstants.geminiApiUrl}?key=$_apiKey',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📡 API 응답 상태: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = response.data;
        final content = responseData['candidates'][0]['content']['parts'][0]['text'];
        print('📝 API 응답 내용: $content');
        
        // JSON 응답 파싱
        try {
          print('🔍 JSON 파싱 시도 중...');
          final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            print('📋 추출된 JSON: $jsonStr');
            final parsedData = json.decode(jsonStr);
            
            final result = OCRResult(
              text: parsedData['extracted_text'] ?? '',
              category: _validateCategory(parsedData['category'] ?? '정보/참고용'),
              confidence: (parsedData['confidence'] ?? 0.8).toDouble(),
              tags: List<String>.from(parsedData['tags'] ?? []),
              reasoning: parsedData['reasoning'] ?? '분류 근거 없음',
            );
            print('✅ OCR 결과: ${result.category} (신뢰도: ${result.confidence})');
            print('📝 분류 근거: ${result.reasoning}');
            print('🏷️ 태그: ${result.tags}');
            print('📄 추출된 텍스트: ${result.text}');
            return result;
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
        }
        
        // JSON 파싱 실패 시 폴백 처리
        return _fallbackProcessing(content);
      } else {
        throw Exception('Gemini API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Gemini Service Error: $e');
      // API 호출 실패 시 기본값 반환
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['자동분류실패'],
        reasoning: 'API 호출 실패: $e',
      );
    }
  }

  // 카테고리 유효성 검사
  String _validateCategory(String category) {
    if (AppConstants.defaultCategories.contains(category)) {
      return category;
    }
    
    // 유사한 카테고리 매핑
    final categoryMappings = {
      '정보': '정보/참고용',
      '참고': '정보/참고용',
      '메모': '학습/업무 메모',
      '업무': '학습/업무 메모',
      '학습': '학습/업무 메모',
      '공부': '학습/업무 메모',
      '대화': '대화/메시지',
      '메시지': '대화/메시지',
      '채팅': '대화/메시지',
      '카톡': '대화/메시지',
      '재미': '재미/밈/감정',
      '밈': '재미/밈/감정',
      '웃긴': '재미/밈/감정',
      '감정': '재미/밈/감정',
      '일정': '일정/예약',
      '예약': '일정/예약',
      '스케줄': '일정/예약',
      '약속': '일정/예약',
      '증빙': '증빙/거래',
      '거래': '증빙/거래',
      '영수증': '증빙/거래',
      '결제': '증빙/거래',
      '구매': '증빙/거래',
      '의류': '옷',
      '패션': '옷',
      '쇼핑': '제품',
      '상품': '제품',
    };
    
    for (final mapping in categoryMappings.entries) {
      if (category.contains(mapping.key)) {
        return mapping.value;
      }
    }
    
    return '정보/참고용'; // 기본값
  }

  // 폴백 처리 (JSON 파싱 실패 시)
  OCRResult _fallbackProcessing(String content) {
    final text = content.replaceAll(RegExp(r'[{}"\[\],]'), ' ').trim();
    
    // 키워드 기반 카테고리 추론
    String category = '정보/참고용';
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('메시지') || lowerContent.contains('대화') || lowerContent.contains('채팅')) {
      category = '대화/메시지';
    } else if (lowerContent.contains('일정') || lowerContent.contains('예약') || lowerContent.contains('약속')) {
      category = '일정/예약';
    } else if (lowerContent.contains('영수증') || lowerContent.contains('결제') || lowerContent.contains('구매')) {
      category = '증빙/거래';
    } else if (lowerContent.contains('학습') || lowerContent.contains('업무') || lowerContent.contains('메모')) {
      category = '학습/업무 메모';
    }
    
    return OCRResult(
      text: text.length > 100 ? '${text.substring(0, 100)}...' : text,
      category: category,
      confidence: 0.6,
      tags: ['자동분류'],
      reasoning: 'JSON 파싱 실패로 키워드 기반 분류 사용',
    );
  }

  // 배치 처리 (여러 이미지 동시 처리)
  Future<List<OCRResult>> processBatchImages(List<File> imageFiles) async {
    final results = <OCRResult>[];
    
    // 동시 처리 제한 (API 요청 제한 고려)
    const batchSize = 3;
    
    for (int i = 0; i < imageFiles.length; i += batchSize) {
      final batch = imageFiles.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((file) => processImage(file)),
      );
      results.addAll(batchResults);
      
      // API 호출 간격 조절
      if (i + batchSize < imageFiles.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return results;
  }

  // 텍스트만으로 카테고리 분류 (이미 추출된 OCR 텍스트용)
  Future<String> classifyTextOnly(String text) async {
    try {
      final requestData = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
다음 텍스트를 분석하여 가장 적절한 카테고리로 분류해주세요:

텍스트: "$text"

카테고리 옵션:
- 정보/참고용
- 대화/메시지
- 학습/업무 메모
- 재미/밈/감정
- 일정/예약
- 증빙/거래
- 옷
- 제품

응답은 카테고리 이름만 정확히 답해주세요.
'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 50,
        }
      };

      final response = await _dio.post(
        '${AppConstants.geminiApiUrl}?key=$_apiKey',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data['candidates'][0]['content']['parts'][0]['text'];
        return _validateCategory(content.trim());
      }
    } catch (e) {
      print('Text classification error: $e');
    }
    
    return '정보/참고용';
  }

}
