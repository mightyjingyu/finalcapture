#!/bin/bash

echo "🔥 Firestore 데이터 삭제 스크립트"
echo "⚠️  주의: 이 스크립트는 모든 사진과 앨범 데이터를 삭제합니다!"
echo ""

# Firebase CLI가 설치되어 있는지 확인
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI가 설치되어 있지 않습니다."
    echo "다음 명령어로 설치하세요: npm install -g firebase-tools"
    exit 1
fi

# Firebase 프로젝트 확인
echo "📋 현재 Firebase 프로젝트:"
firebase projects:list

echo ""
echo "🚨 정말로 모든 데이터를 삭제하시겠습니까? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🗑️  데이터 삭제 중..."
    
    # 사진 컬렉션 삭제
    echo "📸 photos 컬렉션 삭제 중..."
    firebase firestore:delete --recursive --yes photos
    
    # 앨범 컬렉션 삭제
    echo "📁 albums 컬렉션 삭제 중..."
    firebase firestore:delete --recursive --yes albums
    
    echo "✅ 데이터 삭제 완료!"
else
    echo "❌ 삭제가 취소되었습니다."
fi

