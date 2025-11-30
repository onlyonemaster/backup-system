#!/bin/bash
# PHP 파일 백업 스크립트 (메타정보 포함)

BACKUP_DIR="/disk/backup/edit/kiamphp"
SOURCE_DIR="/home/kiam"
LOG_FILE="/var/log/backup-kiamphp.log"
META_DIR="$BACKUP_DIR/.meta"

mkdir -p "$BACKUP_DIR" "$META_DIR"

# 최근 10분 내 수정된 PHP 파일 찾기
find "$SOURCE_DIR" -name '*.php' -type f -mmin -10 2>/dev/null | while read FILE; do

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    RELPATH=${FILE#$SOURCE_DIR/}
    FILENAME=$(basename "$FILE")
    DIRPATH=$(dirname "$RELPATH")
    DIRPATH_SAFE=${DIRPATH//\//_}

    # 백업 파일명
    BACKUP_FILE="$BACKUP_DIR/${FILENAME}-${DIRPATH_SAFE}-${TIMESTAMP}.bak"
    META_FILE="$META_DIR/${FILENAME}-${DIRPATH_SAFE}-${TIMESTAMP}.meta"

    # 파일 복사
    cp "$FILE" "$BACKUP_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
        # 메타 정보 수집
        FILE_SIZE=$(stat -c%s "$FILE" 2>/dev/null)
        FILE_HASH=$(md5sum "$FILE" | awk '{print $1}')
        LINE_COUNT=$(wc -l < "$FILE" 2>/dev/null)
        BACKUP_TIME=$(date '+%Y-%m-%d %H:%M:%S')
        KOREAN_DATE=$(date '+%Y년 %m월 %d일 %a %I:%M:%S %p')

        # 이전 백업 찾기
        PREV_BACKUP=$(ls -t "$BACKUP_DIR"/${FILENAME}-${DIRPATH_SAFE}-*.bak 2>/dev/null | head -2 | tail -1)

        # 이전 버전과의 차이
        DIFF_INFO="initial backup"
        if [ -n "$PREV_BACKUP" ] && [ -f "$PREV_BACKUP" ]; then
            DIFF_LINES=$(diff "$PREV_BACKUP" "$BACKUP_FILE" 2>/dev/null | grep -c "^[<>]" || echo "0")
            DIFF_INFO="$DIFF_LINES lines modified"
        fi

        # JSON 메타 파일 생성
        cat > "$META_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "original_path": "$RELPATH",
  "file_type": "php",
  "source_directory": "$SOURCE_DIR",
  "backup_filename": "$(basename $BACKUP_FILE)",
  "file_size_bytes": $FILE_SIZE,
  "total_lines": $LINE_COUNT,
  "md5_hash": "$FILE_HASH",
  "backup_datetime": "$BACKUP_TIME",
  "korean_date": "$KOREAN_DATE",
  "changes": "$DIFF_INFO",
  "previous_backup": "$(basename $PREV_BACKUP)"
}
EOF

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PHP] Backed up: $RELPATH ($FILE_SIZE bytes, $LINE_COUNT lines)" >> "$LOG_FILE"
    fi

done

# 10일 이상 경과 파일 삭제
DELETED=$(find "$BACKUP_DIR" -name "*.bak" -mtime +10 -delete -print 2>/dev/null | wc -l)
if [ $DELETED -gt 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deleted: $DELETED PHP backup files" >> "$LOG_FILE"
    find "$META_DIR" -name "*.meta" -mtime +10 -delete 2>/dev/null
fi
