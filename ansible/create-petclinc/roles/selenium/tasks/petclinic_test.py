#!/usr/bin/python

import unittest
from selenium import webdriver
import time


class TestThree(unittest.TestCase):

    def setUp(self):
        self.startTime = time.time()

    def test_url_fire(self):
        time.sleep(2)
        self.driver = webdriver.Firefox()
        self.driver.get("http://localhost:8080") # url associated with button click
        button = self.driver.find_element_by_id("home").get_attribute("value")
        #self.assertEquals(u'Pay - $60.00', button)

    def test_url_phantom(self):
        time.sleep(1)
        self.driver = webdriver.PhantomJS()
        self.driver.get("http://localhost:8080") # url associated with button click
        button = self.driver.find_element_by_id("home").get_attribute("value")
        #self.assertEquals(u'Pay - $60.00', button)

    def tearDown(self):
        t = time.time() - self.startTime
        print(' "%s: %.3f" % (self.id(), t) ')
        self.driver.quit()

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestThree)
    unittest.TextTestRunner(verbosity=0).run(suite)