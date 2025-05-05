#!/bin/sh

AUTHORIZATION=elastic:$ELASTIC_PASSWORD
URL=${ELASTICSEARCH_SCHEMA:-http}://${ELASTICSEARCH_HOST:-localhost}:${ELASTICSEARCH_PORT:-9200}

read -p "Username: " USER
echo
read -sp "Password: " PASSWORD
echo

ROLE=$USER
INDEX_PREFIX=$ROLE-index

echo 'Creating user role...'
curl -u $AUTHORIZATION -X POST $URL/_security/role/$USER -H 'Content-Type: application/json' -d "{\"cluster\": [\"monitor\", \"manage_ingest_pipelines\"], \"indices\": [{\"names\": [\"$USER-index*\"], \"privileges\": [\"all\"]}]}"
echo 'Done'

echo 'Creating zammad user...'
curl -u $AUTHORIZATION -X POST $URL/_security/user/$USER -H 'Content-Type: application/json' -d "{\"password\": \"$PASSWORD\", \"roles\": [\"$ROLE\"]}"
echo 'Done'
