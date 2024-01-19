#!/bin/bash

login() {
    # change users here
    local ip=$1
    shift
    for user in $@; do
        # Attempt to login using sshpass and print the user if successful
        sshpass -p "$DEFAULT_PASSWORD" ssh -o "StrictHostKeyChecking no" $user@$ip exit >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            # minor bug in that this will mess with ips that start with ours
            # ie 192.168.10.10 and 192.168.10.101 collide
            echo "Successfully logged in as $user to $ip"
            sed -i "/^$1/s/#/ user=$user\t#/" $HOSTS
            break
        fi
    done
}
export -f login

get_hosts() {
    # Store the ips
    IPS=()

    # Store the [linux] and [windows] headers in variables
    linux_header="[linux]"
    windows_header="[windows]"

    # Read the file line by line
    while read -r line
    do
        # Check if the line contains the [linux] header
        if [[ $line == *"$linux_header"* ]]; then
            # Set a flag to indicate that the next IP addresses are under the [linux] header
            linux_flag=true
            windows_flag=false
        fi

        # Check if the line contains the [windows] header
        if [[ $line == *"$windows_header"* ]]; then
            # Set a flag to indicate that the next IP addresses are under the [windows] header
            linux_flag=false
            windows_flag=true
        fi

        # If the line does not contain any header and the flag is set to true for the [linux] header
        if [[ $line != *"$linux_header"* && $line != *"$windows_header"* && $linux_flag == true && $windows_flag == false ]]; then
            # Extract the IP address from the line using awk
            ip_address=$(echo $line | awk '{print $1}')
            IPS+=($ip_address)
    fi

    done < "$HOSTS"
    export IPS
}

HOSTS=""
DEFAULT_PASSWORD=""
USERS=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--inventory) export HOSTS="$2"; shift ;;
        -p|--password) export DEFAULT_PASSWORD="$2"; shift ;;
        -u|--user) USERS+=("$2"); shift ;;
        -h|--help)
            echo "Usage: ./script.sh [OPTIONS]"
            echo
            echo "Options:"
            echo "  -i, --inventory HOSTFILE     Set the inventory file for hosts"
            echo "  -h, --help                   Show this help message and exit"
            echo "  -p, --password PASSWORD      Set the default password for all hosts"
            echo "  -u, --user USERNAME          Add a user to the list of users to configure"
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

# check if HOSTS is empty
if [[ -z "$HOSTS" ]]; then
    echo "Error: HOSTS variable is empty"
    exit 1
fi

# check if USERS is empty
if [[ ${#USERS[@]} -eq 0 ]]; then
    echo "Error: USERS array is empty"
    exit 1
fi

# check if DEFAULT_PASSWORD is empty
if [[ -z "$DEFAULT_PASSWORD" ]]; then
    echo "Error: DEFAULT_PASSWORD variable is empty"
    exit 1
fi

get_hosts
printf "%s\n" "${IPS[@]}" | parallel -j0 -N1 login {} ${USERS[@]}
