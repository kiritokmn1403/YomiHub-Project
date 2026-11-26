/* Pure ES5 Archive & Compression Utilities for YumiHub Samsung TV (Tizen 4.0 / Chromium 56) */
/* Supports raw UTF-8 JSON, Gzip (.gz), and ZIP (.backup with Store or RFC 1951 Deflate) */
(function (root) {
  'use strict';

  var LENGTH_BASE = [
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
    35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
  ];
  var LENGTH_EXTRA = [
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
    3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
  ];
  var DIST_BASE = [
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
    257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
  ];
  var DIST_EXTRA = [
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
    7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
  ];
  var CL_ORDER = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

  var FIXED_LIT_TREE = null;
  var FIXED_DIST_TREE = null;

  function buildTree(lengths, maxLen) {
    var counts = new Array(maxLen + 1);
    var nextCode = new Array(maxLen + 1);
    var i;
    for (i = 0; i <= maxLen; i++) counts[i] = 0;
    for (i = 0; i < lengths.length; i++) {
      if (lengths[i] > 0) counts[lengths[i]]++;
    }
    var code = 0;
    counts[0] = 0;
    for (i = 1; i <= maxLen; i++) {
      code = (code + counts[i - 1]) << 1;
      nextCode[i] = code;
    }
    var map = {};
    for (i = 0; i < lengths.length; i++) {
      var len = lengths[i];
      if (len > 0) {
        var c = nextCode[len]++;
        map[(len << 16) | c] = i;
      }
    }
    return { map: map, maxLen: maxLen };
  }

  function ensureFixedTrees() {
    if (FIXED_LIT_TREE) return;
    var lit = new Array(288);
    var i;
    for (i = 0; i <= 143; i++) lit[i] = 8;
    for (i = 144; i <= 255; i++) lit[i] = 9;
    for (i = 256; i <= 279; i++) lit[i] = 7;
    for (i = 280; i <= 287; i++) lit[i] = 8;
    var dist = new Array(32);
    for (i = 0; i < 32; i++) dist[i] = 5;
    FIXED_LIT_TREE = buildTree(lit, 9);
    FIXED_DIST_TREE = buildTree(dist, 5);
  }

  function BitReader(bytes, offset) {
    this.bytes = bytes;
    this.pos = offset || 0;
    this.bitBuf = 0;
    this.bitCnt = 0;
  }

  BitReader.prototype.readBits = function (n) {
    while (this.bitCnt < n) {
      if (this.pos >= this.bytes.length) {
        throw new Error('Unexpected end of compressed stream');
      }
      this.bitBuf |= this.bytes[this.pos++] << this.bitCnt;
      this.bitCnt += 8;
    }
    var val = this.bitBuf & ((1 << n) - 1);
    this.bitBuf >>>= n;
    this.bitCnt -= n;
    return val;
  };

  BitReader.prototype.alignByte = function () {
    this.bitBuf = 0;
    this.bitCnt = 0;
  };

  BitReader.prototype.readSymbol = function (tree) {
    var code = 0;
    var len;
    for (len = 1; len <= tree.maxLen; len++) {
      code = (code << 1) | this.readBits(1);
      var key = (len << 16) | code;
      if (tree.map.hasOwnProperty(key)) {
        return tree.map[key];
      }
    }
    throw new Error('Invalid Huffman symbol');
  };

  function inflateRaw(bytes, startOffset) {
    ensureFixedTrees();
    var reader = new BitReader(bytes, startOffset || 0);
    var out = [];
    var bfinal = 0;

    while (!bfinal) {
      bfinal = reader.readBits(1);
      var btype = reader.readBits(2);

      if (btype === 0) {
        reader.alignByte();
        if (reader.pos + 4 > bytes.length) {
          throw new Error('Truncated stored deflate block');
        }
        var len = bytes[reader.pos] | (bytes[reader.pos + 1] << 8);
        var nlen = bytes[reader.pos + 2] | (bytes[reader.pos + 3] << 8);
        reader.pos += 4;
        if (((len ^ 0xffff) & 0xffff) !== nlen) {
          throw new Error('Corrupt stored deflate block length');
        }
        var end = reader.pos + len;
        if (end > bytes.length) throw new Error('Truncated stored deflate data');
        for (; reader.pos < end; reader.pos++) {
          out.push(bytes[reader.pos]);
        }
      } else if (btype === 1 || btype === 2) {
        var litTree;
        var distTree;
        if (btype === 1) {
          litTree = FIXED_LIT_TREE;
          distTree = FIXED_DIST_TREE;
        } else {
          var hlit = reader.readBits(5) + 257;
          var hdist = reader.readBits(5) + 1;
          var hclen = reader.readBits(4) + 4;
          var clLens = new Array(19);
          var i;
          for (i = 0; i < 19; i++) clLens[i] = 0;
          for (i = 0; i < hclen; i++) {
            clLens[CL_ORDER[i]] = reader.readBits(3);
          }
          var clTree = buildTree(clLens, 7);
          var total = hlit + hdist;
          var lens = new Array(total);
          var idx = 0;
          while (idx < total) {
            var sym = reader.readSymbol(clTree);
            if (sym < 16) {
              lens[idx++] = sym;
            } else {
              var rep = 0;
              var val = 0;
              if (sym === 16) {
                if (idx === 0) throw new Error('Invalid repeat in deflate header');
                val = lens[idx - 1];
                rep = 3 + reader.readBits(2);
              } else if (sym === 17) {
                val = 0;
                rep = 3 + reader.readBits(3);
              } else {
                val = 0;
                rep = 11 + reader.readBits(7);
              }
              while (rep-- > 0 && idx < total) {
                lens[idx++] = val;
              }
            }
          }
          litTree = buildTree(lens.slice(0, hlit), 15);
          distTree = buildTree(lens.slice(hlit), 15);
        }

        while (true) {
          var s = reader.readSymbol(litTree);
          if (s < 256) {
            out.push(s);
          } else if (s === 256) {
            break;
          } else {
            var li = s - 257;
            if (li >= LENGTH_BASE.length) throw new Error('Invalid length symbol');
            var matchLen = LENGTH_BASE[li] + (LENGTH_EXTRA[li] ? reader.readBits(LENGTH_EXTRA[li]) : 0);
            var di = reader.readSymbol(distTree);
            if (di >= DIST_BASE.length) throw new Error('Invalid distance symbol');
            var dist = DIST_BASE[di] + (DIST_EXTRA[di] ? reader.readBits(DIST_EXTRA[di]) : 0);
            if (dist > out.length) throw new Error('Distance before start of output');
            var k;
            for (k = 0; k < matchLen; k++) {
              out.push(out[out.length - dist]);
            }
          }
        }
      } else {
        throw new Error('Unsupported deflate block type 3');
      }
    }

    return new Uint8Array(out);
  }

  function decodeUtf8(uint8) {
    if (typeof TextDecoder !== 'undefined') {
      return new TextDecoder('utf-8').decode(uint8);
    }
    var out = '';
    var i = 0;
    var len = uint8.length;
    while (i < len) {
      var c = uint8[i++];
      if (c < 0x80) {
        out += String.fromCharCode(c);
      } else if (c >= 0xc0 && c < 0xe0 && i < len) {
        out += String.fromCharCode(((c & 0x1f) << 6) | (uint8[i++] & 0x3f));
      } else if (c >= 0xe0 && c < 0xf0 && i + 1 < len) {
        out += String.fromCharCode(((c & 0x0f) << 12) | ((uint8[i++] & 0x3f) << 6) | (uint8[i++] & 0x3f));
      } else if (c >= 0xf0 && i + 2 < len) {
        var cp = ((c & 0x07) << 18) | ((uint8[i++] & 0x3f) << 12) | ((uint8[i++] & 0x3f) << 6) | (uint8[i++] & 0x3f);
        cp -= 0x10000;
        out += String.fromCharCode(0xd800 + (cp >> 10), 0xdc00 + (cp & 0x3ff));
      }
    }
    return out;
  }

  function readUint16LE(bytes, off) {
    return bytes[off] | (bytes[off + 1] << 8);
  }

  function readUint32LE(bytes, off) {
    return (bytes[off] | (bytes[off + 1] << 8) | (bytes[off + 2] << 16) | (bytes[off + 3] << 24)) >>> 0;
  }

  function extractFromGzip(bytes) {
    if (bytes.length < 10) throw new Error('Tệp Gzip quá ngắn');
    var flg = bytes[3];
    var pos = 10;
    if (flg & 4) {
      var xlen = readUint16LE(bytes, pos);
      pos += 2 + xlen;
    }
    if (flg & 8) {
      while (pos < bytes.length && bytes[pos] !== 0) pos++;
      pos++;
    }
    if (flg & 16) {
      while (pos < bytes.length && bytes[pos] !== 0) pos++;
      pos++;
    }
    if (flg & 2) pos += 2;
    return decodeUtf8(inflateRaw(bytes, pos));
  }

  function extractFromZip(bytes) {
    // Tim End of Central Directory (0x06054b50)
    var eocdOffset = -1;
    var minOff = Math.max(0, bytes.length - 65558);
    var i;
    for (i = bytes.length - 22; i >= minOff; i--) {
      if (bytes[i] === 0x50 && bytes[i + 1] === 0x4b && bytes[i + 2] === 0x05 && bytes[i + 3] === 0x06) {
        eocdOffset = i;
        break;
      }
    }

    var entries = [];
    if (eocdOffset !== -1) {
      var totalEntries = readUint16LE(bytes, eocdOffset + 10);
      var cdOffset = readUint32LE(bytes, eocdOffset + 16);
      var ptr = cdOffset;
      for (i = 0; i < totalEntries && ptr + 46 <= bytes.length; i++) {
        if (readUint32LE(bytes, ptr) !== 0x02014b50) break;
        var flags = readUint16LE(bytes, ptr + 8);
        var method = readUint16LE(bytes, ptr + 10);
        var compSize = readUint32LE(bytes, ptr + 20);
        var nameLen = readUint16LE(bytes, ptr + 28);
        var extraLen = readUint16LE(bytes, ptr + 30);
        var commentLen = readUint16LE(bytes, ptr + 32);
        var localOff = readUint32LE(bytes, ptr + 42);
        var name = decodeUtf8(bytes.subarray(ptr + 46, ptr + 46 + nameLen));
        entries.push({
          name: name,
          flags: flags,
          method: method,
          compSize: compSize,
          localOff: localOff
        });
        ptr += 46 + nameLen + extraLen + commentLen;
      }
    } else if (readUint32LE(bytes, 0) === 0x04034b50) {
      // Fallback: Local File Header
      var lflags = readUint16LE(bytes, 6);
      var lmethod = readUint16LE(bytes, 8);
      var lcomp = readUint32LE(bytes, 18);
      var lnameLen = readUint16LE(bytes, 26);
      entries.push({
        name: decodeUtf8(bytes.subarray(30, 30 + lnameLen)),
        flags: lflags,
        method: lmethod,
        compSize: lcomp,
        localOff: 0
      });
    }

    if (!entries.length) {
      throw new Error('Không tìm thấy tệp dữ liệu trong kho lưu trữ ZIP');
    }

    // Uu tien tep .backup.db hoac .json
    var target = entries[0];
    for (i = 0; i < entries.length; i++) {
      var lower = entries[i].name.toLowerCase();
      if (lower.indexOf('.backup.db') !== -1 || lower.indexOf('.json') !== -1) {
        target = entries[i];
        break;
      }
    }

    if (target.flags & 1) {
      throw new Error('Tệp .backup đang bật mã hóa mật khẩu. Vui lòng tắt mã hóa sao lưu trên YomiHub hoặc giải nén lấy tệp .backup.db (JSON) trước khi nhập.');
    }

    var lo = target.localOff;
    if (readUint32LE(bytes, lo) !== 0x04034b50) {
      throw new Error('Local file header ZIP không hợp lệ');
    }
    var fnLen = readUint16LE(bytes, lo + 26);
    var exLen = readUint16LE(bytes, lo + 28);
    var dataStart = lo + 30 + fnLen + exLen;
    var sliceEnd = target.compSize > 0 ? Math.min(bytes.length, dataStart + target.compSize) : bytes.length;
    var payload = bytes.subarray(dataStart, sliceEnd);

    if (target.method === 0) {
      return decodeUtf8(payload);
    }
    if (target.method === 8) {
      return decodeUtf8(inflateRaw(payload, 0));
    }
    throw new Error('Phương thức nén ZIP không được hỗ trợ (' + target.method + ')');
  }

  function extractJsonText(arrayBuffer) {
    var bytes = new Uint8Array(arrayBuffer);
    if (!bytes || bytes.length === 0) {
      throw new Error('Tệp trống');
    }
    // ZIP magic: PK\x03\x04
    if (bytes[0] === 0x50 && bytes[1] === 0x4b && bytes[2] === 0x03 && bytes[3] === 0x04) {
      return extractFromZip(bytes);
    }
    // Gzip magic: 0x1f 0x8b
    if (bytes[0] === 0x1f && bytes[1] === 0x8b) {
      return extractFromGzip(bytes);
    }
    return decodeUtf8(bytes);
  }

  root.YumiArchive = {
    extractJsonText: extractJsonText,
    inflateRaw: inflateRaw,
    decodeUtf8: decodeUtf8
  };
})(window);
