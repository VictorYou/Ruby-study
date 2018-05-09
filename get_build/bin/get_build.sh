#!/bin/bash

date="$1"
[ -z "$date" ] && date=`date -d '7 days ago' +%Y-%m-%d`

ruby -I ../lib get_builds.rb -s ../conf/sonar_projects.chengdu
mv sonar_builds_ut sonar_builds_ut.chengdu.csv

ruby -I ../lib get_builds.rb -s ../conf/sonar_projects.all
mv sonar_builds_ut sonar_builds_ut.all.csv

ruby -I ../lib get_builds.rb -j ../conf/jenkins_servers.all -J ../conf/jenkins_jobs.chengdu -A -d "$date" -a -S
mv builds_starting builds_starting.chengdu.csv
mv builds_starting_analysis builds_starting_analysis.chengdu.csv
mv builds_aborted builds_aborted.chengdu.csv

ruby -I ../lib get_builds.rb -j ../conf/jenkins_servers.all -J ../conf/jenkins_jobs.all -A -d "$date" -a -S
mv builds_starting builds_starting.all.csv
mv builds_starting_analysis builds_starting_analysis.all.csv
mv builds_aborted builds_aborted.all.csv
