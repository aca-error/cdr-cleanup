# cleanup-cdr
cleaner cdr files
📄 Disk Cleanup Utility for RHEL 9 - Installation & User Manual
📋 DAFTAR ISI
Overview

System Requirements

Installation Guide

Configuration

Usage Examples

Cron Job Setup

Systemd Service Setup

Troubleshooting

Security Considerations

Monitoring & Logging

1. OVERVIEW
Disk Cleanup Utility adalah script Bash yang dikembangkan khusus untuk RHEL 9 yang membantu mengelola penggunaan disk dengan aman. Script ini memiliki dua mode operasi utama:

🔧 Fitur Utama:
Dual Mode Operation: Disk Threshold & Age-Based Cleanup

Safety First: Minimum file count protection per directory

Security: Exclude hidden files & system directories secara default

Enterprise Ready: SELinux context preservation, journald logging

Comprehensive Logging: Start/end logs dengan duration tracking

🎯 Tujuan:
Mencegah disk full secara proaktif

Membersihkan file lama secara otomatis

Melindungi file-file penting pengguna

Menyediakan audit trail lengkap

2. SYSTEM REQUIREMENTS
Minimum Requirements:
OS: Red Hat Enterprise Linux 9 atau kompatibel

Bash: Version 4.0+

Tools: find, sort, stat, df, awk, mkdir, rm, cp

Recommended:
RAM: 512MB+

Storage: 100MB+ untuk log dan backup

Permissions: Root atau sudo access

Verify Requirements:
bash
# Cek RHEL version
cat /etc/redhat-release

# Cek bash version
bash --version

# Cek tools availability
for cmd in find sort stat df awk mkdir rm cp; do
    command -v $cmd >/dev/null && echo "✓ $cmd" || echo "✗ $cmd NOT FOUND"
done
3. INSTALLATION GUIDE
📥 Step 1: Download Script
bash
# Download script ke /usr/local/bin
sudo curl -o /usr/local/bin/disk-cleanup https://raw.githubusercontent.com/priyogunawan-aca/cleanup-cdr/main/cleanup-cdr.sh

# Atau copy dari local
sudo cp cleanup.sh /usr/local/bin/disk-cleanup
🔒 Step 2: Set Permissions
bash
# Set executable permission
sudo chmod +x /usr/local/bin/disk-cleanup

# Set ownership
sudo chown root:root /usr/local/bin/disk-cleanup

# Verify installation
ls -la /usr/local/bin/disk-cleanup
📁 Step 3: Create Log Directory
bash
# Buat directory untuk log (default: /home/cdrsbx)
sudo mkdir -p /home/cdrsbx
sudo chmod 755 /home/cdrsbx

# Atau buat directory custom
sudo mkdir -p /var/log/disk-cleanup
✅ Step 4: Verify Installation
bash
# Test help command
disk-cleanup --help

# Test dry-run
disk-cleanup --dry-run --threshold=90
4. CONFIGURATION
⚙️ Default Configuration:
bash
DIRECTORY="/home/cdrsbx"      # Target directory
THRESHOLD=90                  # Disk usage threshold (%)
MIN_FILE_COUNT=30             # Min files per directory
MAX_DELETE_PER_RUN=100        # Max files deleted per run
BACKUP_ENABLED=0              # Backup disabled by default
DRY_RUN=1                     # Safety first - dry run default
📝 Environment File (Optional):
Buat file /etc/default/disk-cleanup:

bash
# Disk Cleanup Configuration
CLEANUP_DIRECTORY="/home/cdrsbx"
CLEANUP_THRESHOLD=85
CLEANUP_MIN_FILES=20
CLEANUP_MAX_DELETE=500
CLEANUP_BACKUP_ENABLED=1
CLEANUP_BACKUP_DIR="/backup/deleted_files"
🛡️ SELinux Configuration:
bash
# Buat SELinux policy jika diperlukan
sudo semanage fcontext -a -t bin_t "/usr/local/bin/disk-cleanup"
sudo restorecon -v /usr/local/bin/disk-cleanup
5. USAGE EXAMPLES
🔍 Basic Usage:
bash
# 1. Help menu
disk-cleanup --help

# 2. Dry run - check what will be deleted
disk-cleanup --dry-run --threshold=85

# 3. Force cleanup with threshold 80%
disk-cleanup --force --threshold=80

# 4. Age-based cleanup (older than 180 days)
disk-cleanup --force --age-days=180

# 5. Age-based cleanup (older than 6 months)
disk-cleanup --force --age-months=6
🎯 Advanced Usage:
bash
# 1. Custom directory dengan backup
disk-cleanup --force --threshold=75 --directory=/var/log --backup

# 2. Debug mode untuk troubleshooting
disk-cleanup --force --threshold=85 --debug

# 3. Exclude pattern tambahan
disk-cleanup --force --threshold=80 --exclude="*.log" --exclude="backup/*"

