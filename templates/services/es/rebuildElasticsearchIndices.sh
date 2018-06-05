#!/bin/sh
set -x

apk add --update curl

# Set commands
COMMAND="curl -s -k -X"
{{- if not .dev }}
ES_HOST="https://elasticsearch:9200"
{{- else }}
ES_HOST="http://elasticsearch:9200"
{{- end }}
MAPPINGS_PATH="/config"
SHARD="3"
REPLICA="2"
DATE="$(date +%d-%m-%Y)"

${COMMAND} GET "${ES_HOST}/_cluster/health?wait_for_status=green&timeout=50s"

# Set index templates
echo
echo "Creating Elasticsearch index templates..."
${COMMAND} PUT "${ES_HOST}/_template/activities" -H 'Content-Type:application/json' -d '{ "template": "*activities", "order": 0, "settings": { "index.mapper.dynamic": false } }'
echo
${COMMAND} PUT "${ES_HOST}/_template/contacts" -H 'Content-Type:application/json' -d '{ "template": "*contacts", "order": 0, "settings": { "index.mapper.dynamic": false } }'
echo
${COMMAND} PUT "${ES_HOST}/_template/events" -H 'Content-Type:application/json' -d '{ "template": "*activities", "order": 0, "settings": { "index.mapper.dynamic": false } }'
# Interactions is set to dynamic mappings for now (dev only)
echo
${COMMAND} PUT "${ES_HOST}/_template/interactions" -H 'Content-Type:application/json' -d '{ "template": "*interactions", "order": 0, "settings": { "index.mapper.dynamic": true } }'
echo
${COMMAND} PUT "${ES_HOST}/_template/organisations" -H 'Content-Type:application/json' -d '{ "template": "*organisations", "order": 0, "settings": { "index.mapper.dynamic": false } }'
echo
${COMMAND} PUT "${ES_HOST}/_template/organisationskb" -H 'Content-Type:application/json' -d '{ "template": "*organisationskb", "order": 0, "settings": { "index.mapper.dynamic": false } }'
echo
${COMMAND} PUT "${ES_HOST}/_template/${ES_PREFIX}vacancy-activities" -H 'Content-Type:application/json' -d '{ "template": "*vacancy-activities", "order": 0, "settings": { "index.mapper.dynamic": false } }'
echo

# Create indices with mappings
echo
echo "Creating Elasticsearch indices..."
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}activities_${DATE}" -H 'Content-Type:application/json' -d '{"settings":{"index":{"number_of_shards":'${SHARD}',"number_of_replicas":'${REPLICA}'}}}' --data @${MAPPINGS_PATH}/mappings_Seed_Activities.json
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}contacts_${DATE}" -H 'Content-Type:application/json' -d '{"settings":{"index":{"number_of_shards":'${SHARD}',"number_of_replicas":'${REPLICA}'}}}' --data @${MAPPINGS_PATH}/mappings_Seed_Contacts.json
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}events_${DATE}" -H 'Content-Type:application/json' -d '{"settings":{"index":{"number_of_shards":'${SHARD}',"number_of_replicas":'${REPLICA}'}}}' --data @${MAPPINGS_PATH}/mappings_Seed_Events.json
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}interactions_${DATE}"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}organisations_${DATE}" -H 'Content-Type:application/json' -d '{"settings":{"index":{"number_of_shards":'${SHARD}',"number_of_replicas":'${REPLICA}'}}}' --data @${MAPPINGS_PATH}/mappings_Seed_Organisations.json
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}organisationskb_${DATE}" -H 'Content-Type:application/json' -d '{"settings":{"index":{"number_of_shards":'${SHARD}',"number_of_replicas":'${REPLICA}'}}}' --data @${MAPPINGS_PATH}/mappings_Seed_Organisations.json
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}vacancy-activities_${DATE}" -H 'Content-Type:application/json' -d '{"settings":{"index":{"number_of_shards":'${SHARD}',"number_of_replicas":'${REPLICA}'}}}' --data @${MAPPINGS_PATH}/mappings_Seed_VacancyActivities.json
echo

# Create alias
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}activities_${DATE}/_alias/${ES_PREFIX}activities"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}contacts_${DATE}/_alias/${ES_PREFIX}contacts"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}events_${DATE}/_alias/${ES_PREFIX}events"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}interactions_${DATE}/_alias/${ES_PREFIX}interactions"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}organisations_${DATE}/_alias/${ES_PREFIX}organisations"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}organisationskb_${DATE}/_alias/${ES_PREFIX}organisationskb"
echo
${COMMAND} PUT "${ES_HOST}/${ES_PREFIX}vacancy-activities_${DATE}/_alias/${ES_PREFIX}vacancy-activities"

# Output indices from ES
echo
echo "Current Elasticsearch indices..."
${COMMAND} GET "${ES_HOST}/_cat/indices"

echo
echo "You should now start monstache replication to see data appear in Elasticsearch."
echo
