#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from email import encoders
from email.header import Header
from email.mime.text import MIMEText
from email.utils import parseaddr, formataddr
import smtplib
import os
from time import sleep

sleep(20)

def _format_addr(s):
    name, addr = parseaddr(s)
    return formataddr((Header(name, 'utf-8').encode(), addr))

from_addr = '********@163.com'
password = '********'
to_addr = '********@qq.com'
smtp_server = 'smtp.163.com'
ip_file = '/home/pi/.hostname'

os.system("hostname -I > "+ip_file)
ip_file = open(ip_file)

server = smtplib.SMTP(smtp_server, 25)
server.set_debuglevel(1)
server.login(from_addr, password)

msg = MIMEText(ip_file.readline().replace(' ', '\n'), 'plain', 'utf-8')
msg['From'] = _format_addr(from_addr)
msg['To'] = _format_addr(to_addr)
msg['Subject'] = Header('rpi system ip', 'utf-8').encode()
server.sendmail(from_addr, [to_addr], msg.as_string())

server.quit()
ip_file.close()
