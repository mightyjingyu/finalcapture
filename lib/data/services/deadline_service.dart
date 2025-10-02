import 'dart:io';
import 'dart:convert';

class DeadlineService {
  
  /// 텍스트에서 기한을 추출하고 ISO 포맷으로 변환
  String? extractDeadline(String text) {
    if (text.isEmpty) return null;
    
    print('🔍 기한 추출 시작: $text');
    
    // 작년/과거 언급이 있는지 먼저 확인
    if (text.contains('작년') || text.contains('지난해') || text.contains('어제') || text.contains('과거')) {
      print('⚠️ 과거 언급 감지, 기한 추출 중단');
      return null;
    }
    
    final now = DateTime.now();
    
    // 1. 명시적 연도가 있는 경우 먼저 처리
    final explicitYearPatterns = [
      RegExp(r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일'),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})'),
    ];
    
    for (final pattern in explicitYearPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final year = match.group(1)!;
          final month = match.group(2)!.padLeft(2, '0');
          final day = match.group(3)!.padLeft(2, '0');
          
          final explicitDate = DateTime.parse('$year-$month-$day');
          if (explicitDate.isBefore(now)) {
            print('⚠️ 명시적 과거 날짜 감지: $explicitDate');
            return null; // 과거 날짜는 기한이 아님
          }
          
          final isoDate = '${explicitDate.year}-${explicitDate.month.toString().padLeft(2, '0')}-${explicitDate.day.toString().padLeft(2, '0')}';
          print('✅ 명시적 연도 기한 추출 성공: $isoDate');
          return isoDate;
        } catch (e) {
          print('❌ 명시적 연도 날짜 파싱 오류: $e');
          continue;
        }
      }
    }
    
    // 2. 연도가 없는 경우 (MM월 DD일, MM-DD, MM/DD)
    final monthDayPatterns = [
      RegExp(r'(\d{1,2})월\s*(\d{1,2})일'),
      RegExp(r'(\d{1,2})-(\d{1,2})'),
      RegExp(r'(\d{1,2})/(\d{1,2})'),
    ];
    
    for (final pattern in monthDayPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final month = match.group(1)!.padLeft(2, '0');
          final day = match.group(2)!.padLeft(2, '0');
          
          // 올해 날짜로 해석
          final thisYearDate = DateTime.parse('${now.year}-$month-$day');
          
          if (thisYearDate.isBefore(now)) {
            // 과거 날짜면 내년으로 해석
            final nextYearDate = DateTime(now.year + 1, thisYearDate.month, thisYearDate.day);
            final isoDate = '${nextYearDate.year}-${nextYearDate.month.toString().padLeft(2, '0')}-${nextYearDate.day.toString().padLeft(2, '0')}';
            print('📅 과거 날짜 감지, 내년으로 해석: $isoDate');
            return isoDate;
          } else {
            // 미래 날짜면 올해로 해석
            final isoDate = '${thisYearDate.year}-${thisYearDate.month.toString().padLeft(2, '0')}-${thisYearDate.day.toString().padLeft(2, '0')}';
            print('✅ 월일 기한 추출 성공: $isoDate');
            return isoDate;
          }
        } catch (e) {
          print('❌ 월일 날짜 파싱 오류: $e');
          continue;
        }
      }
    }
    
    // 3. 일만 있는 경우 (DD일)
    final dayPattern = RegExp(r'(\d{1,2})일');
    final dayMatch = dayPattern.firstMatch(text);
    if (dayMatch != null) {
      try {
        final day = dayMatch.group(1)!.padLeft(2, '0');
        final month = now.month.toString().padLeft(2, '0');
        
        // 이번 달 날짜로 해석
        final thisMonthDate = DateTime.parse('${now.year}-$month-$day');
        
        if (thisMonthDate.isBefore(now)) {
          // 과거 날짜면 다음 달로 해석
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          final nextMonthDate = DateTime(nextYear, nextMonth, thisMonthDate.day);
          final isoDate = '${nextMonthDate.year}-${nextMonthDate.month.toString().padLeft(2, '0')}-${nextMonthDate.day.toString().padLeft(2, '0')}';
          print('📅 과거 날짜 감지, 다음 달로 해석: $isoDate');
          return isoDate;
        } else {
          // 미래 날짜면 이번 달로 해석
          final isoDate = '${thisMonthDate.year}-${thisMonthDate.month.toString().padLeft(2, '0')}-${thisMonthDate.day.toString().padLeft(2, '0')}';
          print('✅ 일 기한 추출 성공: $isoDate');
          return isoDate;
        }
      } catch (e) {
        print('❌ 일 날짜 파싱 오류: $e');
      }
    }
    
    print('❌ 기한을 찾을 수 없음');
    return null;
  }
  
  /// 기한이 있는지 확인
  bool hasDeadline(String text) {
    return extractDeadline(text) != null;
  }
  
  /// 알림 시간 계산 (3일 전, 1일 전, 당일 9시)
  List<String> calculateNotifications(String deadline) {
    try {
      final deadlineDate = DateTime.parse(deadline);
      final notifications = <String>[];
      
      // 3일 전 9시
      final threeDaysBefore = deadlineDate.subtract(const Duration(days: 3));
      notifications.add(DateTime(threeDaysBefore.year, threeDaysBefore.month, threeDaysBefore.day, 9).toIso8601String());
      
      // 1일 전 9시
      final oneDayBefore = deadlineDate.subtract(const Duration(days: 1));
      notifications.add(DateTime(oneDayBefore.year, oneDayBefore.month, oneDayBefore.day, 9).toIso8601String());
      
      // 당일 9시
      notifications.add(DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day, 9).toIso8601String());
      
      print('🔔 알림 예약: ${notifications.length}개');
      for (int i = 0; i < notifications.length; i++) {
        final days = ['3일 전', '1일 전', '당일'][i];
        print('  $days: ${notifications[i]}');
      }
      
      return notifications;
    } catch (e) {
      print('❌ 알림 시간 계산 오류: $e');
      return [];
    }
  }
  
  /// 기한 정보를 JSON으로 생성
  Map<String, dynamic> generateDeadlineResult(String rawText, String normalizedText) {
    print('📅 기한 정보 생성 시작');
    print('📝 원본 텍스트: $rawText');
    print('✨ 정규화된 텍스트: $normalizedText');
    
    final deadline = extractDeadline(rawText);
    
    if (deadline != null) {
      final notifications = calculateNotifications(deadline);
      
      final result = {
        'normalized_text': normalizedText,
        'deadline': deadline,
        'album': 'Deadlines',
        'links': <String, String>{},
        'notifications': notifications,
        'raw_text': rawText,
        'timestamp': DateTime.now().toIso8601String(),
        'has_deadline': true,
      };
      
      print('✅ 기한 정보 생성 완료');
      print('📅 기한: $deadline');
      print('📁 앨범: Deadlines');
      print('🔔 알림: ${notifications.length}개');
      
      return result;
    } else {
      // 기한이 없는 경우 일반 제품 검색 결과
      final result = {
        'normalized_text': normalizedText,
        'deadline': null,
        'album': '정보/참고용', // 기본 앨범
        'links': <String, String>{},
        'notifications': <String>[],
        'raw_text': rawText,
        'timestamp': DateTime.now().toIso8601String(),
        'has_deadline': false,
      };
      
      print('ℹ️ 기한 없음 - 일반 분류');
      return result;
    }
  }
  
  /// 기한 정보를 JSON 문자열로 변환
  String generateDeadlineJson(String rawText, String normalizedText) {
    final result = generateDeadlineResult(rawText, normalizedText);
    return json.encode(result);
  }
  
  /// 기한 정보를 파일로 저장
  Future<void> saveDeadlineResult(String rawText, String normalizedText, String filePath) async {
    try {
      final jsonResult = generateDeadlineJson(rawText, normalizedText);
      final file = File(filePath);
      await file.writeAsString(jsonResult);
      print('💾 기한 정보 저장 완료: $filePath');
    } catch (e) {
      print('❌ 파일 저장 실패: $e');
    }
  }
  
  /// 기한 정보를 콘솔에 출력
  void printDeadlineResult(String rawText, String normalizedText) {
    final result = generateDeadlineResult(rawText, normalizedText);
    
    print('\n📅 === 기한 정보 결과 ===');
    print('📝 원본 텍스트: ${result['raw_text']}');
    print('✨ 정규화된 텍스트: ${result['normalized_text']}');
    
    if (result['has_deadline'] == true) {
      print('📅 기한: ${result['deadline']}');
      print('📁 앨범: ${result['album']}');
      print('🔔 알림 예약:');
      
      final notifications = result['notifications'] as List<String>;
      for (int i = 0; i < notifications.length; i++) {
        final days = ['3일 전', '1일 전', '당일'][i];
        print('  $days: ${notifications[i]}');
      }
    } else {
      print('ℹ️ 기한 없음 - 일반 분류');
      print('📁 앨범: ${result['album']}');
    }
    
    print('⏰ 생성 시간: ${result['timestamp']}');
    print('========================\n');
  }
}
