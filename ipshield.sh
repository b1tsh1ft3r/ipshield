#!/bin/bash

readonly log_file="/var/log/ipshield.log"
readonly blacklist="/opt/ipshield/black.list"

readonly opendbl_url="https://opendbl.net/lists/"
readonly opendbl_files=("etknown.list" "tor-exit.list" "bruteforce.list" "blocklistde-all.list" "talos.list" "dshield.list" "sslblock.list")

readonly ipdeny_url="https://www.ipdeny.com/ipblocks/data/countries/"
readonly ipdeny_files=("cn.zone" "ru.zone" "tr.zone" "br.zone" "in.zone" "np.zone" "ro.zone" "af.zone") # china | russia | turkey | brazil | india | nepal | romania | afghanistan

#####################################################################################
# Error handling
#####################################################################################
log_error() 
{ 
    local timestamp=$(date); 
    echo "$timestamp: Error - $1" >> "$log_file" 
}

#####################################################################################
# Download lists
#####################################################################################
download_lists() 
{
    if [ ! -d "/opt/ipshield/blacklists" ]; then
        mkdir -p "/opt/ipshield/blacklists"
    fi
    
    # OpenDBL Lists
    for filename in "${opendbl_files[@]}"; do
        url="${opendbl_url}${filename}"
        if wget -q -N "$url" -P "/opt/ipshield/blacklists/"; then
            echo "$(date): Downloaded $filename" >> "$log_file"
        else
            log_error "Failed to download $filename from $url"
        fi
    done

    # IPDeny Country Lists
    for filename in "${ipdeny_files[@]}"; do
      url="${ipdeny_url}${filename}"
    if wget -q -N "$url" -P "/opt/ipshield/blacklists/"; then
            echo "$(date): Downloaded $filename" >> "$log_file"
        else
            log_error "Failed to download $filename from $url"
        fi
    done
}

#####################################################################################
# Create blacklist
#####################################################################################
function create_blacklist()
{
    echo "Creating blacklist..." >> "$log_file"
    cat /opt/ipshield/blacklists/*.list > /opt/ipshield/black.list
    cat /opt/ipshield/blacklists/*.zone >> /opt/ipshield/black.list
    sed -i '/^#/d' /opt/ipshield/black.list                # remove comments from blacklist file
    sed -i 's/^/add blacklist /' /opt/ipshield/black.list  # append required data to start of each line
}

#####################################################################################
# Load blacklist
#####################################################################################
function load_blacklist() 
{
    echo "Loading blacklist..." >> "$log_file"

    if iptables -nvL | grep -q "match-set blacklist"; then
        iptables -D INPUT -m set --match-set blacklist src -j DROP
        sleep 2
    fi

    ipset destroy blacklist                                # remove any existing blacklist
    ipset -N blacklist iphash                              # create a blank blacklist
    sleep 2
    ipset restore < /opt/ipshield/black.list               # load the black.list file

    # Check if the rule exists in the INPUT chain of iptables
    if ! iptables -C INPUT -m set --match-set blacklist src -j DROP &>/dev/null; then
        iptables -I INPUT 1 -m set --match-set blacklist src -j DROP
    fi

    total=$(cat /opt/ipshield/black.list | wc -l)          # count number of entries
    echo "Loaded $total IPs"                               # Print total number of IPs loaded   
}

#####################################################################################
# Main
#####################################################################################
function main 
{
    timestamp=$(date)
    echo "$timestamp: Updating blacklists..." >> "$log_file"
    
    download_lists         # Download blacklists
    create_blacklist       # Combine all lists into one
    load_blacklist         # Load blacklist file

    timestamp=$(date)
    echo "$timestamp: Blacklist update complete!" >> "$log_file"
    echo "--------------------------------------------------------------------" >> "$log_file"
}

    main "$@"
