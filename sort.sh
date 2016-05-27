#!/bin/bash
#
# AIS target finder sort.sh - Sorts and filters datastream from listen.sh
#
####
## Copyright (C) 2016 by Abri le Roux <abrileroux@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###
# This script is run periodically using cron. It scans the datastream file from listen.sh,
# sees if it contains any targets contained in targets.list. It then generates a small report
# in lastseen.txt. A GPX file containing all matches is then generated.
# A report of targets along with the GPX file is then emailed to the email addresses entered below.  
# Old data is copied to the archive directory.
#
# Requirements:
# Standard bash stuff 
# gawk
# gpsbabel
# mailx
#
# May 2016
# Greenpeace ship MY Esperanza Somewhere in the Indian Ocean
#
####

# Set some variables
scripttime=`date -u +"%d%m%y-%H"`
workdir=/home/user/ais
email="example@mail.com"

# Clean up the working files from the previous run
rm $workdir/lastseen.txt
rm $workdir/*.gpx
rm $workdir/mail.txt

# Add the headers to the lastseen CSV file. Required so that GPSBabel know's whats going on
echo \"name\",\"date\",\"time\",\"desc\",\"lat\",\"lon\",\"speed\",\"cour\" >> $workdir/lastseen.txt

# Add some introduction text to the email.
echo "List of ship information received since last update. Times in UTC." > $workdir/mail.txt

# Say what we are doing.. this will be recorded to the log file.

echo `date` : "Looking for Targets..."

# For each target in the list...
for i in `cat $workdir/targets.list`; do
	# ... See if it has a match in the datastream.csv file... 
        # ... and if it	does, make a csv file for each ship in the currentships directory... 
	if grep `echo $i | awk -F "," '{print $1}'` $workdir/datastream.csv > $workdir/currentships/$i; then
		
		echo FOUND $i
		
		# ... store some pertinent information for each ship in temporary variables. We use gawk to select
		# the field we want in CSV. 
		shipname=`echo $i | awk -F "," '{gsub(/"/, "", $2)}; {print $2}'`
		shipdata=`tail -1 $workdir/currentships/$i`
		lasttime=`echo $shipdata | awk -F "," '{gsub(/"/, "", $2)}; {print $2}'`
		lastdate=`echo $shipdata | awk -F "," '{gsub(/"/, "", $1)}; {print $1}'`
		shipspeed=`echo $shipdata | awk -F "," '{print $6}'`
		shipcourse=`echo $shipdata | awk -F "," '{print $7}'`
		
		# Put that information into the lastseen.txt file. Still in CSV format..
		echo \"$shipname $shipspeed kt $shipcourse\",$shipdata >> $workdir/lastseen.txt
                
		# Prepare the email's text	
		echo "" >> $workdir/mail.txt 
		echo $shipname at $lasttime on $lastdate. Speed $shipspeed kt Course $shipcourse >> $workdir/mail.txt
		
	else
		# If the ship wasn't found don't keep a blank file around. Delete it.
		rm $workdir/currentships/$i
	fi
done

echo "Generating GPX file..."
# Tell GPSBabel to generate a GPX file from the lastseen.txt file.
gpsbabel -i unicsv -f $workdir/lastseen.txt -o gpx -F $workdir/$scripttime.gpx

# Send everything to the people in the $email variable. Email sent outside the ship can take a while to be delivered.
echo "Sending Mail..."
cat $workdir/mail.txt | mailx -s "AIS digest - $scripttime" -a $workdir/$scripttime.gpx $email

# Make an archive of the data so that we can go back to look through it in the future if we need to.
echo "Archiving Data..."

mkdir $workdir/archive/$scripttime
mkdir $workdir/archive/$scripttime/ships

cp $workdir/currentships/* $workdir/archive/$scripttime/ships
cp $workdir/$scripttime.gpx $workdir/archive/$scripttime/
cp $workdir/lastseen.txt $workdir/archive/$scripttime/
cp $workdir/datastream.csv $workdir/archive/$scripttime/

# Truncate the datastream.csv file so that the next time the script is run it will work on fresh data.
echo "Resetting Datastream..."
echo "" > $workdir/datastream.csv

echo "Done" `date`

