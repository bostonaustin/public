#!/usr/bin/env python3
__author__ = 'Austin Matthews'

""" Creates dispatch table from 4 string method based functions. """

from string import *
dispatch_table = {
                "capital" : str.capitalize,
                "title" : str.title,
                "upper" : str.upper,
                "lower" : str.lower
                }

while True:
    function_choice = input("Enter a function name (capital, title, upper, lower, exit): ")
    if function_choice == "exit":
        break
    input_string = input("Enter a string: ")
    print(dispatch_table[function_choice](input_string))
