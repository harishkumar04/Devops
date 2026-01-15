#!/bin/bash

echo "        SYSTEM INFORMATION REPORT       "
echo "========================================"

if [ -f /etc/os-release ]; then
    OS_NAME=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
    OS_VERSION=$(grep "^VERSION=" /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS_NAME="Unknown"
    OS_VERSION="Unknown"
fi

KERNEL_VERSION=$(uname -r)

UPTIME=$(uptime -p)

CPU_MODEL=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
CPU_CORES=$(nproc)

MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

DISK_USAGE=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

echo "OS Name        : $OS_NAME"
echo "OS Version     : $OS_VERSION"
echo "Kernel Version : $KERNEL_VERSION"
echo "Uptime         : $UPTIME"
echo "CPU Model      : $CPU_MODEL"
echo "CPU Cores      : $CPU_CORES"
echo "Memory Usage   : $MEMORY_USAGE"
echo "Disk Usage     : $DISK_USAGE"

echo
echo "========================================"
echo "Report generated on: $(date)"
