#!/usr/bin/env python3
__author__ = 'Austin Matthews'
""" simple doctest example """

small_words = ('into', 'the', 'a', 'of', 'at', 'in', 'for', 'on')

def book_title(title):
    """ Takes a string and returns a title-case string.
    All words EXCEPT for small words are made title case
    unless the string starts with a preposition, in which
    case the word is correctly capitalized.

    Examples:
        >>> book_title('DIVE Into python')
        'Dive into Python'

        >>> book_title('the great gatsby')
        'The Great Gatsby'

        >>> book_title('the WORKS OF AleXANDer dumas')
        'The Works of Alexander Dumas'
    """

    word_list = title.lower().split()
    if len(word_list) < 1:
        return ''

    new_title = word_list.pop(0).title()
    for word in word_list:
        if word in small_words:
            new_title = new_title + ' ' + word
        else:
            new_title = new_title + ' ' + word.title()
    return new_title

# define _test to import itself or throw except ImportError
def _test():
    import doctest, simple_doctest
    return doctest.testmod(simple_doctest)

# call doctest
if __name__ == "__main__":
    _test()

# exit code 0 indicates the test passed OK