#!/bin/bash

# === CONFIGURATION ===
ABUSEIPDB_API_KEY="ee8318a44fea92403abb24b208a93818272bf0a4e806111fa949aa42fde1a3356874d391e3d64320"
LIST_PATH="/var/ossec/etc/lists/abuseipdb_blacklist"
WEB_IP_LIST="/var/www/html/blocked_ips.txt"
LOG_FILE="/var/log/abuseipdb_update.log"
TEMP_JSON="/tmp/abuseipdb_response.json"
TEMP_IPS="/tmp/abuseipdb_ips.txt"
TEMP_ALL="/tmp/combined_ips.txt"

# === LOG HEADER ===
echo "[`date '+%Y-%m-%d %H:%M:%S'`] Starting AbuseIPDB update..." >> "$LOG_FILE"

# === FETCH ABUSEIPDB JSON ===
echo "[*] Fetching from AbuseIPDB..."
curl -s "https://api.abuseipdb.com/api/v2/blacklist?maxAgeInDays=90&limit=1000" \
  -H "Key: $ABUSEIPDB_API_KEY" \
  -H "Accept: application/json" \
  -o "$TEMP_JSON"

if [ $? -ne 0 ]; then
    echo "[!] Failed to fetch AbuseIPDB data." | tee -a "$LOG_FILE"
    exit 1
fi

# === Extract IPs to temp file ===
jq -r '.data[].ipAddress' "$TEMP_JSON" > "$TEMP_IPS"

# === Update Wazuh CDB list ===
echo "[*] Updating Wazuh CDB list..."
touch "$LIST_PATH"
added_ips=0
while read -r ip; do
    if ! grep -q "${ip}:" "$LIST_PATH"; then
        echo "${ip}:" >> "$LIST_PATH"
        echo "  [+] New IP added to CDB: $ip" >> "$LOG_FILE"
        ((added_ips++))
    fi
done < "$TEMP_IPS"
chown wazuh:wazuh "$LIST_PATH"
chmod 660 "$LIST_PATH"

# === Update FortiGate IP list ===
echo "[*] Updating FortiGate IP list (deduplicated, max 10,000 IPs)..."
touch "$WEB_IP_LIST"
cat "$WEB_IP_LIST" "$TEMP_IPS" | sort -u > "$TEMP_ALL"
tail -n 10000 "$TEMP_ALL" > "$WEB_IP_LIST"
chmod 644 "$WEB_IP_LIST"

# === Restart Wazuh to apply CDB changes ===
echo "[*] Restarting Wazuh Manager..."
systemctl restart wazuh-manager

# === Cleanup ===
rm -f "$TEMP_JSON" "$TEMP_IPS" "$TEMP_ALL"

# === Final log entry ===
echo "[`date '+%Y-%m-%d %H:%M:%S'`] $added_ips new IPs added. Wazuh and FortiGate lists updated." >> "$LOG_FILE"
echo "[✓] Done. AbuseIPDB IPs updated."
