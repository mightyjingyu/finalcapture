import 'dart:convert';
import 'dart:io';

class ProductSearchService {
  
  /// 텍스트 정규화 - 제품명, 브랜드명, 주요 키워드만 남기기
  String normalizeText(String rawText) {
    if (rawText.isEmpty) return '';
    
    // 1. 불필요한 기호, 줄바꿈 제거
    String cleaned = rawText
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')  // 줄바꿈, 탭 제거
        .replaceAll(RegExp(r'[^\w\s가-힣]'), ' ')  // 특수문자 제거 (한글, 영문, 숫자, 공백만 유지)
        .replaceAll(RegExp(r'\s+'), ' ')  // 연속된 공백을 하나로
        .trim();
    
    // 2. 제품 관련 키워드 추출 및 정리
    List<String> words = cleaned.split(' ');
    List<String> filteredWords = [];
    
    // 불필요한 단어들 제거
    final stopWords = {
      '사진', '이미지', '캡처', '스크린샷', '화면', '앱', '메뉴', '버튼',
      '구매', '주문', '결제', '배송', '리뷰', '평점', '가격', '할인',
      '무료', '쿠폰', '이벤트', '세일', '특가', '추천'
    };
    
    for (String word in words) {
      if (word.length > 1 && !stopWords.contains(word.toLowerCase())) {
        filteredWords.add(word);
      }
    }
    
    // 3. 브랜드명과 제품명 우선 정리
    String result = filteredWords.join(' ');
    
    // 4. 제품 카테고리 키워드 정리
    final categoryMappings = {
      '신발': '신발',
      '운동화': '운동화',
      '스니커즈': '스니커즈',
      '구두': '구두',
      '부츠': '부츠',
      '샌들': '샌들',
      '옷': '의류',
      '상의': '상의',
      '하의': '하의',
      '바지': '바지',
      '셔츠': '셔츠',
      '티셔츠': '티셔츠',
      '후드': '후드티',
      '재킷': '재킷',
      '코트': '코트',
      '가방': '가방',
      '핸드백': '핸드백',
      '백팩': '백팩',
      '지갑': '지갑',
      '시계': '시계',
      '액세서리': '액세서리',
      '모자': '모자',
      '스카프': '스카프',
      '벨트': '벨트',
      '반지': '반지',
      '목걸이': '목걸이',
      '귀걸이': '귀걸이',
      '화장품': '화장품',
      '스킨케어': '스킨케어',
      '메이크업': '메이크업',
      '향수': '향수',
      '전자제품': '전자제품',
      '스마트폰': '스마트폰',
      '이어폰': '이어폰',
      '헤드폰': '헤드폰',
      '충전기': '충전기',
      '케이스': '케이스',
      '보호필름': '보호필름'
    };
    
    // 카테고리 키워드가 있으면 추가
    for (String category in categoryMappings.keys) {
      if (result.toLowerCase().contains(category)) {
        if (!result.toLowerCase().contains(categoryMappings[category]!)) {
          result += ' ${categoryMappings[category]}';
        }
      }
    }
    
    return result.trim();
  }
  
  /// URL 인코딩
  String urlEncode(String text) {
    return Uri.encodeComponent(text);
  }
  
  /// 검색 URL 생성
  Map<String, String> generateSearchUrls(String normalizedText) {
    if (normalizedText.isEmpty) {
      return {};
    }
    
    final encodedQuery = urlEncode(normalizedText);
    
    return {
      'naver': 'https://search.shopping.naver.com/search/all?query=$encodedQuery',
      'google': 'https://www.google.com/search?tbm=shop&q=$encodedQuery',
      'coupang': 'https://www.coupang.com/np/search?q=$encodedQuery',
      'musinsa': 'https://www.musinsa.com/search/musinsa/integration?type=&q=$encodedQuery',
      'ably': 'https://www.a-bly.com/search?keyword=$encodedQuery',
    };
  }
  
  /// 제품 검색 결과 생성 (JSON 형태)
  Map<String, dynamic> generateProductSearchResult(String rawText) {
    print('🔍 제품 검색 결과 생성 시작');
    print('📝 원본 텍스트: $rawText');
    
    // 1. 텍스트 정규화
    final normalizedText = normalizeText(rawText);
    print('✨ 정규화된 텍스트: $normalizedText');
    
    // 2. 검색 URL 생성
    final searchUrls = generateSearchUrls(normalizedText);
    print('🔗 생성된 검색 URL: ${searchUrls.length}개');
    
    // 3. JSON 결과 생성
    final result = {
      'normalized_text': normalizedText,
      'links': searchUrls,
      'raw_text': rawText,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    print('✅ 제품 검색 결과 생성 완료');
    print('📊 결과: $result');
    
    return result;
  }
  
  /// 제품 검색 결과를 JSON 문자열로 변환
  String generateProductSearchJson(String rawText) {
    final result = generateProductSearchResult(rawText);
    return json.encode(result);
  }
  
  /// 제품 검색 결과를 파일로 저장
  Future<void> saveProductSearchResult(String rawText, String filePath) async {
    try {
      final jsonResult = generateProductSearchJson(rawText);
      final file = File(filePath);
      await file.writeAsString(jsonResult);
      print('💾 제품 검색 결과 저장 완료: $filePath');
    } catch (e) {
      print('❌ 파일 저장 실패: $e');
    }
  }
  
  /// 제품 검색 결과를 콘솔에 출력
  void printProductSearchResult(String rawText) {
    final result = generateProductSearchResult(rawText);
    
    print('\n🔍 === 제품 검색 결과 ===');
    print('📝 원본 텍스트: ${result['raw_text']}');
    print('✨ 정규화된 텍스트: ${result['normalized_text']}');
    print('🔗 검색 링크:');
    
    final links = result['links'] as Map<String, String>;
    links.forEach((platform, url) {
      print('  $platform: $url');
    });
    
    print('⏰ 생성 시간: ${result['timestamp']}');
    print('========================\n');
  }
}
