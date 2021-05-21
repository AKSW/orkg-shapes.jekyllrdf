#!/bin/sh

LC_ALL=C
GRAPH=orkg-dump/orkg.nt
SHAPES=shapes.nt
CLASSES=classes.nt
PREDICATES=predicates.nt
CLASSES_QUERY=classes.sparql
PREDICATES_QUERY=predicates.sparql
EXPORT=orkg-shapes.nt

SOURCE_URL=http://orkg.org/orkg/

# Install shaclgen from my fork
pip install git+https://github.com/white-gecko/shaclgen@feature/extractClasses

MESSAGE="Update ORKG Shapes"
LOG=""
LOG="${LOG}"$( date '+%Y-%m-%d %H.%M.%S%z' )"\n"

shaclgen ${GRAPH} -ns http://orkg.org/orkg/shapes/ orkgsh -p prefixes.json | rapper -i turtle - http://example.org/ > ${SHAPES}
docker run --rm --volume $PWD:/query --network data aksw/query http://fuseki:3030/orkg /query/${CLASSES_QUERY} -f nt > ${CLASSES}
docker run --rm --volume $PWD:/query --network data aksw/query http://fuseki:3030/orkg /query/${PREDICATES_QUERY} -f nt > ${PREDICATES}

LOG="${LOG}"$( wc -l $SHAPES)"\n"
LOG="${LOG}"$( wc -l $CLASSES)"\n"
LOG="${LOG}"$( wc -l $PREDICATES)"\n"
cat ${CLASSES} ${PREDICATES} ${SHAPES} | sort -u > ${EXPORT}

LOG="${LOG}"$( wc -l $EXPORT)"\n"

rm ${CLASSES} ${PREDICATES} ${SHAPES}

LOG="${LOG}\nSource: \"<${SOURCE_URL}>\"\n"

echo $LOG

git add $EXPORT

# Check if files changed or commits need to be pushed
git status --porcelain | grep '^[MTD] '
change_status=$((1-$?))

if [ $change_status -eq 0 ]; then
  echo "[INFO] Repository needs no update. Abort."
  exit 0
else
  git commit -m "$MESSAGE" -m "$( echo ${LOG} )"
fi
