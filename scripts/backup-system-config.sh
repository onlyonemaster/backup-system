#!/bin/bash
# 시스템 설정 파일 백업 스크립트 (메타정보 포함)

BACKUP_DIR="/disk/backup/edit/system"
LOG_FILE="/var/log/backup-system-config.log"
META_DIR="$BACKUP_DIR/.meta"

mkdir -p "$BACKUP_DIR" "$META_DIR"

# 백업 함수
backup_file() {
    local FILE=$1
    local SOURCE_DIR=$2
    local FILE_EXT=$3

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    RELPATH=${FILE#$SOURCE_DIR/}
    FILENAME=$(basename "$FILE")
    DIRPATH=$(dirname "$RELPATH")
    DIRPATH_SAFE=${DIRPATH//\//_}

    BACKUP_FILE="$BACKUP_DIR/${FILENAME}-${DIRPATH_SAFE}-${TIMESTAMP}.bak"
    META_FILE="$META_DIR/${FILENAME}-${DIRPATH_SAFE}-${TIMESTAMP}.meta"

    cp "$FILE" "$BACKUP_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
        FILE_SIZE=$(stat -c%s "$FILE" 2>/dev/null)
        FILE_HASH=$(md5sum "$FILE" | awk '{print $1}')
        LINE_COUNT=$(wc -l < "$FILE" 2>/dev/null)
        BACKUP_TIME=$(date '+%Y-%m-%d %H:%M:%S')
        KOREAN_DATE=$(date '+%Y년 %m월 %d일 %a %H:%M:%S')

        PREV_BACKUP=$(ls -t "$BACKUP_DIR"/${FILENAME}-${DIRPATH_SAFE}-*.bak 2>/dev/null | head -2 | tail -1)

        DIFF_INFO="initial backup"
        if [ -n "$PREV_BACKUP" ] && [ -f "$PREV_BACKUP" ]; then
            DIFF_LINES=$(diff "$PREV_BACKUP" "$BACKUP_FILE" 2>/dev/null | grep -c "^[<>]" || echo "0")
            DIFF_INFO="${DIFF_LINES} lines modified"
        fi

        # JSON 메타 파일 생성 (변수 처리 최적화)
        PREV_BACKUP_NAME=$(basename "$PREV_BACKUP" 2>/dev/null || echo "")
        BACKUP_FILE_NAME=$(basename "$BACKUP_FILE")

        cat > "$META_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "original_path": "$RELPATH",
  "file_type": "$FILE_EXT",
  "source_directory": "$SOURCE_DIR",
  "backup_filename": "$BACKUP_FILE_NAME",
  "file_size_bytes": $FILE_SIZE,
  "total_lines": $LINE_COUNT,
  "md5_hash": "$FILE_HASH",
  "backup_datetime": "$BACKUP_TIME",
  "korean_date": "$KOREAN_DATE",
  "changes": "$DIFF_INFO",
  "previous_backup": "$PREV_BACKUP_NAME"
}
EOF

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${FILE_EXT^^}] Backed up: $RELPATH ($FILE_SIZE bytes)" >> "$LOG_FILE"
    fi
}

# MySQL 설정 백업
if [ -d "/etc/mysql" ]; then
    find /etc/mysql \( -name "*.cnf" \) -type f -mmin -10 2>/dev/null | while read FILE; do
        backup_file "$FILE" "/etc/mysql" "cnf"
    done
fi

# PHP 설정 백업
if [ -d "/etc/php" ]; then
    find /etc/php \( -name "*.ini" -o -name "*.conf" \) -type f -mmin -10 2>/dev/null | while read FILE; do
        EXT="${FILE##*.}"
        backup_file "$FILE" "/etc/php" "$EXT"
    done
fi

# Apache 설정 백업
if [ -d "/etc/apache2" ]; then
    find /etc/apache2 \( -name "*.conf" \) -type f -mmin -10 2>/dev/null | while read FILE; do
        backup_file "$FILE" "/etc/apache2" "conf"
    done
fi

# Custom Apache 설정 백업
if [ -d "/opt/apache/conf" ]; then
    find /opt/apache/conf \( -name "*.conf" \) -type f -mmin -10 2>/dev/null | while read FILE; do
        backup_file "$FILE" "/opt/apache/conf" "conf"
    done
fi

# 스케줄러 설정 백업
if [ -d "/home/scheduler/www/crontab" ]; then
    find /home/scheduler/www/crontab \( -name "*.conf" -o -name "*.php" \) -type f -mmin -10 2>/dev/null | while read FILE; do
        EXT="${FILE##*.}"
        backup_file "$FILE" "/home/scheduler/www/crontab" "$EXT"
    done
fi

# 10일 이상 경과 파일 삭제
DELETED=$(find "$BACKUP_DIR" -name "*.bak" -mtime +10 -delete -print 2>/dev/null | wc -l)
if [ $DELETED -gt 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deleted: $DELETED system config backup files" >> "$LOG_FILE"
    find "$META_DIR" -name "*.meta" -mtime +10 -delete 2>/dev/null
fi
