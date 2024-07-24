#!/bin/bash

# devopsfetch.sh

# Function to display help
display_help() {
    echo "Usage: devopsfetch.sh [OPTION]..."
    echo "Collect and display system information for DevOps purposes."
    echo
    echo "Options:"
    echo "  -p, --port [PORT]      Display active ports or specific port info"
    echo "  -d, --docker [NAME]    Display Docker images/containers or specific container info"
    echo "  -n, --nginx [DOMAIN]   Display Nginx domains or specific domain config"
    echo "  -u, --users [USER]     Display user logins or specific user info"
    echo "  -t, --time RANGE       Display activities within a time range (e.g., '1 hour ago')"
    echo "  -h, --help             Display this help message"
    echo
    echo "Examples:"
    echo "  devopsfetch.sh -p                  # List all active ports"
    echo "  devopsfetch.sh -p 80               # Show details for port 80"
    echo "  devopsfetch.sh -d                  # List all Docker images and containers"
    echo "  devopsfetch.sh -d my-container     # Show details for 'my-container'"
    echo "  devopsfetch.sh -n                  # List all Nginx domains"
    echo "  devopsfetch.sh -n example.com      # Show config for example.com"
    echo "  devopsfetch.sh -u                  # List all users and last logins"
    echo "  devopsfetch.sh -u johndoe          # Show details for user 'johndoe'"
    echo "  devopsfetch.sh -t '1 hour ago'     # Show activities in the last hour"
}

# Function to format output as a table
format_table() {
    column -t -s $'\t'
}

# Function to display active ports
display_ports() {
    printf "%-15s %-5s %-8s\n" "USER" "PORT" "SERVICE"
    
    if [ -z "$1" ]; then
        sudo lsof -i -P -n | grep LISTEN | awk '{
            port = $9
            sub(/.*:/, "", port)
            user = $3
            service = $1
            if (length(service) > 8) service = substr(service, 1, 8)
            printf "%-15s %-5s %-8s\n", user, port, service
        }' | sort -k2 -n | uniq
    else
        echo "Information for port $1:"
        result=$(sudo lsof -i :$1 -P -n | grep LISTEN | awk '{
            port = $9
            sub(/.*:/, "", port)
            user = $3
            service = $1
            if (length(service) > 8) service = substr(service, 1, 8)
            printf "%-15s %-5s %-8s\n", user, port, service
        }')
        if [ -z "$result" ]; then
            echo "No service found on port $1"
        else
            echo "$result"
        fi
    fi
}

# Function to display Docker information
display_docker() {
    if [ -z "$1" ]; then
         echo "****************************** Docker Images ******************************"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | format_table
        echo -e "\nDocker Containers:"
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | format_table
    else
        echo "Container '$1' Details:"
        docker inspect $1 | jq '.[0] | {Name: .Name, Image: .Config.Image, State: .State.Status, Ports: .NetworkSettings.Ports}'
    fi
}

# Function to display Nginx information
display_nginx() {
    if [ -z "$1" ]; then
        echo "****************************** Nginx Domains and Ports ******************************"
        grep -h server_name /etc/nginx/sites-enabled/* | awk '{print $2}' | sed 's/;$//' | \
        while read domain; do
            port=$(grep -h "listen " /etc/nginx/sites-enabled/* | grep -v "[::]" | awk '{print $2}' | sed 's/;$//' | head -1)
            echo -e "$domain\t$port"
        done | format_table
    else
        echo "Nginx Configuration for $1:"
        grep -rl "server_name $1" /etc/nginx/sites-enabled | xargs cat
    fi
}

# Function to display user information
display_users() {
    if [ -z "$1" ]; then
        echo "Users and Last Login Times:"
        last -w | awk '!seen[$1]++ {print $1, $3, $4, $5, $6, $7}' | format_table
    else
        echo "User '$1' Details:"
        id $1
        echo "Last Login:"
        last $1 | head -1
    fi
}

# Function to display system logs based on a specific date or date range
display_system_logs() {
    local start_date=$1
    local end_date=$2

    if [ -z "$end_date" ]; then
        # If only one date is provided, assume it's the start date and set end date to now
        end_date="now"
    fi

    echo "Displaying system logs from $start_date to $end_date:"
    journalctl --since "$start_date" --until "$end_date" | less
}

# Main logic
if [ $# -eq 0 ]; then
    display_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            display_ports "$2"
            shift 2
            ;;
        -d|--docker)
            display_docker "$2"
            shift 2
            ;;
        -n|--nginx)
            display_nginx "$2"
            shift 2
            ;;
        -u|--users)
            display_users "$2"
            shift 2
            ;;
        -t|--time)
        if [ -z "$3" ]; then
            display_system_logs "$2"
        else
            display_system_logs "$2" "$3"
        fi
        ;;
        -h|--help)
            display_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            display_help
            exit 1
            ;;
    esac
done
