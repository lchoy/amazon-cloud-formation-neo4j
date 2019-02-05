#!/bin/bash

echo "====================================================" 
echo "== MEETUP BENCHMARK"
echo "== START: " $(date)
echo "====================================================" 

if [ -z $2 ] ; then 
   echo "Usage: ./benchmark.sh bolt+routing://host:7687 Neo4jPassword"
   exit 1
fi

if [ -z $1 ] ; then
   echo  "Usage: ./benchmark.sh bolt+routing://host:7687 Neo4jPassword"
   exit 1
fi

export NEO4J_URI=$1
export NEO4J_PASSWORD=$2
export NEO4J_USERNAME=neo4j

TAG=$(head -c 3 /dev/urandom | md5 | head -c 5)

STARTTIME=$(date +%s)

echo "Index phase" 
START_INDEX=$(date +%s)
cat 01-index.cypher | cypher-shell -a $NEO4J_URI
END_INDEX=$(date +%s)
ELAPSED_INDEX=$(($END_INDEX - $START_INDEX))

echo "Load phase" 
START_LOAD=$(date +%s)
./load-all.sh segment-files-subset.txt
END_LOAD=$(date +%s)
ELAPSED_LOAD=$(($END_LOAD - $START_LOAD))

echo "Cities phase" 
START_CITIES=$(date +%s)
cat 02b-load-world-cities.cypher | cypher-shell -a $NEO4J_URI
END_CITIES=$(date +%s)
ELAPSED_CITIES=$(($END_CITIES - $START_CITIES))

echo "Link groups phase"
START_LINK=$(date +%s)
cat 03a-link-groups-to-countries.cypher | cypher-shell -a $NEO4J_URI
echo "Link venues phase" 
cat 03b-link-venues-to-cities.cypher | cypher-shell -a $NEO4J_URI 
END_LINK=$(date +%s)
ELAPSED_LINK=$(($END_LINK - $START_LINK))

for q in `seq 1 5` ; do 
    echo "Queryload $q phase"
    for i in `seq 1 10` ; do 
        cat read-queries/q$q >> queryload-$TAG-$q.cypher
    done

    cat queryload-$TAG-$q.cypher | cypher-shell -a $NEO4J_URI
done
ENDTIME=$(date +%s)
ELAPSED=$(($ENDTIME - $STARTTIME))
echo "BENCHMARK ELAPSED TIME IN SECONDS: " $ELAPSED

rm -f queryload-$TAG-*.cypher
echo "Done"

echo "====================================================" 
echo "== BENCHMARK $TAG $1"
echo "== FINISH: " $(date)
echo "===================================================="
echo "Benchmark $TAG complete with $ELAPSED elapsed"

echo "BENCHMARK_ELAPSED=$ELAPSED"
echo "BENCHMARK_LINK=$ELAPSED_LINK"
echo "BENCHMARK_LOAD=$ELAPSED_LOAD"
echo "BENCHMARK_CITIES=$ELAPSED_CITIES"
echo "BENCHMARK_INDEX=$ELAPSED_INDEX"
