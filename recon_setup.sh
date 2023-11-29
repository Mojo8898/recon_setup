#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <machine_name> <ip_address> <vpn_full_path>"
    exit 1
fi

session=$1
ip=$2
vpn=$3

mkdir -p /home/kali/htb/machines/$session/nmap && cd /home/kali/htb/machines/$session

# Start tmux session
tmux new-session -d -s $session
tmux set-environment -t $session IP "$ip"
tmux set-environment -t $session SESSION "$session"
tmux send-keys -t $session:0 "clear" C-m

# Connect to VPN
tmux rename-window -t $session:0 "openvpn"
tmux send-keys -t $session:0 "sudo openvpn $vpn" C-m

# Create new window
tmux new-window -t $session -n $ip

# Verify connection
tmux send-keys -t $session:1 "clear" C-m
tmux send-keys -t $session:1 "echo 'Waiting on connection to VPN/host...' && until ping -c1 $ip > /dev/null 2>&1; do sleep .5; done" C-m

# Run nmap scans
tmux send-keys -t $session:1 "clear" C-m
tmux send-keys -t $session:1 "sudo nmap -p- --min-rate=1000 -oN nmap/$session-allports.nmap -v $ip && echo '\n<=================================================================================>\n' && sudo nmap -sC -sV -oN nmap/$session-tcp.nmap -p \$(cat nmap/$session-allports.nmap | grep '^[0-9]' | awk '/open/{print \$1}' | cut -d '/' -f 1  | paste -sd,) $ip && echo '\n<=================================================================================>\n' && sudo nmap -sU --top-ports=200 -oN nmap/$session-udp.nmap -v $ip" C-m

tmux attach -t $session