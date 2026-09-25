#!/bin/bash

filename="sample.txt"

echo "Creating file..." 

touch "$filename"

echo "File created successfuly."

if [ -f "$filename" ]; then 
	echo "file exists." 
else
	echo "File does not exist." 

fi 

echo "adding data to file..." 
echo "hellof from shell scripting" > "$filename"
echo "file Contents:"
cat "$filename" 
