import pathlib
from pathlib import Path
import shutil
import sqlite3
import requests
import json

cookies_working_copy_path = Path("/home/hans/.gerrit/cookies.sqlite")
specific_firefox_cookies_path = Path("/home/hans/snap/firefox/common/.mozilla/firefox/0uv15g7c.default/cookies.sqlite")

shutil.copy(specific_firefox_cookies_path, cookies_working_copy_path)

cookienames = ["_forward_auth2", "GerritAccount", ]

sqlcommand = 'select name,value,creationTime from moz_cookies where host like "%.haleytek.net"'
sqlconn = sqlite3.connect("/home/hans/.gerrit/cookies.sqlite")
sqlres = sqlconn.execute(sqlcommand)


cookies = dict()
for name, value, timestamp in sqlres:
    if name in cookienames:
        cookies[name] = value


r=requests.get("https://source.haleytek.net/changes/haleytek%2Fvendor%2Fhaleytek%2Ftools%2Fqualcomm~36888/detail?O=1916314", allow_redirects=False, cookies=cookies)
data = json.loads(r.content.splitlines()[1])
print(json.dumps(data, indent=4))



