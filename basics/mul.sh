#!/bin/bash

echo "Enter the first Number: "
read num1 

echo "Enter the second Number: " 
read num2

if [ "$num2" -eq 0 ]; then
	echo "Error : Cannot divide by xero" 
	exit 1
fi 

result=$((num1 / num2))

echo "The answer is $result"
