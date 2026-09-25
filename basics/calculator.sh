#!/bin/bash

echo "Enter first number: "
read num1 

echo "Enter second number: "
read num2

echo "Enter Operation (+,-,*,/): " 
read operation

case $operation in 
	+)
		result=$((num1 + num2))
		;;
	-)
		result=$((num1 - num2))
		;;

	\*)	result=$((num1 * num2))
		;;

	/)
		result=$((num1 / num2))
		;;
esac 

echo "Result : $result"

