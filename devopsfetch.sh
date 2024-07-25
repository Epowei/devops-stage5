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


# Function to display active ports
display_ports() {
   echo -e "\035[1m| PORT       | HOST       | SERVICE   | USER       |\035[0m"
    echo "*************************************************"
    sudo netstat -tuln | awk 'NR>2 {split($4, a, ":"); port=a[length(a)]; host=a[length(a)-1]; print port, host, $1}' | while read -r port host protocol; do
        service=$(sudo lsof -i :"$port" | awk 'NR==2 {print $1}')
        user=$(sudo lsof -i :"$port" | awk 'NR==2 {print $3}')
        printf "| %-10s | %-10s | %-9s | %-10s |\n" "$port" "$host" "$service" "$user"
    done
}

# Display detailed information about a specific port
port_info() {
    echo -e "\033[1mDetails for Port $1:\035[0m"
    sudo lsof -i :"$1" | awk 'NR==1 {print "\033[1m| COMMAND | PID  | USER | FD  | TYPE | DEVICE | SIZE/OFF | NODE | NAME \033[0m"; next} {printf "| %-7s | %-4s | %-4s | %-3s | %-4s | %-6s | %-8s | %-4s | %-s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9}'
}
    
# Function to display Docker information
display_docker() {
    echo -e "\035[1mDocker Images:\033[0m"
    echo -e "\035[1m| REPOSITORY  | TAG       | IMAGE ID  | CREATED           | SIZE   |\035[0m"
    echo "*******************************************************************"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}"

    echo -e "\n\035[1mDocker Containers:\035[0m"
    echo -e "\035[1m| CONTAINER ID  | IMAGE     | COMMAND  | CREATED           | STATUS  | PORTS     | NAMES   |\035[0m"
    echo "----------------------------------------------------------------------------------------------"
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
}

container_details() {
    echo -e "\035[1mContainer details $1:\035[0m"
    echo -e "\035[1m| CONTAINER ID  | IMAGE     | NAME      | STATUS   | IP ADDRESS   |\035[0m"
    echo "------------------------------------------------------------"
    docker inspect "$1" --format "table {{.Id}}\t{{.Image}}\t{{.Name}}\t{{.State.Status}}\t{{.NetworkSettings.IPAddress}}"
}

# Display all Nginx domains and their ports
nginx_info() {
    echo -e "\035[1m| NGINX DOMAIN                   | PORT     | HOST       |\035[0m"
    echo "--------------------------------------------------------"
    sudo nginx -T 2>/dev/null | awk '
    /server_name/ {server_name=$2}
    /listen/ {port=$2; host="localhost"; if (server_name) {printf "| %-30s | %-8s | %-10s |\n", server_name, port, host; server_name=""}}'
}

# Detailed configuration information for a specific domain
domain_info() {
    echo -e "\035[1mNginx Configuration for Domain $1:\035[0m"
    sudo nginx -T 2>/dev/null | awk "/server_name $1/,/}/" | sed 's/^\s*//'
}

# List all users and their last login times
users_logins() {
    echo -e "\035[1m| USERNAME  | PORT  | LAST LOGIN      |\035[0m"
    echo "--------------------------------------"
    lastlog | awk 'NR==1 {next} {printf "| %-9s | %-5s | %-s %-s %-s |\n", $1, $2, $3, $4, $5}'
}

# Detailed information about a specific user
user_info() {
    echo -e "\035[1mDetails for User $1:\035[0m"
    id "$1" | awk -F ' ' '{printf "User ID: %-10s\nGroup ID: %-10s\nGroups: %-s\n", $1, $2, $3}'
    echo -e "\nLast Login Info:"
    lastlog | grep "$1" | awk '{print "Last Login: " $3" "$4" "$5}'
}

# Display activities within a specified time range
time_range() {
    echo -e "\035[1m| TIMESTAMP                   | USER  | ACTIVITY               |\035[0m"
    echo "---------------------------------------------------------------"
    journalctl --since="$1" --until="$2" --output=short-iso | while read line; do
        timestamp=$(echo $line | awk '{print $1, $2}')
        user=$(echo $line | awk '{print $6}')
        activity=$(echo $line | awk '{print $7, $8, $9, $10}')
        printf "| %-26s | %-5s | %-20s |\n" "$timestamp" "$user" "$activity"
    done
}

# Main logic
if [ $# -eq 0 ]; then
    display_help
    exit 1
fi

# Parse Command-line Arguments
case $1 in
    -p|--port)
        if [ -z "$2" ]; then
            display_ports
        else
            port_info "$2"
        fi
        ;;
    -d|--docker)
        if [ -z "$2" ]; then
            display_docker
        else
            container_details "$2"
        fi
        ;;
    -n|--nginx)
        if [ -z "$2" ]; then
            nginx_info
        else
            domain_info "$2"
        fi
        ;;
    -u|--users)
        if [ -z "$2" ]; then
            user_logins
        else
            user_info "$2"
        fi
        ;;
    -t|--time)
        if [ -z "$2" ] || [ -z "$3]"; then
            echo "Please provide a valid time range."
            exit 1
        else
            time_range "$2" "$3"
        fi
        ;;
    -h|--help)
        help
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac
