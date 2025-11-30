# 설치 가이드

## 사전 요구사항 확인

시스템이 요구사항을 만족하는지 확인하세요:

```bash
# OS 확인 (CentOS 7+, Ubuntu 18+)
uname -a
lsb_release -d

# 디스크 용량 확인 (최소 50GB 필요)
df -h /disk

# 권한 확인
sudo -l

# 필수 도구 확인
which find md5sum bash
```

## 설치 단계

### 1단계: 저장소 클론

```bash
# SSH 방식 (권장)
git clone git@github.com:onlyonemaster/backup-system.git

# HTTPS 방식
git clone https://github.com/onlyonemaster/backup-system.git

cd backup-system
```

### 2단계: 회사 환경 설정

회사 규모에 맞는 설정 템플릿을 선택하세요:

```bash
# 소규모 회사 (10-50명)
cp config/small-company.conf config/config.sh

# 또는 중규모 회사 (50-200명)
cp config/medium-company.conf config/config.sh

# 또는 대규모 회사 (200명+)
cp config/large-company.conf config/config.sh
```

필요시 설정을 커스터마이징하세요:

```bash
vi config/config.sh
```

수정 가능한 옵션:
- `COMPANY_NAME`: 회사 이름
- `SOURCE_PHP_DIR`: PHP 소스 디렉토리 (기본: /home/kiam)
- `BACKUP_BASE_DIR`: 백업 저장 경로 (기본: /disk/backup/edit)
- `CRON_INTERVAL`: 실행 주기 (기본: */10 = 10분마다)
- `RETENTION_DAYS`: 보관 기간 (기본: 10일)

### 3단계: 설치 실행

설치 스크립트를 실행합니다:

```bash
sudo bash scripts/install.sh
```

설치 스크립트가 수행하는 작업:
1. 백업 디렉토리 생성
2. 스크립트를 /usr/local/bin에 설치
3. Cron 작업 등록
4. 로그 파일 생성
5. 테스트 실행

### 4단계: 설치 확인

```bash
# 백업 디렉토리 확인
ls -lh /disk/backup/edit/

# Cron 작업 확인
crontab -l | grep backup

# 로그 파일 확인
ls -lh /var/log/backup-*.log

# 최초 백업 확인 (설치 후 10분 대기 또는 수동 실행)
/usr/local/bin/backup-kiamphp.sh
/usr/local/bin/backup-system-config.sh
ls -lh /disk/backup/edit/kiamphp/
ls -lh /disk/backup/edit/system/
```

## 기본 사용법

### 백업 상태 확인

```bash
# PHP 파일 백업 목록
ls -lh /disk/backup/edit/kiamphp/

# 설정 파일 백업 목록
ls -lh /disk/backup/edit/system/
```

### 메타정보 확인

```bash
# JSON 메타정보 조회
cat /disk/backup/edit/kiamphp/.meta/*.meta | jq .

# 또는 보기 좋게 포맷
cat /disk/backup/edit/kiamphp/.meta/*.meta | python3 -m json.tool
```

### 버전 조회

```bash
# 파일의 모든 버전 조회
view-backup-versions.sh index.php

# 최신 버전만
view-backup-versions.sh index.php latest

# 최신 2개 비교
view-backup-versions.sh index.php diff
```

### 파일 복원

```bash
# 백업 파일 확인
ls -lh /disk/backup/edit/kiamphp/

# 특정 버전으로 복원
cp /disk/backup/edit/kiamphp/index.php-.-20251130-120000.bak /home/kiam/index.php

# 복원 확인
cat /home/kiam/index.php
```

### 로그 확인

```bash
# PHP 백업 로그
tail -f /var/log/backup-kiamphp.log

# 설정 백업 로그
tail -f /var/log/backup-system-config.log

# 로그 검색
grep "ERROR" /var/log/backup-*.log
grep "index.php" /var/log/backup-kiamphp.log
```

## 고급 설정

### Cron 주기 변경

설정 파일에서 `CRON_INTERVAL` 변경 후 재설치:

