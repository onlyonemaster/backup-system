#!/bin/bash
# 백업 시스템 설치 스크립트

set -e

echo "=========================================="
echo "  백업 시스템 설치"
echo "=========================================="
echo ""

# 1. 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "오류: 이 스크립트는 root 권한으로 실행해야 합니다."
    exit 1
fi

# 2. 설정 파일 확인
if [ ! -f "config/config.sh" ]; then
    echo "오류: config/config.sh를 찾을 수 없습니다."
    echo "먼저 config/config-template.sh를 복사하여 config/config.sh를 만들어주세요."
    exit 1
fi

# config.sh 소스
source config/config.sh

echo "설정 파일 읽음: config/config.sh"
echo "  회사명: $COMPANY_NAME"
echo "  소스 디렉토리: $SOURCE_PHP_DIR"
echo "  백업 경로: $BACKUP_BASE_DIR"
echo ""

# 3. 백업 디렉토리 생성
echo "1/4 백업 디렉토리 생성 중..."
mkdir -p "$BACKUP_BASE_DIR/kiamphp/.meta"
mkdir -p "$BACKUP_BASE_DIR/system/.meta"
chmod 755 "$BACKUP_BASE_DIR"
echo "    완료: $BACKUP_BASE_DIR"
echo ""

# 4. 스크립트 설치
echo "2/4 스크립트 설치 중..."
cp scripts/backup-kiamphp.sh /usr/local/bin/backup-kiamphp.sh
cp scripts/backup-system-config.sh /usr/local/bin/backup-system-config.sh
cp scripts/view-backup-versions.sh /usr/local/bin/view-backup-versions.sh
chmod 755 /usr/local/bin/backup-kiamphp.sh
chmod 755 /usr/local/bin/backup-system-config.sh
chmod 755 /usr/local/bin/view-backup-versions.sh
echo "    완료: /usr/local/bin/"
echo ""

# 5. Cron 작업 등록
echo "3/4 Cron 작업 등록 중..."
CRON_JOB="*/10 * * * * /usr/local/bin/backup-kiamphp.sh && /usr/local/bin/backup-system-config.sh"

# 기존 cron 제거
crontab -l 2>/dev/null | grep -v "backup-kiamphp.sh" | crontab - 2>/dev/null || true

# 새 cron 추가
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo "    완료: 10분마다 실행"
echo ""

# 6. 로그 파일 생성
echo "4/4 로그 파일 생성 중..."
touch /var/log/backup-kiamphp.log
touch /var/log/backup-system-config.log
chmod 644 /var/log/backup-kiamphp.log
chmod 644 /var/log/backup-system-config.log
echo "    완료: /var/log/"
echo ""

# 7. 테스트 실행
echo "=========================================="
echo "  설치 완료! 테스트 실행 중..."
echo "=========================================="
echo ""

/usr/local/bin/backup-kiamphp.sh
/usr/local/bin/backup-system-config.sh

echo ""
echo "=========================================="
echo "  설치 완료!"
echo "=========================================="
echo ""
echo "다음 명령어로 백업 상태를 확인할 수 있습니다:"
echo ""
echo "  # PHP 백업 확인"
echo "  ls -lh $BACKUP_BASE_DIR/kiamphp/"
echo ""
echo "  # 설정 백업 확인"
echo "  ls -lh $BACKUP_BASE_DIR/system/"
echo ""
echo "  # 버전 조회"
echo "  view-backup-versions.sh <파일명>"
echo ""
echo "  # 로그 확인"
echo "  tail -f /var/log/backup-kiamphp.log"
echo "  tail -f /var/log/backup-system-config.log"
echo ""
