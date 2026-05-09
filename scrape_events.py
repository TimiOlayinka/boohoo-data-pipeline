import urllib.request
import re

url = "https://www.eventbrite.co.uk/d/united-kingdom--manchester/networking/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read().decode('utf-8')
    links = re.findall(r'href=\"(https://www.eventbrite.co.uk/e/[^\"]+)\"', html)
    print(list(set(links))[:10])
except Exception as e:
    print(e)
