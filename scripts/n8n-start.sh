#!/bin/bash
# Start n8n service
systemctl --user start n8n.service
echo "n8n starting..."
sleep 2
systemctl --user status n8n.service --no-pager