```bash
vi config/config.sh

# CRON_INTERVAL 변경
# */5 = 5분마다
# */10 = 10분마다 (기본)
# */30 = 30분마다
# 0 * = 매 시간

sudo bash scripts/install.sh
```

### 보관 기간 변경

```bash
vi config/config.sh

# RETENTION_DAYS 변경
# 기본값: 10
# 권장값: 7-30

# 설정 적용 (Cron이 자동으로 적용함)
```

### 모니터링 경로 추가

설정 파일에서 모니터링 경로를 수정한 후 스크립트를 수정합니다:

```bash
# 기본 모니터링 경로
# /etc/mysql
# /etc/php
# /etc/apache2
# /opt/apache/conf
# /home/scheduler/www/crontab
```

새로운 경로를 모니터링하려면:

1. config.sh에 경로 추가
2. backup-system-config.sh 수정
3. Cron 재등록

### 수동 백업 실행

```bash
# PHP 백업 수동 실행
/usr/local/bin/backup-kiamphp.sh

# 설정 백업 수동 실행
/usr/local/bin/backup-system-config.sh

# 둘 다 실행
/usr/local/bin/backup-kiamphp.sh && /usr/local/bin/backup-system-config.sh
```

## 문제 해결

### Q: 백업 파일이 생성되지 않음

A: 다음을 확인하세요:

```bash
# 1. 10분 내 수정된 파일이 있는가?
find /home/kiam -name "*.php" -mmin -10

# 2. 백업 디렉토리 권한 확인
ls -ld /disk/backup/edit/

# 3. 로그 확인
cat /var/log/backup-kiamphp.log

# 4. 스크립트 수동 실행
/usr/local/bin/backup-kiamphp.sh

# 5. 에러 확인
/usr/local/bin/backup-kiamphp.sh 2>&1 | tee /tmp/backup-debug.log
```

### Q: 디스크 공간 부족

A: 보관 기간을 단축하세요:

```bash
# 설정 파일에서 RETENTION_DAYS 변경
vi config/config.sh

# 기존 파일 수동 삭제
find /disk/backup/edit -name "*.bak" -mtime +5 -delete

# 확인
du -sh /disk/backup/edit/
```

### Q: Cron 작업이 실행되지 않음

A: Cron 설정을 확인하세요:

```bash
# 1. Crontab 확인
crontab -l | grep backup

# 2. Cron 서비스 상태 확인
sudo systemctl status crond

# 또는 CentOS/Ubuntu 버전에 따라
sudo systemctl status cron

# 3. Cron 로그 확인
sudo tail -f /var/log/cron

# 4. Cron 서비스 재시작
sudo systemctl restart crond
```

### Q: 권한 오류

A: 권한을 확인하세요:

```bash
# 스크립트 권한 확인
ls -l /usr/local/bin/backup-*.sh

# 백업 디렉토리 권한 확인
ls -ld /disk/backup/edit/

# 로그 파일 권한 확인
ls -l /var/log/backup-*.log
```

### Q: JSON 메타정보를 파싱할 수 없음

A: jq를 설치하세요:

```bash
# CentOS/RHEL
sudo yum install -y jq

# Ubuntu/Debian
sudo apt-get install -y jq

# 또는 Python 사용
python3 -m json.tool /disk/backup/edit/kiamphp/.meta/*.meta
```

## 언설치

백업 시스템을 제거하려면:

```bash
# 1. Cron 작업 제거
crontab -e
# 백업 관련 라인 삭제

# 2. 스크립트 제거
sudo rm -f /usr/local/bin/backup-*.sh
sudo rm -f /usr/local/bin/view-backup-*.sh

# 3. 로그 파일 제거 (선택)
sudo rm -f /var/log/backup-*.log

# 4. 백업 파일 제거 (선택)
sudo rm -rf /disk/backup/edit/
```

## 다음 단계

- [트러블슈팅 가이드](docs/트러블슈팅.md) 읽기
- [사용설명서](docs/사용설명서.md) 읽기
- 설정 튜닝 및 최적화
- 다른 서버에 설치
