#!/bin/bash

backup_system_enable_from_recovery() {

    # === 1. Убедимся, что /recovery жив ===
    if ! mountpoint -q /recovery; then
        local RECOV_PART=$(findmnt -n -o SOURCE /recovery 2>/dev/null || blkid -L quasar-recovery || find /dev -name "*recovery*" 2>/dev/null | head -1 || { echo "No recovery partition"; exit 1; })
        mount "$RECOV_PART" /recovery
    fi
    mount -o remount,rw /recovery

    # === 2. Путь бэкапа ===
    local BACKUP_DIR="/recovery/usr/backup"
    mkdir -p "$BACKUP_DIR"

    # === 3. rsync чистой системы ===
    rsync -aAXHx --numeric-ids \
    --exclude={'/dev/*','/proc/*','/sys/*','/tmp/*','/run/*','/mnt/*','/media/*','/lost+found'} \
    --exclude='/recovery' \
    --exclude='/post' \
    --exclude='/regions' \
    --exclude='/home/*/.cache/*' \
    / "$BACKUP_DIR/"

    # === 4. Метаданные для QuasarRecovery ===
    cat > "$BACKUP_DIR/recovery.info" <<EOF
type=quasar-system-backup
version=1
created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source=QuasarInstall-postinstall
EOF

    sync
    mount -o remount,ro /recovery
}

backup_system_enable() {
    local BACKUP_DIR="/usr/backup/"
    mkdir -p "$BACKUP_DIR"

    # === 3. rsync чистой системы ===
    rsync -aAXHx --numeric-ids \
    --exclude={'/dev/*','/proc/*','/sys/*','/tmp/*','/run/*','/mnt/*','/media/*','/lost+found'} \
    --exclude='/recovery' \
    --exclude='/home/*/.cache/*' \
    / "$BACKUP_DIR/"

}

Backup=$(dialog --title "quasar-post-install" --menu "Сделать точку восстановления? " 15 70 8 \
    1 "С интеграцией с Recovery (rsync)" \
    2 "Создать простой Backup (rsync)" \
    3 "нет" \
    3>&1 1>&2 2>&3)

case "$Backup" in
    1) backup_system_enable_from_recovery ;;
    2) backup_system_enable ;;
    3|"") echo "Отмена или выход" ;;
esac
