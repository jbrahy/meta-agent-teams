#!/bin/sh

for i in `cat tmp/suggested-agents.txt `
do
./bin/build-team-template.sh $i
done
