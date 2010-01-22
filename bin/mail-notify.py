#!/usr/bin/python
# -*- encoding: utf-8 -*-
#
# Chmouel Boudjnah <chmouel@chmouel.com>
import sqlite3
import datetime
import os
import sys

CONFIG = {
    'interval' : 5,
    'sendmail_location' : '/usr/sbin/sendmail',
    'mail_from' : 'chmouel@chmouel.com',
    'mail_to' : 'chmouel@gmail.com',
}

def sql_thing():
    ret = {}
    string_to_send = []
    conn = sqlite3.connect("/tmp/mail-notify.db")
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    before = datetime.datetime.now() - datetime.timedelta(minutes=CONFIG['interval'])
    before_str = str(before)[:str(before).find('.')]

    query = cur.execute('select id, strftime(\'%%H:%%M\', date) as date, nick, channel, message from data where date >= "%s"' % (before_str,))
    for row in  query:
        if row['channel'] in ret:
            ret[row['channel']].append(row)
        else:
            ret[row['channel']] = [row]

    #cleanup if we already active in that channel
    for chan in ret:
        for row in ret[chan]:
            if row['nick'] == 'me':
                ret[chan] = []

    for chan in ret:
        if not ret[chan]:
            continue
        for row in ret[chan]:
            string_to_send.append("%s <%s> %s" % (row['date'], row['nick'], row['message']))
            conn.execute("delete from data where id=?", (row['id'],))
            
    conn.commit()
    conn.close();
    return string_to_send
    
def send_mail(config, text):
    p = os.popen("%s -t" % config['sendmail_location'], "w")
    p.write("From: %s\n" % config['mail_from'])
    p.write("To: %s\n" % config['mail_to'])
    p.write("Subject: New IRC messages (%d)\n" % (len(text)))
    p.write("\n") # 
    p.write("\n".join(text))
    status = p.close()
    if status == 256:
        sys.exit(1)

def main():
    things_to_send = sql_thing()
    if not things_to_send:
        return
    send_mail(CONFIG, things_to_send)

if __name__ == '__main__':
    main()
