#!/usr/bin/env python3
__author__ = 'Austin Matthews'

""" Initial implementation of complex numbers. """

class Complex:

    def __init__(self, real, imag):
        self.real = real
        self.imag = imag

    def __add__(self, c2):
        c = Cplx(self.real+c2.real, self.imag+c2.imag)
        return c

    def __str__(self):
        return "%s+%sj" % (self.real, self.imag)

if __name__ == "__main__":
    zero = Cplx(0.0, 0.0)
    one = Cplx(1.0, 0.0)
    i = Cplx(0.0, 1.0)
    result = zero + one + i
    print(result)