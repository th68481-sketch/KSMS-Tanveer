#!/bin/bash
# Bootstrap Platform Super Admin
# Usage: ./bootstrap.sh <email> <password> <setup_token>

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <email> <password> <setup_token>"
    exit 1
fi

# Call Supabase Edge Function 'bootstrap-super-admin'
curl -X POST "$SUPABASE_URL/functions/v1/bootstrap-super-admin" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$1\", \"password\": \"$2\", \"setup_token\": \"$3\"}"
