import sys,socket,struct,collections
def ip(h):
    if len(h)==8: return socket.inet_ntoa(struct.pack('<I',int(h,16)))
    b=bytes.fromhex(h); b=b''.join(b[i:i+4][::-1] for i in range(0,16,4))
    return socket.inet_ntop(socket.AF_INET6,b).replace('::ffff:','')
c=collections.Counter(); uids=collections.Counter()
for l in open(sys.argv[1],encoding='ascii',errors='ignore'):
    p=l.split()
    if len(p)<8 or not p[0].endswith(':') or p[0]=='sl': continue
    uids[p[7]]+=1
    rh,rp=p[2].split(':'); r=ip(rh)
    if r.startswith(('0.0.0.0','127.','::')) and r!='::ffff': 
        if r not in ('::',): continue
    if p[7]==sys.argv[2]: c[(p[3],r,int(rp,16))]+=1
print('uids',dict(uids)); 
for k,v in sorted(c.items()): print(k,v)
