#!/bin/bash
#
# Script to receive NMEA data on UDP port 7014 convert it to CSV and feed it continuously into datastream.csv
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

# Requirements :
# nc (netcat) to receive the NMEA data over the network
# gpsdecode (From the gpsd-clients package on debian)
# jq to conver the JSON data from gpsdecode into CSV 
#
# All the "stdbuf" commands are there to ensure that data is written to the file in realime. Linux usually 
# requires 4KB of data before it will actually write to the file.
#
# May 2016
# Greenpeace ship MY Esperanza Somewhere in the Indian Ocean
#
####

echo "Starting Listen"

stdbuf -i0 -o0 -e0 nc -ul 7014  \
 | stdbuf -i0 -o0 -e0 gpsdecode \
 | stdbuf -i0 -o0 -e0 jq -r 'select(.mmsi != null and .lat != null ) | [(now | strftime("%Y/%m/%d")),(now | strftime("%H:%M:%S")),.mmsi, .lat, .lon, .speed, .course] | @csv' >> /home/abri/ais/datastream.csv
