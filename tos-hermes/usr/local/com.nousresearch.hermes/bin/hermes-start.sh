#!/bin/bash
# Hermes AI Agent - TOS 7 启动脚本
# 通过 Unix Socket 提供 HTTP 服务，由 TOS 平台代理转发

set -e

LOG_DIR="/var/log/com.nousresearch.hermes"
LOG_FILE="${LOG_DIR}/hermes.log"
PID_FILE="/var/run/com.nousresearch.hermes/hermes.pid"
SOCKET_FILE="/var/api/com.nousresearch.hermes.sock"

APP_DIR="/usr/local/com.nousresearch.hermes"
DATA_DIR="/usr/local/com.nousresearch.hermes/data"
VENV_DIR="${DATA_DIR}/venv"
WEBUI_DIR="${DATA_DIR}/hermes-webui"
WORKSPACE_DIR="${DATA_DIR}/workspace"

PYTHON="${VENV_DIR}/bin/python3"
SERVER_SCRIPT="${WEBUI_DIR}/server.py"

mkdir -p "${LOG_DIR}" "$(dirname "${PID_FILE}")" "$(dirname "${SOCKET_FILE}")" "${DATA_DIR}" "${WORKSPACE_DIR}"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

diagnose_env() {
    log_msg "=== 启动前诊断 ==="
    log_msg "APP_DIR=${APP_DIR}"
    log_msg "DATA_DIR=${DATA_DIR}"
    log_msg "VENV_DIR=${VENV_DIR}"
    log_msg "WEBUI_DIR=${WEBUI_DIR}"
    log_msg "USER=$(whoami 2>/dev/null || echo unknown)"

    if [ ! -f "${PYTHON}" ]; then
        log_msg "ERROR: Python venv not found at ${PYTHON}"
        return 1
    fi
    log_msg "Python: $( "${PYTHON}" --version 2>&1 )"

    if [ ! -f "${SERVER_SCRIPT}" ]; then
        log_msg "ERROR: server.py not found at ${SERVER_SCRIPT}"
        return 1
    fi

    if ! "${PYTHON}" -c "import agent" 2>/dev/null; then
        log_msg "ERROR: hermes-agent module not found"
        return 1
    fi
    log_msg "Module 'agent' OK"

    log_msg "=== 诊断完成 ==="
    return 0
}

start_process() {
    if [ -f "${PID_FILE}" ] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
        log_msg "Hermes is already running"
        return 0
    fi

    if ! diagnose_env; then
        return 1
    fi

    log_msg "Starting Hermes on Unix socket ${SOCKET_FILE} ..."

    rm -f "${SOCKET_FILE}"

    export HERMES_HOME="${DATA_DIR}"
    export PYTHONUNBUFFERED=1
    export HERMES_WEBUI_HOST="0.0.0.0"
    export HERMES_WEBUI_PORT="8787"
    export HERMES_WEBUI_DEFAULT_WORKSPACE="${WORKSPACE_DIR}"
    export HERMES_WEBUI_STATE_DIR="${DATA_DIR}/webui"
    export HERMES_UNIX_SOCKET="${SOCKET_FILE}"

    mkdir -p "${DATA_DIR}/webui/sessions"

    cd "${WEBUI_DIR}"
    nohup "${PYTHON}" "${SERVER_SCRIPT}" >> "${LOG_FILE}" 2>&1 &
    local pid=$!
    echo "${pid}" > "${PID_FILE}"
    log_msg "Started with PID: ${pid}"

    sleep 2
    if kill -0 "${pid}" 2>/dev/null; then
        log_msg "Process verified running"
        chmod 0660 "${SOCKET_FILE}" 2>/dev/null || true
        chown hermes:hermes "${SOCKET_FILE}" 2>/dev/null || true
        return 0
    else
        log_msg "ERROR: Process exited immediately!"
        tail -20 "${LOG_FILE}"
        rm -f "${PID_FILE}"
        return 1
    fi
}

stop_process() {
    log_msg "Stopping Hermes ..."
    if [ -f "${PID_FILE}" ]; then
        local pid
        pid=$(cat "${PID_FILE}" 2>/dev/null)
        if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
            kill -TERM "${pid}" 2>/dev/null || true
            local count=0
            while kill -0 "${pid}" 2>/dev/null && [ "${count}" -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            if kill -0 "${pid}" 2>/dev/null; then
                kill -KILL "${pid}" 2>/dev/null || true
            fi
        fi
        rm -f "${PID_FILE}"
    fi
    rm -f "${SOCKET_FILE}"
    pkill -f "hermes-webui/server.py" 2>/dev/null || true
    log_msg "Stopped"
}

status() {
    if [ -f "${PID_FILE}" ] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
        return 0
    fi
    return 1
}

case "$1" in
    start)
        start_process
        ;;
    stop)
        stop_process
        ;;
    restart)
        stop_process
        sleep 1
        start_process
        ;;
    status)
        if status; then
            echo "Hermes is running"
            exit 0
        else
            echo "Hermes is not running"
            exit 3
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
