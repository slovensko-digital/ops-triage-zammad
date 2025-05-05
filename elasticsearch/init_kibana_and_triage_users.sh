#!/bin/sh

AUTHORIZATION=elastic:$ELASTIC_PASSWORD
URL=${ELASTICSEARCH_SCHEMA:-http}://${ELASTICSEARCH_HOST:-localhost}:${ELASTICSEARCH_PORT:-9200}

while ! curl -s -f -o /dev/null -u $AUTHORIZATION $URL; do
  echo 'Waiting for Elasticsearch...'
  sleep 5
done

echo 'Setting kibana_system password...'
curl -u $AUTHORIZATION -X POST $URL/_security/user/kibana_system/_password -H 'Content-Type: application/json' -d "{\"password\": \"$KIBANA_PASSWORD\"}"
echo 'Done'

echo 'Setting zammad user role...'
curl -u $AUTHORIZATION -X POST $URL/_security/role/$ELASTICSEARCH_USER -H 'Content-Type: application/json' -d "{\"cluster\": [\"monitor\", \"manage_ingest_pipelines\"], \"indices\": [{\"names\": [\"$ELASTICSEARCH_USER-index*\"], \"privileges\": [\"all\"]}]}"
echo 'Done'

echo 'Setting zammad user...'
curl -u $AUTHORIZATION -X POST $URL/_security/user/$ELASTICSEARCH_USER -H 'Content-Type: application/json' -d "{\"password\": \"$ELASTICSEARCH_PASS\", \"roles\": [\"$ELASTICSEARCH_USER\"]}"
echo 'Done'
