MATRIX_HOST="<server-url>"
BEARER_TOKEN="<token-here>"

list_users() {
  echo "Retrieving list of users..."
  curl -X GET "https://${MATRIX_HOST}/_synapse/admin/v2/users" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" | jq .
}

list_tokens() {
  echo "Retrieving list of tokens..."
  curl -X GET "https://${MATRIX_HOST}/_synapse/admin/v1/registration_tokens" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" | jq .
}

create_token() {
  curl -X POST "https://${MATRIX_HOST}/_synapse/admin/v1/registration_tokens/new" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
                "uses_allowed": 1
              }' | jq
}

create_user() {
  read -p "Enter user ID (format: @username:server): " user_id
  read -p "Enter password: " user_password
  read -p "Enter display name: " displayname
  read -p "Enter avatar URL (optional): " avatar_url
  read -p "Enter email address (optional, comma-separated for multiple): " emails
  read -p "Enter external ID (optional, format: auth_provider:external_id): " external_ids_input
  read -p "Is the user an admin? (true/false): " admin
  read -p "Is the user deactivated? (true/false): " deactivated
  read -p "Is the user locked? (true/false): " locked

  threepids=""
  IFS=',' read -r -a email_array <<<"$emails"
  for email in "${email_array[@]}"; do
    threepids+="{
            \"medium\": \"email\",
            \"address\": \"${email}\"
        },"
  done
  threepids="${threepids%,}" 
  external_ids=""
  if [ -n "$external_ids_input" ]; then
    IFS=',' read -r -a external_array <<<"$external_ids_input"
    for external in "${external_array[@]}"; do
      IFS=':' read -r auth_provider external_id <<<"$external"
      external_ids+="{
                \"auth_provider\": \"${auth_provider}\",
                \"external_id\": \"${external_id}\"
            },"
    done
    external_ids="${external_ids%,}" 
  fi

  json_payload=$(jq -n \
    --arg password "$user_password" \
    --arg displayname "$displayname" \
    --arg avatar_url "$avatar_url" \
    --argjson logout_devices false \
    --argjson admin "$admin" \
    --argjson deactivated "$deactivated" \
    --argjson locked "$locked" \
    --argjson threepids "[$threepids]" \
    --argjson external_ids "[$external_ids]" \
    '{
            password: $password,
            logout_devices: $logout_devices,
            displayname: $displayname,
            avatar_url: $avatar_url,
            threepids: $threepids,
            external_ids: $external_ids,
            admin: $admin,
            deactivated: $deactivated,
            locked: $locked
        }')

  curl -X PUT "https://${MATRIX_HOST}/_synapse/admin/v2/users/${user_id}" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$json_payload" | jq . 
}

deactivate_user() {
  read -p "Enter user ID to deactivate (format: @username:server): " user_id
  curl -X POST "https://${MATRIX_HOST}/_synapse/admin/v1/deactivate/${user_id}" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"erase": false}' | jq . 
} 

reset_password() {
  read -p "Enter user ID to reset password (format: @username:server): " user_id
  read -p "Enter new password: " new_password
  curl -X POST "https://${MATRIX_HOST}/_synapse/admin/v1/reset_password/${user_id}" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"new_password\": \"${new_password}\", \"logout_devices\": true}" | jq . 
}

query_user_account() {
  read -p "Enter user ID to query (format: @username:server): " user_id
  curl -X GET "https://${MATRIX_HOST}/_synapse/admin/v2/users/${user_id}" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" | jq . 
}

list_user_devices() {
  read -p "Enter user ID to list devices (format: @username:server): " user_id
  curl -X GET "https://${MATRIX_HOST}/_synapse/admin/v2/users/${user_id}/devices" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" | jq . 
}


GREEN="\033[1;32m"
PURPLE="\033[1;34m"
NC="\033[0m"

# MENU SYSTEM
display_welcome_message() {
  echo -e "${GREEN}"  


  echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
  echo "░         ░░░░░░░░░░░░░   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ░░░░░░░   ░░░░░░░░░░░░░░   ░░░░░░░░░░░░░░░░░░░░░░░░"
  echo "▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒     ▒▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒▒"
  echo "▒   ▒▒▒▒▒▒▒   ▒   ▒▒▒    ▒  ▒▒▒▒   ▒▒▒▒▒  ▒    ▒▒▒▒▒▒▒    ▒  ▒   ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒   ▒   ▒ ▒   ▒▒▒▒   ▒▒▒▒▒    ▒  ▒  ▒    ▒▒▒▒▒   ▒▒▒   "
  echo "▓       ▓▓▓▓   ▓▓   ▓▓▓   ▓▓▓▓  ▓▓▓   ▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓     ▓▓▓▓▓  ▓▓▓   ▓▓▓▓▓▓▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓▓▓   ▓▓▓▓   ▓▓▓▓   ▓▓▓  ▓   ▓"
  echo "▓   ▓▓▓▓▓▓▓▓   ▓▓   ▓▓▓   ▓▓▓         ▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓   ▓▓  ▓▓         ▓▓▓▓▓▓▓▓   ▓▓▓  ▓▓   ▓   ▓▓▓   ▓▓▓▓   ▓▓▓▓   ▓▓▓▓   ▓▓▓▓  ▓▓▓▓"
  echo "▓   ▓▓▓▓▓▓▓▓   ▓▓   ▓▓▓   ▓ ▓  ▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓   ▓ ▓  ▓▓▓   ▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓   ▓   ▓▓▓   ▓▓▓▓   ▓ ▓▓   ▓▓▓▓   ▓▓  ▓▓   ▓"
  echo "█         █    ██   ████   ████     ████    █████████████   ██  ███   ███     ██████████   ███████   ███   █    ████   ██    ████   █   ███   "
  echo "██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"

  center_text() {
    text="$1"
    term_width=$(tput cols)
    text_length=${#text}
    spaces=$(((term_width - text_length) / 2))
    printf "%${spaces}s%s\n" "" "$text"
  }

  echo -e "${PURPLE}" 
  center_text "This script provides a user-friendly interface for managing users"
  center_text "on a Matrix server using the Synapse Admin API. You can perform"
  center_text "various actions such as listing users, creating users, resetting"
  center_text "passwords, and managing tokens."
  echo -e "${NC}"
}

main() {
  display_welcome_message

  while true; do
    echo ""
    echo "Select an option:"
    echo ""
    echo "1) List Users"
    echo "2) Create User"
    echo "3) Deactivate User"
    echo "4) Reset Password"
    echo "5) List Tokens"
    echo "6) Create Token"
    echo "7) Query User Account"
    echo "8) List User Devices"
    echo ""
    echo "9) Exit"
    echo ""

    read -p "Enter your choice [1-9]: " choice

    case "$choice" in
    1) list_users ;;
    2) create_user ;;
    3) deactivate_user ;;
    4) reset_password ;;
    5) list_tokens ;;
    6) create_token ;;
    7) query_user_account ;;
    8) list_user_devices ;;
    9)
      echo "Exiting..."
      exit 0
      ;;
    *) echo "Invalid option. Please select a number between 1 and 9." ;;
    esac

  done
}

main