#!/usr/bin/python
'''sample function to determine the fibonacci seq until a max limit'''

'''funcion to calculate the fibinaci sequence'''
def fibonacci(max):
    a,b = 0,1
    while a < max:
        yield a
        a,b = b,b+a


'''to print out the seq until it hits 500'''
for num in fibonacci(500):
    print(num, end=' ')

''' output:
0 1 1 2 3 5 8 13 21 34 55 89 144 233 377     
'''


'''for vertical output'''
for num in fibonacci(7):
    print(num)

''' output:
0
1
1
2
3
5
'''