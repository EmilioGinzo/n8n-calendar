#!/bin/bash
# Restart n8n service
systemctl --user restart n8n.service
echo "n8n restarting..."
sleep 2
systemctl --user status n8n.service --no-pager
