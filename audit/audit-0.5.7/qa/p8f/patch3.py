import io,sys
p='overlay/lib/modules/manga/reader/subsampling_scale_image_view/src/subsampling_scale_image_view.dart'
s=io.open(p,encoding='utf-8',newline='').read(); c='\r\n' in s; s=s.replace('\r\n','\n')
def rep(a,b):
    global s
    if s.count(a)!=1: sys.exit('MISMATCH %r'%a[:60])
    s=s.replace(a,b)
rep('''    if (!mounted || _loadState != LoadState.loading) return;
    final path = _resolvedFilePath ?? '';
    _failDecode(''','''    if (!mounted || _loadState != LoadState.loading) return;
    // An off-screen page has its decodes cancelled on purpose: not an error.
    if (!widget.isVisible) return;
    final path = _resolvedFilePath ?? '';
    _failDecode(''')
rep('''        // Trigger tile refresh when it becomes visible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshTiles(load: true);''','''        // Trigger tile refresh when it becomes visible
        if (_loadState == LoadState.loading && _resolvedFilePath != null) {
          _armDecodeWatchdog();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshTiles(load: true);''')
if c: s=s.replace('\n','\r\n')
io.open(p,'w',encoding='utf-8',newline='').write(s); print('ok')
