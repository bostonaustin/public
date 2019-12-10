#!/usr/bin/env python


'''
Usage: $ python ./ssl_cert_checker.py -c config.yml -a 28 -m mail@mail.com

loops through websites to report the SSL certificate expiration dates of multiple sites

changes email subject header when sites expire within a number of days (28 by default)

requires config file -- format <host>:<port>

    config.yml :    website_a:443
                    website_b:443
                    website_c:443
'''


import sys
import io
import smtplib
import argparse
import socket
import datetime
import yaml
from OpenSSL import SSL
from email.mime.text import MIMEText
from argparse import RawTextHelpFormatter


def config():
    import yaml
    with open('config.yml', 'r') as f:
        doc = yaml.load(f)
    return doc

def log(message, severity):
    ''' print to STDOUT with custom timestamp - use $ ssl_cert_checker.py > to save to a logfile '''
    current_time = datetime.datetime.today().strftime('%Y-%m-%d.%H:%M:%S')
    log_level = 1                                                           # set to 0 = normal / 1 = debug
    if log_level >= severity:                                               # set log severity 0 = normal [OR] 1 = debug
        print("{0} {1}".format(current_time, message))


def cert_checker(p1, p2, p3):
    ''' check for a response from servers being verified '''
    config_file = p1
    alert_days = int(p2)
    mail_rcpt = p3
    mail_date = datetime.datetime.today().strftime('%d-%B-%Y.%H:%M')
    mail_from = '<ssl_cert_checker@example.com>'
    cur_date = datetime.datetime.utcnow()
    servers = io.open(config_file, 'r')
    mail_server = '127.0.0.1'
    response = ''
    cert_tested = 0
    cert_valid = 0
    email_alert = 0
    email_info = 0
    email_error = 0

    for line in servers:
        ''' loop over list of ssl certs to check '''
        host = line.strip().split(':')[0]
        port = line.strip().split(':')[1]
        try:
            context = SSL.Context(SSL.SSLv23_METHOD)
            sock = SSL.Connection(context, socket.socket())
            try:
                sock.connect((str(host), int(port)))
                sock.send('\x00')
                get_peer_cert = sock.get_peer_certificate()
                sock.close()
                exp_date = datetime.datetime.strptime(get_peer_cert.get_notAfter(), '%Y%m%d%H%M%SZ')
                days_to_expire = int((exp_date - cur_date).days)
                cert_tested += 1
                if days_to_expire < 7:
                    response += "[ALERT] {0}:{1} has EXPIRED ALREADY with {2} days until expired.\n".format(host, port, days_to_expire)
                    email_alert += 1
                elif days_to_expire < alert_days:
                    response += "[INFO] {0}:{1} will expire in {2} days with {3} days left before considering an alert.\n".format(host, port, days_to_expire, alert_days)
                    email_info += 1
                else:
                    response += "[OK] {0}:{1} does not expire for {2} days. (expires {3})\n".format(host, port, days_to_expire, exp_date)
                    cert_valid += 1
            except Exception as e:
                response += "\n[ERROR] {0} -- while testing {1}:{2}.\n".format(e, host, port)
                email_error += 1
                cert_tested += 1
        except SSL.Error as e:
            response += "\n[ERROR] {0} -- while testing {1}:{2}.\n".format(e, host, port)
            email_error += 1
            cert_tested += 1

    if response:
        response += "\n   Total certificates [ {0} valid / {1} tested ]".format(cert_valid, cert_tested)
        try:
            message = MIMEText(response)
            if email_error > 0:
                message['Subject'] = "ERROR - SSL cert checker {0}".format(mail_date)      # endpoint failed to connect
            elif email_alert > 0:
                message['Subject'] = "ALERT - SSL cert checker {0}".format(mail_date)      # cert expired
            elif email_info > 0:
                message['Subject'] = "INFO - SSL cert checker {0}".format(mail_date)       # cert expiring < alert_days
            else:
                message['Subject'] = "SSL cert checker {0}".format(mail_date)              # all clear
            message['From'] = mail_from
            message['To'] = mail_rcpt
            smtpObj = smtplib.SMTP( mail_server )
            smtpObj.sendmail(mail_from, mail_rcpt, message.as_string())
            smtpObj.quit()
        except smtplib.SMTPException:
            log("\n [ERROR] Unable to send mail \n".format(__file__), 0)


def main():
    ''' check the url(s) for valid SSL certificates and alert if expiring '''
    parser = argparse.ArgumentParser(description='Check SSL certificate expiration date(s) for website(s)',
                                     usage='%(prog)s [OPTIONS]',
                                     formatter_class=RawTextHelpFormatter)
    parser.add_argument('-c, --config', dest='config_file', help='''Enter the location of the configuration file\n  [default = -c .ssl_cert_checker.list]''')
    parser.add_argument('-a, --alert', type=int, dest='alert_days', help='''Enter the number of day(s) left before considering an alert\n  [default = -a 28]''')
    parser.add_argument('-m, --mail', dest='mail_rcpt', help='''Send the email report to this recipient\n  [default = -m boston.austin@gmail.com]''')
    args=parser.parse_args()

    if args.config_file is None:
        log("[DEBUG] no configuration file defined as argument, using default".format(__file__), 1)
        config_file = config()
    else:
        config_file = args.config_file

    if args.alert_days is None:
        log("[DEBUG] no number of alert days defined as argument, using default".format(__file__), 1)
        alert_days = 28
    else:
        alert_days = args.alert_days

    if args.mail_rcpt is None:
        log("[DEBUG] no mail recipient defined as argument, using default".format(__file__), 1)
        mail_rcpt = '<boston.austin@gmail.com>'
    else:
        mail_rcpt = args.mail_rcpt

    try:
        cert_checker(config_file, alert_days, mail_rcpt)
    except Exception as err:
        print(err)
        log("[ERROR] process failed to complete properly -- please try again".format(__file__), 0)
        sys.exit(1)

        
# only run as a stand-alone script
if __name__ == '__main__':
    try:
        main()
    except Exception as e_main:
        print(e_main)
