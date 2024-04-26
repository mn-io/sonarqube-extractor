#!/bin/bash

. _shared.sh

function getRules() {
    PAGE_NUMBER=$1 # > 0
    PAGE_SIZE=$2 # <= 500

    SONARQUBE_QUERY="${SONARQUBE_HOST}/api/rules/search?f=name,lang,severity,status&s=key&activation=true&qprofile=${QUALITY_PROFILE}"

    curl -s -u ${SONARQUBE_USER} \
      "${SONARQUBE_QUERY}&p=${PAGE_NUMBER}&ps=${PAGE_SIZE}"
}


echo "Fetching overview..."
TOTAL=$(getRules 1 1 | jq '.total')
TOTAL_PAGES=$((TOTAL/500 + 1))
echo "Fetching in total ${TOTAL} rules on ${TOTAL_PAGES} pages"


RESULT="";

for (( i=1; i<=TOTAL_PAGES; i++ ))
do
   echo "  Fetching page ${i} of ${TOTAL_PAGES}"
   RESULT+=$(getRules $i 500 | jq '[.rules[] ]')
done


RESULT=$(echo ${RESULT} | sed "s#\\\\\"#'#g" )

echo $'# SONARQUBE active rules\n' > ${OUTPUT_FILE_NAME}.md

echo ${RESULT} | jq -s 'add' | jq -c ".[]" | while read RULE; do
    echo "${RULE}"
    KEY=$(echo "${RULE}" | jq -r '.key')

    echo "##" ${KEY}: $(echo "${RULE}" | jq -r '.name') >> ${OUTPUT_FILE_NAME}.md
    echo "${SONARQUBE_HOST}/coding_rules?open=${KEY}" >> ${OUTPUT_FILE_NAME}.md
    echo '' >> ${OUTPUT_FILE_NAME}.md
    echo - severity: $(echo "${RULE}" | jq -r '.severity') >> ${OUTPUT_FILE_NAME}.md
    echo - type: $(echo "${RULE}" | jq -r '.type') >> ${OUTPUT_FILE_NAME}.md
    echo - lang: $(echo "${RULE}" | jq -r '.lang') >> ${OUTPUT_FILE_NAME}.md
    echo - status: $(echo "${RULE}" | jq -r '.status') >> ${OUTPUT_FILE_NAME}.md

    QUERY="${SONARQUBE_HOST}/api/rules/show?key=${KEY}"
    RULE_DESCRIPTION=$(curl -s -u ${SONARQUBE_USER} ${QUERY} | jq '.rule')
    
    echo - scope: $(echo "${RULE_DESCRIPTION}" | jq -r '.scope') >> ${OUTPUT_FILE_NAME}.md
    echo '' >> ${OUTPUT_FILE_NAME}.md
    echo '>' $(echo "${RULE_DESCRIPTION}" | jq -r '.mdDesc') >> ${OUTPUT_FILE_NAME}.md
   
    echo $'\n' >> ${OUTPUT_FILE_NAME}.md
done