# Backup System - 통합 파일 백업 시스템

자동으로 PHP 파일과 설정 파일을 백업하고 버전 관리하는 시스템입니다.

## 주요 기능

- ✅ PHP 파일 자동 백업 (10분 주기, 커스터마이징 가능)
- ✅ 설정 파일 자동 백업 (MySQL, PHP, Apache, 스케줄러)
- ✅ JSON 메타데이터 (타임스탐프, MD5 해시, 파일 크기, 라인 수)
- ✅ 변경 이력 자동 기록 (이전 버전과의 차이)
- ✅ 자동 보관 정책 (10일 자동 정리, 커스터마이징 가능)
- ✅ 버전 복구 도구 (빠른 파일 복구)

## 빠른 시작

```bash
# 저장소 클론
git clone https://github.com/onlyonemaster/backup-system.git
cd backup-system

# 설정 파일 준비
cp config/small-company.conf config/config.sh  # 또는 medium/large
vi config/config.sh  # 회사 정보 수정

# 설치 및 자동화
sudo bash scripts/install.sh
```

## 시스템 요구사항

- **OS**: CentOS/Ubuntu 7+
- **디스크**: 최소 50GB 여유 공간
- **권한**: Root 또는 sudo
- **필수 도구**: find, md5sum, cron, bash 4.0+

## 설치 방법

자세한 설치 가이드는 [SETUP.md](SETUP.md) 참고

```bash
# 1단계: 저장소 클론
git clone https://github.com/onlyonemaster/backup-system.git
cd backup-system

# 2단계: 회사 환경에 맞는 설정 선택
cp config/small-company.conf config/config.sh
# 또는: cp config/medium-company.conf config/config.sh
# 또는: cp config/large-company.conf config/config.sh

# 3단계: 설정 파일 수정 (필요시)
vi config/config.sh

# 4단계: 설치 실행
sudo bash scripts/install.sh

# 5단계: 테스트 (10분 대기 후 자동 실행)
ls -lh /disk/backup/edit/kiamphp/
ls -lh /disk/backup/edit/system/
```

## 사용 방법

### 백업 상태 확인

```bash
# PHP 백업 파일 조회
ls -lh /disk/backup/edit/kiamphp/

# 설정 백업 파일 조회
ls -lh /disk/backup/edit/system/

# 메타정보 확인
cat /disk/backup/edit/kiamphp/.meta/*.meta
```

### 버전 조회

```bash
# 파일의 모든 버전 조회
view-backup-versions.sh index.php

# 최신 버전만 조회
view-backup-versions.sh index.php latest

# 최신 2개 버전 비교
view-backup-versions.sh index.php diff
```

### 파일 복원

```bash
# 특정 버전으로 복원
cp /disk/backup/edit/kiamphp/index.php-.-20251130-074313.bak /home/kiam/index.php

# 설정 파일 복원
cp /disk/backup/edit/system/mysqld.cnf-mysql.conf.d-20251130-074502.bak /etc/mysql/mysql.conf.d/mysqld.cnf

# 서비스 재시작 (필요시)
sudo systemctl restart mysql
```

### 로그 확인

```bash
# PHP 백업 로그 실시간 모니터링
tail -f /var/log/backup-kiamphp.log

# 설정 백업 로그 실시간 모니터링
tail -f /var/log/backup-system-config.log
```

### 모니터링

```bash
# 디스크 용량 확인
du -sh /disk/backup/edit/

# 백업 파일 개수
find /disk/backup/edit -name "*.bak" | wc -l

# 메타파일 개수
find /disk/backup/edit -name "*.meta" | wc -l
```

## 설정 옵션

### config.sh 주요 설정

```bash
# 회사 이름
COMPANY_NAME="회사이름"

# PHP 소스 디렉토리
SOURCE_PHP_DIR="/home/kiam"

# 백업 저장 경로
BACKUP_BASE_DIR="/disk/backup/edit"

# Cron 주기 (*/10 = 10분마다, */5 = 5분마다)
CRON_INTERVAL="*/10"

# 보관 기간 (일)
RETENTION_DAYS=10
```

### 회사 규모별 추천 설정

| 규모 | 설정 | 특징 |
|------|------|------|
| 소규모 (10-50명) | small-company.conf | 10분마다, 10일 보관 |
| 중규모 (50-200명) | medium-company.conf | 5분마다, 15일 보관 |
| 대규모 (200명+) | large-company.conf | 2분마다, 30일 보관 |

## 메타데이터 구조

각 백업 파일마다 JSON 메타데이터가 생성됩니다:

```json
{
  "timestamp": "20251130-074313",
  "original_path": "index.php",
  "file_type": "php",
  "source_directory": "/home/kiam",
  "backup_filename": "index.php-.-20251130-074313.bak",
  "file_size_bytes": 1024,
  "total_lines": 50,
  "md5_hash": "a98a8b86bdf7805b1ac551eb9a885ff5",
  "backup_datetime": "2025-11-30 07:43:13",
  "korean_date": "2025년 11월 30일 토 07:43:13 AM",
  "changes": "9 lines modified",
  "previous_backup": "index.php-.-20251130-074302.bak"
}
```

## 문제 해결

문제 해결 가이드는 [docs/트러블슈팅.md](docs/트러블슈팅.md) 참고

## 라이선스

MIT License - 상업용/개인용 모두 가능

자세한 내용은 [LICENSE](LICENSE) 참고

## 기여

이슈나 풀 리퀘스트를 통해 기여할 수 있습니다.

## 지원

- 📧 GitHub Issues: [이슈 등록](https://github.com/onlyonemaster/backup-system/issues)
- 📚 문서: [SETUP.md](SETUP.md), [docs/](docs/)

## 변경 이력

- **v1.0** (2025-11-30): 초기 배포
  - PHP 파일 백업 시스템
  - 설정 파일 백업 시스템
  - 메타데이터 추적
  - 자동 보관 정책
  - 버전 조회 도구
