#!/bin/bash
cd "$(dirname "$0")"
: > missing_all.txt
run() { echo "===== $1"; node run.js ext/$1 "$2" "$3" 2>&1 | grep -v "^missing requests"; cat missing.txt >> missing_all.txt; echo >> missing_all.txt; }
run rophim.js https://www.rophimhd.com '[["latest"],["popular"],["search","conan"],["detail","$first"],["videos","$firstEp"]]'
run hotphim.js https://hotphim.org '[["popular"],["latest"],["search","tinh yeu"],["detail","$first"],["videos","$firstEp"]]'
run hako.js https://ln.hako.vn '[["popular"],["latest"],["search","tensei"],["detail","$first"],["html","$firstCh"]]'
run anime47.js https://anime47.best '[["popular"],["latest"],["search","naruto"],["detail","$first"]]'
run vtvgo.js https://vtvgo.vn '[["popular"],["detail","$first"],["videos","$firstEp"]]'
run youtube.js https://www.youtube.com '[["popular"],["search","son tung"],["detail","$first"],["videos","$firstEp"]]'
run pornhub.js https://www.pornhub.com '[["popular"],["latest"],["search","asian"],["detail","$first"],["videos","$firstEp"]]'
run fikfap.js https://fikfap.com '[["popular"],["latest"],["search","asian"],["detail","$first"],["videos","$firstEp"]]'
grep -v '^$' missing_all.txt | sort -u > missing.txt
echo "TOTAL MISSING: $(wc -l < missing.txt)"
