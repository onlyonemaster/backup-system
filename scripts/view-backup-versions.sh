#!/bin/bash
# 백업 파일 버전 조회 도구

KIAMPHP_BACKUP_DIR="/disk/backup/edit/kiamphp"
KIAMPHP_META_DIR="$KIAMPHP_BACKUP_DIR/.meta"
SYSTEM_BACKUP_DIR="/disk/backup/edit/system"
SYSTEM_META_DIR="$SYSTEM_BACKUP_DIR/.meta"

if [ -z "$1" ]; then
    echo "사용법: $0 <파일명> [latest|diff|all]"
    echo ""
    echo "예시:"
    echo "  $0 index.php                    # 모든 버전 조회"
    echo "  $0 index.php latest             # 최신 버전만 조회"
    echo "  $0 mysqld.cnf diff              # 최신 2개 버전 비교"
    exit 1
fi

FILENAME="$1"
ACTION="${2:-all}"
SEARCH_PATTERN="${FILENAME%.*}-*"

# PHP 백업인지 설정 백업인지 판단
if ls "$KIAMPHP_BACKUP_DIR"/${SEARCH_PATTERN}.bak &>/dev/null; then
    BACKUP_DIR="$KIAMPHP_BACKUP_DIR"
    META_DIR="$KIAMPHP_META_DIR"
    TYPE="PHP"
elif ls "$SYSTEM_BACKUP_DIR"/${SEARCH_PATTERN}.bak &>/dev/null; then
    BACKUP_DIR="$SYSTEM_BACKUP_DIR"
    META_DIR="$SYSTEM_META_DIR"
    TYPE="CONFIG"
else
    echo "오류: '$FILENAME'에 대한 백업을 찾을 수 없습니다."
    exit 1
fi

echo "📚 $FILENAME 의 백업 버전 목록 ($TYPE)"
echo "======================================="
echo ""

# 백업 파일 목록 가져오기 (최신순)
BACKUPS=($(ls -t "$BACKUP_DIR"/${SEARCH_PATTERN}.bak 2>/dev/null))
TOTAL=${#BACKUPS[@]}

if [ $TOTAL -eq 0 ]; then
    echo "백업이 없습니다."
    exit 1
fi

case "$ACTION" in
    latest)
        # 최신 1개만 표시
        LATEST="${BACKUPS[0]}"
        BASENAME=$(basename "$LATEST")
        TIMESTAMP=$(echo "$BASENAME" | grep -oE '[0-9]{8}-[0-9]{6}')

        if [ -f "$META_DIR/${BASENAME%.bak}.meta" ]; then
            echo "최신 버전:"
            echo ""
            cat "$META_DIR/${BASENAME%.bak}.meta" | python3 -m json.tool 2>/dev/null || \
            cat "$META_DIR/${BASENAME%.bak}.meta"
        else
            echo "메타 정보를 찾을 수 없습니다."
        fi
        ;;

    diff)
        # 최신 2개 버전 비교
        if [ $TOTAL -lt 2 ]; then
            echo "비교할 이전 버전이 없습니다. (현재 버전: 1개)"
            exit 1
        fi

        LATEST="${BACKUPS[0]}"
        PREVIOUS="${BACKUPS[1]}"

        echo "최신 2개 버전 비교:"
        echo ""
        echo "=== 최신 버전 ==="
        diff "$PREVIOUS" "$LATEST" || true
        ;;

    *)
        # 모든 버전 표시
        for ((i=0; i<TOTAL; i++)); do
            BACKUP="${BACKUPS[$i]}"
            BASENAME=$(basename "$BACKUP")
            TIMESTAMP=$(echo "$BASENAME" | grep -oE '[0-9]{8}-[0-9]{6}')

            if [ -f "$META_DIR/${BASENAME%.bak}.meta" ]; then
                SIZE=$(jq -r '.file_size_bytes' "$META_DIR/${BASENAME%.bak}.meta" 2>/dev/null || echo "?")
                LINES=$(jq -r '.total_lines' "$META_DIR/${BASENAME%.bak}.meta" 2>/dev/null || echo "?")
                HASH=$(jq -r '.md5_hash' "$META_DIR/${BASENAME%.bak}.meta" 2>/dev/null || echo "?")
                CHANGES=$(jq -r '.changes' "$META_DIR/${BASENAME%.bak}.meta" 2>/dev/null || echo "?")

                echo "[$((i+1))] $TIMESTAMP"
                echo "    크기: $SIZE bytes | 라인: $LINES | MD5: ${HASH:0:10}..."
                echo "    변경: $CHANGES"
                echo "    파일: $BASENAME"
                echo ""
            fi
        done
        echo "총 $TOTAL 개의 백업 버전이 있습니다."
        ;;
esac
