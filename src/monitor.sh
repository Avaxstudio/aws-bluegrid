#!/bin/bash

URL="https://gs-rest-service-qb95.onrender.com/greeting"
LOGFILE="service_monitor.log"
STATUS="UNKNOWN"
CHECK_INTERVAL=10
source .env




send_slack_notification() {
    local status="$1"
    local http_code="$2"
    local timestamp="$3"
    local emoji=""
    local message=""

    if [ "$status" == "DOWN" ]; then
        emoji=":rotating_light:"
    elif [ "$status" == "UP" ]; then
        emoji=":white_check_mark:"
    else
        emoji=":grey_question:"
    fi

    message="$emoji *Status:* $status\n*Time:* $timestamp\n*HTTP Code:* $http_code"

    curl -X POST -H 'Content-type: application/json' \
     --data "{\"text\": \"$message\"}" \
     "$SLACK_WEBHOOK_MONITOR"

}


echo "[$(date '+%Y-%m-%d %H:%M:%S')] Početak monitoringa: $URL" | tee -a "$LOGFILE"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    RESPONSE=$(curl -s -w "%{http_code}" -L --fail "$URL" -o tmp_response.txt)
    HTTP_CODE="$RESPONSE"

    if [ "$HTTP_CODE" -eq 200 ]; then
        NEW_STATUS="UP"
    else
        NEW_STATUS="DOWN"
    fi

    if [ "$STATUS" != "$NEW_STATUS" ]; then
        BODY=$(cat tmp_response.txt)
        echo "[$TIMESTAMP] 🔁 Status promenjen: $STATUS ➝ $NEW_STATUS (HTTP $HTTP_CODE)" | tee -a "$LOGFILE"
        echo "[$TIMESTAMP] 📦 Odgovor tela: $BODY" | tee -a "$LOGFILE"
        STATUS="$NEW_STATUS"
        send_slack_notification "$NEW_STATUS" "$HTTP_CODE" "$TIMESTAMP"
    fi

    sleep "$CHECK_INTERVAL"
done