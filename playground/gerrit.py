import pathlib
from pathlib import Path
import shutil
import sqlite3
import requests
import json

hardcoded_auth_storage_name = "a8808be0-1bda-431d-ab8b-65fa44d0c83e.d3a7f22c-46af-4a63-99d1-177a117b6c78-login.windows.net-accesstoken-696157fc-d8d5-4614-b0aa-5b4383ae558c-d3a7f22c-46af-4a63-99d1-177a117b6c78%"

cookies_working_copy_path = Path("/home/hans/.gerrit/cookies.sqlite")
storage_working_copy_path = Path("/home/hans/.gerrit/data.sqlite")
specific_firefox_cookies_path = Path("/home/hans/snap/firefox/common/.mozilla/firefox/0uv15g7c.default/cookies.sqlite")
specific_firefox_storage_path = Path("/home/hans/snap/firefox/common/.mozilla/firefox/0uv15g7c.default/storage/default/https+++source.haleytek.net/ls/data.sqlite")


shutil.copy(specific_firefox_cookies_path, cookies_working_copy_path)
shutil.copy(specific_firefox_storage_path, storage_working_copy_path)

# auth cookie for gerrit
cookienames = ["_forward_auth2", "GerritAccount", "csrftoken"]

sqlcommand = 'select name,value,creationTime from moz_cookies where host like "%.haleytek.net"'
sqlconn = sqlite3.connect(cookies_working_copy_path)
sqlres = sqlconn.execute(sqlcommand)

cookies = dict()
for name, value, timestamp in sqlres:
    if name in cookienames:
        cookies[name] = value
    if name.startswith("_ga"):
        cookies[name] = value

# auth token for follow.haleytek...
sqlcommand = f'select value from data where key like "{hardcoded_auth_storage_name}"'
sqlconn = sqlite3.connect(storage_working_copy_path)
sqlres = sqlconn.execute(sqlcommand)

#for (i,) in sqlres:
#    t = json.loads(i)
#    print(t['secret'])

#print(sqlres.fetchone())
(js,) = sqlres.fetchone()
j = json.loads(js)
follow_secret = j['secret']


allchangesurl="https://source.haleytek.net/changes/?q=is:open+owner:self+-is:wip"
allchangesurl="https://source.haleytek.net/changes/?q=38879"
headers={"Accept": "application/json"}

def get_votes(labels):
    t = [x['value'] for x in labels['all']]
    return min(t), max(t)


def get_json_from_follow(details):
    current_revision = details['current_revision']

    headers = \
    {
            'Origin': 'https://source.haleytek.net',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-site',
            'TE': 'trailers',
    }

    headers['authorization'] = f"Bearer {follow_secret}"

    patchsetsha = current_revision
    changenumber = details['_number']
    patchset = details['revisions'][current_revision]['_number']

    r = requests.get(f'https://follow.haleytek.net/api/jobSuggestions?patchsetSha={patchsetsha}&status=NEW&change_nr={changenumber}&ps={patchset}', allow_redirects=True, cookies=cookies, headers=headers)
    runs = json.loads(r.content)
    d=json.dumps(runs, indent=2)

    print(d)
    runsdict = dict()
    for r in runs['runs']:
        if r['checkName'] not in runsdict:
            runsdict[r['checkName']] = dict()
        tmp = runsdict[r['checkName']]

        if 'attempt' not in r:
            continue

        if r['attempt'] not in tmp:
            tmp[r['attempt']] = dict()
        tmp2 = tmp[r['attempt']]
        tmp2['status'] = r['status']

        att = r['attempt'] if 'attempt' in r else '?'
        #print("RUN START", att, r['checkName'])
        for res in r['results']:

            if res['category'] not in tmp2:
                tmp2[res['category']] = 0
            tmp2[res['category']] += 1

            #print(res['category'])
        #print("RUN END")

    print(runsdict)
    exit(0)

def format_submit_requirement(change, submit_req):
    match submit_req['name']:
        case 'Verified':
            lab = change['labels']['Verified']
            _min, _max = get_votes(lab)
            return f'V'
        case 'Code-Review':
            lab = change['labels']['Code-Review']
            _min, _max = get_votes(lab)
            return f'R/{_min:+},{_max:+}'
        case 'Resolved comments':
            tot = change['total_comment_count']
            unres = change['unresolved_comment_count']
            return f'C/{tot},{unres}'
        case _: return ''
    return

def find_req_by_name(details, name):
    for req in details['submit_requirements']:
        if req['name'] == name: return req

def get_json_from_gerrit(url):
    r = requests.get(url, allow_redirects=False, cookies=cookies)
    return json.loads(r.content.splitlines()[1])

req2letter = {'Verified': 'V', 'Code-Review': 'R', 'Resolved comments': 'C'}
changelist = get_json_from_gerrit(allchangesurl)
for change in changelist:
    details = get_json_from_gerrit(f"https://source.haleytek.net/changes/{change['id']}/detail?O=1916314")
    get_json_from_follow(details)
    print(f"\x1b[36m{change['_number']}\x1b[0m", end=" ")
    print("[", end=" ")
    for reqname in req2letter.keys():
        req = find_req_by_name(details, reqname)
        match req['status']:
            case 'SATISFIED': col = 32
            case 'UNSATISFIED': col = 31
            case _: col = 33
        print(f"\x1b[{col}m{format_submit_requirement(details, req)}", end="\x1b[0m ")
        #print(details['labels'][req['name']])
        #print(req['submittability_expression_result']['expression'])
        #print(req['submittability_expression_result']['failing_atoms'])
        #print(req['submittability_expression_result']['passing_atoms'])
        #print("......", req['submittability_expression_result']['failing_atoms'], req['submittability_expression_result']['failing_atoms'])
    print("]", end=" ")
    print(change['subject'])




