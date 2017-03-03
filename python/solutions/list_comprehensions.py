if __name__ == '__main__':
    numbers = []
    # swap these 2 lines below for local testing
    n = 4
    # n = int(input())

    def gen_nums():
        num = 1
        while num <= n:
            yield num
            num += 1

    for x in gen_nums():
        print(x, end='')