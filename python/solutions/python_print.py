"""
Read an integer N

Without using any string methods, try to print the following:

123 ... N

Note that ... represents the values in between.

Input Format
The first line contains an integer N

Output Format
Output the answer as explained in the task.

Sample Input

3
Sample Output

123
"""

if __name__ == '__main__':
    #n = int(input())
    # swap these for testing locally
    n = 4

    def gen_nums():
        num = 1
        while num <= n:
            yield num
            num +=1


    for x in gen_nums():
        print(x, end='')