#!/bin/bash

. _shared.sh

function getSearch() {
    PAGE_NUMBER=$1 # > 0
    PAGE_SIZE=$2 # <= 500

    SONARQUBE_QUERY="${SONARQUBE_HOST}/api/issues/search?componentKeys=${PROJECT_KEY}&s=FILE_LINE&resolved=false"

    curl -s -u ${SONARQUBE_USER} \
      "${SONARQUBE_QUERY}&p=${PAGE_NUMBER}&ps=${PAGE_SIZE}"
}

echo "Fetching overview..."
TOTAL=$(getSearch 1 1 | jq '.total')
TOTAL_PAGES=$((TOTAL/500 + 1))
echo "Fetching in total ${TOTAL} issues on ${TOTAL_PAGES} pages"


RESULT="";

for (( i=1; i<=TOTAL_PAGES; i++ ))
do
   echo "  Fetching page ${i} of ${TOTAL_PAGES}"
   RESULT+=$(getSearch $i 500 | jq '[.issues[] ]')
done


echo "(over)writing ${OUTPUT_FILE_NAME}.json" 
echo ${RESULT} | jq -s 'add' > ${OUTPUT_FILE_NAME}.json


echo "(over)writing ${OUTPUT_FILE_NAME}.csv" 
CSV_HEADER='key", '\
'"link to issue", '\
'"rule", '\
'"link to rule", '\
'"severity", '\
'"type", '\
'"message", '\
'"component", '\
'"scope", '\
'"quickFixAvailable"'
CSV_SELECT='.key, '\
'("=HYPERLINK(\"'${SONARQUBE_HOST}'/issues?projects='${PROJECT_KEY}'&rules="+.rule+"&open="+.key+"\")"), '\
'.rule, '\
'("=HYPERLINK(\"'${SONARQUBE_HOST}'/coding_rules?open="+.rule+"&rule_key="+.rule+"\")"), '\
'.severity, '\
'.type, '\
'.message, '\
'.component, '\
'.scope, '\
'.quickFixAvailable'

echo ${CSV_HEADER} > ${OUTPUT_FILE_NAME}.csv
echo ${RESULT} | jq -s 'add' | jq -r ".[] | [${CSV_SELECT}] | @csv"  >> ${OUTPUT_FILE_NAME}.csv

echo "done"