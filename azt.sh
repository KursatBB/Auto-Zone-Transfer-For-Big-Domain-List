#!/bin/bash

# Simple DNS zone transfer bash script for multiple domains with controlled parallel processing
# $1 is the file containing the list of domain names
# Max jobs limits the parallel processes

if [ -z "$1" ]; then
  echo "[*] Simple Zone Transfer script"
  echo "[*] Usage : $0 domain_list.txt"
  exit 0
fi

# Set the maximum number of parallel jobs
MAX_JOBS=5

# Function to perform zone transfer for a given domain
perform_zone_transfer() {
  local domain=$1
  echo "[*] Testing domain: $domain"
  
  # Identify the DNS servers for the domain
  for server in $(host -t ns $domain | cut -d " " -f4); do
    # For each of these servers, attempt a zone transfer
    echo "[*] Trying DNS server: $server for domain: $domain"
    host -l $domain $server | grep "has address" &
    
    # Limit the number of background jobs
    while (( $(jobs | wc -l) >= MAX_JOBS )); do
      sleep 0.5
    done
  done
}

# Iterate through each domain in the file and run zone transfer with controlled parallelism
while IFS= read -r domain; do
  perform_zone_transfer "$domain" &
  
  # Limit the number of background jobs
  while (( $(jobs | wc -l) >= MAX_JOBS )); do
    sleep 0.5
  done
done < "$1"

# Wait for all background processes to finish
wait

echo "[*] All tests completed."
