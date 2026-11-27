import json,sys,urllib.request,urllib.parse
sys.stdout.reconfigure(encoding='utf-8')
terms=sys.argv[1:]
for t in terms:
    u='https://itunes.apple.com/search?'+urllib.parse.urlencode({'term':t,'entity':'software','country':'us','limit':5})
    try:
        r=json.loads(urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'Mozilla/5.0'}),timeout=30).read())
        print('##',t)
        for x in r['results']:
            print('  ',x['trackId'],x['trackName'][:40],'|',x.get('averageUserRating'),x.get('userRatingCount'),x.get('currentVersionReleaseDate','')[:10])
    except Exception as e: print(t,e)