# 4. Quiet mode untuk cron jobs
disk-cleanup --force --threshold=85 --quiet

# 5. Include hidden files (HATI-HATI!)
disk-cleanup --force --threshold=85 --include-hidden
📊 Mode Comparison:
Mode	Command	Use Case
Threshold	--threshold=85	Prevent disk full
Age-Based	--age-days=90	Compliance/retention
Debug	--debug	Troubleshooting
Quiet	--quiet	Cron jobs
6. CRON JOB SETUP
⏰ Contoh Cron Configuration:
bash
# Edit crontab
sudo crontab -e
📅 Cron Examples:
bash
# 1. Run daily at 2 AM dengan threshold 85%
0 2 * * * /usr/local/bin/disk-cleanup --force --threshold=85 --quiet

# 2. Run weekly (Sunday) untuk age-based cleanup
0 3 * * 0 /usr/local/bin/disk-cleanup --force --age-days=180 --quiet

# 3. Run every 6 hours dengan monitoring
0 */6 * * * /usr/local/bin/disk-cleanup --force --threshold=90 --quiet

# 4. With email notification on error
0 2 * * * /usr/local/bin/disk-cleanup --force --threshold=85 2>&1 | mail -s "Disk Cleanup Report" admin@example.com
📁 Cron Configuration File:
Buat file /etc/cron.d/disk-cleanup:

bash
# Disk Cleanup Cron Job
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# Run daily at 2 AM
0 2 * * * root /usr/local/bin/disk-cleanup --force --threshold=85 --quiet
7. SYSTEMD SERVICE SETUP
🔄 Create Service File:
Buat file /etc/systemd/system/disk-cleanup.service:

ini
[Unit]
Description=Disk Cleanup Service
After=network-online.target
Wants=network-online.target
Documentation=man:disk-cleanup(1)

[Service]
Type=oneshot
User=root
Group=root
EnvironmentFile=/etc/default/disk-cleanup
ExecStart=/usr/local/bin/disk-cleanup --force --threshold=${CLEANUP_THRESHOLD:-85} --min-files=${CLEANUP_MIN_FILES:-20} --max-delete=${CLEANUP_MAX_DELETE:-500}
StandardOutput=journal
StandardError=journal
LockPersonality=yes
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=/home/cdrsbx /backup
MemoryDenyWriteExecute=yes
RestrictRealtime=yes

[Install]
WantedBy=multi-user.target
⏰ Create Timer File:
Buat file /etc/systemd/system/disk-cleanup.timer:

ini
[Unit]
Description=Run Disk Cleanup Daily
Requires=disk-cleanup.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
🚀 Enable & Start Service:
bash
# Reload systemd
sudo systemctl daemon-reload

# Enable timer
sudo systemctl enable --now disk-cleanup.timer

# Check status
sudo systemctl status disk-cleanup.timer

# Manual run
sudo systemctl start disk-cleanup.service

# View logs
sudo journalctl -u disk-cleanup.service -f
8. TROUBLESHOOTING
🔍 Common Issues & Solutions:
Issue 1: "Script tidak menghapus file padahal disk sudah penuh"
bash
# Solusi:
# 1. Cek disk usage manual
df -h /home/cdrsbx

# 2. Run dengan debug mode
disk-cleanup --force --threshold=20 --debug --directory=/home/cdr

# 3. Cek apakah directory valid
ls -la /home/cdr
Issue 2: "Permission denied"
bash
# Solusi:
# 1. Cek permission script
ls -la /usr/local/bin/disk-cleanup

# 2. Cek permission directory target
ls -la /home/cdrsbx

# 3. Run sebagai root
sudo disk-cleanup --force --threshold=85
Issue 3: "SELinux blocking operations"
bash
# Solusi:
# 1. Check SELinux alerts
sudo ausearch -m avc -ts recent

# 2. Temporary disable untuk testing
sudo setenforce 0

# 3. Create proper policy
sudo audit2allow -a -M diskcleanup
sudo semodule -i diskcleanup.pp
Issue 4: "Script stuck atau terlalu lama"
bash
# Solusi:
# 1. Cek lock file
ls -la /var/lock/cdrsbx_cleanup.lock

# 2. Kill stale process
sudo rm -f /var/lock/cdrsbx_cleanup.lock

# 3. Reduce max delete limit
disk-cleanup --force --threshold=85 --max-delete=50
📋 Diagnostic Commands:
bash
# 1. Check script version
disk-cleanup --help | head -5

# 2. Test disk usage function
get_disk_usage() {
    df -P "$1" 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}
echo "Disk usage: $(get_disk_usage /home/cdr)%"

# 3. Check log file
tail -f /home/cdrsbx/cleanup.log

# 4. Verify exclude patterns
find /home/cdr -type f -name '.*' | wc -l
9. SECURITY CONSIDERATIONS
🔐 Default Security Features:
Exclude Hidden Files: Semua file/directory yang dimulai dengan . dikecualikan

