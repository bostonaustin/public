#!/usr/bin/python3

'''
# demo list comprehension

given three integers x, y, z representing the dimensions of a cuboid along with an integer N
print a list of all possible coordinates given by (i,j,k) on a 3D grid where the sum of i+j+k is not equal to N

[ expression-involving-loop-variable for loop-variable in sequence ]

    This will step over every element in a sequence, successively setting the loop-variable equal to every element one at a time.
    It will then build up a list by evaluating the expression-involving-loop-variable for each one.
    This eliminates the need to use lambda forms and generally produces a much more readable code than using map()
    and a more compact code than using a for loop.

>> ListOfNumbers = [ x for x in range(10) ] # List of integers from 0 to 9
>> ListOfNumbers
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]


# expected output:
# [[0, 0, 0], [0, 0, 1], [0, 1, 0], [1, 0, 0], [1, 1, 1]]
'''

if __name__ == '__main__':
#    x = int(input())
#    y = int(input())
#    z = int(input())
#    n = int(input())

# swap for local test
    x = int('2')
    y = int('2')
    z = int('2')
    n = int('2')

# CORRECT output [[0, 0, 0], [0, 0, 1], [0, 1, 0], [1, 0, 0], [1, 1, 1]]
#cubes = [[i,j,k] for i in range(x) for j in range(y) for k in range(z) if i+j+k != n]
#print(cubes)
# BUT FAILS 0,0,1,0 test case

#WORKS on one test case 1112
# cubes = [[x,y,z] for x in range(2) for y in range(2) for z in range(2) if x+y+z != n]

cubes = [[i,j,k] for i in range(x+1) for j in range(y+1) for k in range(z+1) if i+j+k != n]
print(cubes)

'''
cubes = [[i,j,k]
         for i in range(x+1)
         for j in range(y+1)
         for k in range(z+1)
         if i+j+k != n]
print(cubes)
'''