System Directory Protection: Tidak boleh clean up /, /etc, /boot, dll

Minimum File Count: Minimal 30 file per directory tidak dihapus

Dry Run Default: Script default hanya simulasi

Security File Detection: Warning untuk file security-sensitive

⚠️ Important Notes:
Script harus dijalankan sebagai root atau dengan sudo

Backup diaktifkan hanya jika benar-benar diperlukan

Test dengan --dry-run sebelum --force

Review log file secara berkala

🔒 Security Best Practices:
bash
# 1. Regular log review
grep -i "error\|warning" /home/cdrsbx/cleanup.log

# 2. Monitor disk cleanup activity
sudo auditctl -w /usr/local/bin/disk-cleanup -p x

# 3. Regular backup verification
ls -la /backup/deleted_files/

# 4. Update script secara berkala
sudo curl -o /usr/local/bin/disk-cleanup https://new-version-url
10. MONITORING & LOGGING
📊 Log File Structure:
text
/home/cdrsbx/cleanup.log
├── START LOG (Timestamp, PID, Arguments)
├── CONFIGURATION (Settings)
├── PROCESS STEPS (Find, Filter, Delete)
├── END LOG (Duration, Summary)
└── ERROR/WARNING MESSAGES
👁️ Monitoring Examples:
bash
# 1. Last run summary
grep -A10 "DISK CLEANUP COMPLETED" /home/cdrsbx/cleanup.log | tail -15

# 2. Check duration
grep "Total Duration" /home/cdrsbx/cleanup.log

# 3. Count deleted files
grep -c "Deleted:" /home/cdrsbx/cleanup.log

# 4. Error statistics
grep -c "ERROR" /home/cdrsbx/cleanup.log

# 5. Generate daily report
awk '/DISK CLEANUP STARTED/,/DISK CLEANUP COMPLETED/' /home/cdrsbx/cleanup.log | tail -20
📈 Integration with Monitoring Tools:
Nagios/Icinga Plugin:
bash
#!/bin/bash
# check_disk_cleanup.sh
LOG="/home/cdrsbx/cleanup.log"
LAST_RUN=$(grep "DISK CLEANUP COMPLETED" "$LOG" | tail -1)

if [[ -z "$LAST_RUN" ]]; then
    echo "CRITICAL: Disk cleanup never run"
    exit 2
fi

# Parse last run time
if [[ $LAST_RUN =~ ([0-9-]+ [0-9:]+) ]]; then
    LAST_TIME="${BASH_REMATCH[1]}"
    LAST_EPOCH=$(date -d "$LAST_TIME" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date +%s)
    HOURS_DIFF=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))
    
    if [[ $HOURS_DIFF -gt 24 ]]; then
        echo "WARNING: Disk cleanup last run $HOURS_DIFF hours ago"
        exit 1
    else
        echo "OK: Disk cleanup running normally"
        exit 0
    fi
fi
Log Rotation Configuration:
Buat file /etc/logrotate.d/disk-cleanup:

bash
/home/cdrsbx/cleanup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /usr/bin/systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
📞 SUPPORT & CONTACT
Resources:
Documentation: /usr/share/doc/disk-cleanup/

Man Page: man disk-cleanup (jika diinstall)

GitHub Repository: https://github.com/priyogunawan-aca/cleanup-cdr

Issue Tracker: https://github.com/priyogunawan-aca/cleanup-cdr/issues

Emergency Procedures:
Stop All Cleanup: sudo pkill -f disk-cleanup

Restore Backup: cp -r /backup/deleted_files/ /original/path/

Disable Service: sudo systemctl disable disk-cleanup.timer

📄 APPENDIX
A. Exit Codes:
Code	Meaning	Action
0	Success	No action needed
1	General error	Check logs
2	Invalid arguments	Verify command
3	Permission denied	Check user/perms
4	Directory invalid	Verify target dir
5	Already running	Check lock file
B. File Locations:
Path	Purpose	Permission
/usr/local/bin/disk-cleanup	Main script	755 root:root
/home/cdrsbx/cleanup.log	Log file	644 root:root
/var/lock/cdrsbx_cleanup.lock	Lock file	644 root:root
/backup/deleted_files/	Backup directory	700 root:root
/etc/default/disk-cleanup	Configuration	600 root:root
C. Performance Tips:
Large Directories: Gunakan --max-delete=500 untuk batch processing

Network Storage: Tambah timeout untuk NFS/CIFS

High I/O: Schedule di jam sepi (2 AM)

Memory Usage: Monitor dengan ps aux | grep disk-cleanup

📅 Document Version: 1.0
🔄 Last Updated: January 2024
✅ Compatibility: RHEL 9+
👨‍💻 Author: System Administration Team

Note: Selalu test di environment staging sebelum production deployment. Backup data penting sebelum menjalankan cleanup operations.
