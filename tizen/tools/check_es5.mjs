#!/usr/bin/env node
/**
 * Pure Node.js ES5 compatibility checker for YumiHub Samsung TV (Tizen 4.0 / Chromium 56).
 * Zero external dependencies: strips comments, string literals, and regex literals,
 * validates syntax via vm.Script, and rejects ES6+ syntax constructs.
 *
 * Usage:
 *   node check_es5.mjs [file-or-dir ...]
 *   (defaults to ../js relative to this script)
 */

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DEFAULT_JS_DIR = path.resolve(__dirname, '..', 'js');

const REGEX_PRECEDING_KEYWORDS = new Set([
  'return',
  'throw',
  'case',
  'delete',
  'void',
  'typeof',
  'instanceof',
  'in',
  'of',
  'new',
  'else',
  'do',
  'yield',
  'await'
]);

const ES6_KEYWORDS = new Map([
  ['let', 'let declaration (ES6)'],
  ['const', 'const declaration (ES6)'],
  ['class', 'class syntax (ES6)'],
  ['await', 'await expression (ES2017)'],
  ['import', 'import syntax (ES6+)'],
  ['export', 'export syntax (ES6+)']
]);

function isIdentStart(ch) {
  return (ch >= 'a' && ch <= 'z') ||
    (ch >= 'A' && ch <= 'Z') ||
    ch === '_' ||
    ch === '$';
}

function isIdentPart(ch) {
  return isIdentStart(ch) || (ch >= '0' && ch <= '9');
}

function isDigit(ch) {
  return ch >= '0' && ch <= '9';
}

function isWhitespace(ch) {
  return ch === ' ' || ch === '\t' || ch === '\r' || ch === '\n' || ch === '\v' || ch === '\f';
}

function buildLineStarts(source) {
  const starts = [0];
  for (let i = 0; i < source.length; i++) {
    if (source[i] === '\n') {
      starts.push(i + 1);
    }
  }
  return starts;
}

function offsetToLineCol(lineStarts, offset) {
  let lo = 0;
  let hi = lineStarts.length - 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (lineStarts[mid] <= offset) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  const lineIdx = Math.max(0, hi);
  return {
    line: lineIdx + 1,
    col: offset - lineStarts[lineIdx] + 1
  };
}

/**
 * Strips comments (//, /* *\/), string literals ('...', "..."), and regex literals (/.../)
 * while preserving exact line breaks/offsets and flagging template literals (`...`).
 */
function stripNonCode(source, lineStarts) {
  const out = [];
  const templateViolations = [];
  const len = source.length;
  let i = 0;
  let canStartRegex = true;

  function pushMasked(ch) {
    out.push(ch === '\n' ? '\n' : ' ');
  }

  while (i < len) {
    const ch = source[i];
    const next = i + 1 < len ? source[i + 1] : '';

    // Line comment
    if (ch === '/' && next === '/') {
      out.push(' ', ' ');
      i += 2;
      while (i < len && source[i] !== '\n') {
        out.push(' ');
        i++;
      }
      continue;
    }

    // Block comment
    if (ch === '/' && next === '*') {
      out.push(' ', ' ');
      i += 2;
      while (i < len) {
        if (source[i] === '*' && i + 1 < len && source[i + 1] === '/') {
          out.push(' ', ' ');
          i += 2;
          break;
        }
        pushMasked(source[i]);
        i++;
      }
      continue;
    }

    // String literal ('...' or "...")
    if (ch === '\'' || ch === '"') {
      const quote = ch;
      out.push(quote);
      i++;
      while (i < len) {
        const c = source[i];
        if (c === '\\') {
          pushMasked(c);
          i++;
          if (i < len) {
            pushMasked(source[i]);
            i++;
          }
          continue;
        }
        if (c === quote) {
          out.push(quote);
          i++;
          break;
        }
        if (c === '\n') {
          out.push('\n');
          i++;
          break;
        }
        out.push(' ');
        i++;
      }
      canStartRegex = false;
      continue;
    }

    // Template literal (`...`) -> ES6 violation!
    if (ch === '`') {
      const pos = offsetToLineCol(lineStarts, i);
      templateViolations.push({
        line: pos.line,
        col: pos.col,
        rule: 'template-literal',
        message: 'Template literal (`...`) is ES6+ syntax'
      });
      out.push(' ');
      i++;
      while (i < len) {
        const c = source[i];
        if (c === '\\') {
          pushMasked(c);
          i++;
          if (i < len) {
            pushMasked(source[i]);
            i++;
          }
          continue;
        }
        if (c === '`') {
          out.push(' ');
          i++;
          break;
        }
        pushMasked(c);
        i++;
      }
      canStartRegex = false;
      continue;
    }

    // Regex literal (/.../)
    if (ch === '/' && canStartRegex) {
      out.push('/');
      i++;
      let inCharClass = false;
      while (i < len) {
        const c = source[i];
        if (c === '\\') {
          pushMasked(c);
          i++;
          if (i < len) {
            pushMasked(source[i]);
            i++;
          }
          continue;
        }
        if (c === '[') {
          inCharClass = true;
          out.push(' ');
          i++;
          continue;
        }
        if (c === ']' && inCharClass) {
          inCharClass = false;
          out.push(' ');
          i++;
          continue;
        }
        if (c === '/' && !inCharClass) {
          out.push('/');
          i++;
          break;
        }
        if (c === '\n') {
          out.push('\n');
          i++;
          break;
        }
        out.push(' ');
        i++;
      }
      while (i < len && ((source[i] >= 'a' && source[i] <= 'z') || (source[i] >= 'A' && source[i] <= 'Z'))) {
        out.push(' ');
        i++;
      }
      canStartRegex = false;
      continue;
    }

    // Identifier / keyword
    if (isIdentStart(ch)) {
      const start = i;
      while (i < len && isIdentPart(source[i])) {
        out.push(source[i]);
        i++;
      }
      const word = source.slice(start, i);
      canStartRegex = REGEX_PRECEDING_KEYWORDS.has(word);
      continue;
    }

    // Number literal
    if (isDigit(ch) || (ch === '.' && isDigit(next))) {
      while (i < len && (isIdentPart(source[i]) || source[i] === '.')) {
        out.push(source[i]);
        i++;
      }
      canStartRegex = false;
      continue;
    }

    // Whitespace
    if (isWhitespace(ch)) {
      out.push(ch);
      i++;
      continue;
    }

    // Punctuation & operators
    out.push(ch);
    if ((ch === '+' && next === '+') || (ch === '-' && next === '-')) {
      out.push(next);
      i += 2;
      canStartRegex = false;
      continue;
    }
    if (ch === ')' || ch === ']') {
      canStartRegex = false;
    } else {
      canStartRegex = true;
    }
    i++;
  }

  return {
    stripped: out.join(''),
    templateViolations
  };
}

function prevNonWsChar(str, idx) {
  for (let i = idx - 1; i >= 0; i--) {
    if (!isWhitespace(str[i])) return { ch: str[i], index: i };
  }
  return { ch: '', index: -1 };
}

function nextNonWsChar(str, idx) {
  for (let i = idx; i < str.length; i++) {
    if (!isWhitespace(str[i])) return { ch: str[i], index: i };
  }
  return { ch: '', index: -1 };
}

function findMatchingParen(str, openIdx) {
  let depth = 0;
  for (let i = openIdx; i < str.length; i++) {
    const ch = str[i];
    if (ch === '(') depth++;
    else if (ch === ')') {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function findMatchingBracket(str, openIdx) {
  let depth = 0;
  for (let i = openIdx; i < str.length; i++) {
    const ch = str[i];
    if (ch === '[') depth++;
    else if (ch === ']') {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function checkStrippedEs6(stripped, lineStarts) {
  const violations = [];

  function addViolation(offset, rule, message) {
    const pos = offsetToLineCol(lineStarts, offset);
    violations.push({ line: pos.line, col: pos.col, rule, message });
  }

  // 1. Operator & multi-char token checks
  for (let i = 0; i < stripped.length; i++) {
    const ch = stripped[i];
    const next = i + 1 < stripped.length ? stripped[i + 1] : '';
    const next2 = i + 2 < stripped.length ? stripped[i + 2] : '';

    if (ch === '=' && next === '>') {
      addViolation(i, 'arrow-function', 'Arrow function (=>) is ES6+ syntax');
      i++;
      continue;
    }
    if (ch === '?' && next === '.' && !isDigit(next2)) {
      addViolation(i, 'optional-chaining', 'Optional chaining (?.) is ES2020 syntax');
      i++;
      continue;
    }
    if (ch === '?' && next === '?') {
      addViolation(i, 'nullish-coalescing', 'Nullish coalescing (??) is ES2020 syntax');
      i++;
      continue;
    }
    if (ch === '.' && next === '.' && next2 === '.') {
      addViolation(i, 'spread-rest', 'Spread/rest (...) is ES6+ syntax');
      i += 2;
      continue;
    }
    if (ch === '*' && next === '*') {
      addViolation(i, 'exponentiation', 'Exponentiation operator (**) is ES2016 syntax');
      i++;
      continue;
    }
  }

  // 2. Identifier / keyword checks
  const wordRe = /\b([A-Za-z_$][A-Za-z0-9_$]*)\b/g;
  let m;
  while ((m = wordRe.exec(stripped)) !== null) {
    const word = m[1];
    const idx = m.index;
    const endIdx = idx + word.length;
    const prev = prevNonWsChar(stripped, idx);
    const next = nextNonWsChar(stripped, endIdx);

    // Ignore property accesses (obj.class, obj.default) and object keys ({ class: 1 })
    const isPropertyOrKey = prev.ch === '.' || next.ch === ':';
    if (isPropertyOrKey) continue;

    if (ES6_KEYWORDS.has(word)) {
      addViolation(idx, `keyword-${word}`, ES6_KEYWORDS.get(word));
    } else if (word === 'async') {
      // Flag async function / async (...) / async ident =>
      const rest = stripped.slice(endIdx);
      if (/^\s+(?:function\b|\(|[A-Za-z_$][A-Za-z0-9_$]*\s*=>)/.test(rest) || next.ch === '(') {
        addViolation(idx, 'keyword-async', 'async function/arrow is ES2017 syntax');
      }
    } else if (word === 'for' && next.ch === '(') {
      const closeIdx = findMatchingParen(stripped, next.index);
      if (closeIdx !== -1) {
        const header = stripped.slice(next.index + 1, closeIdx);
        // Check top-level 'of' in for (...) header (not after '.')
        if (/(?:^|[\s)\]}])of\b/.test(header) && !/\.\s*of\b/.test(header)) {
          addViolation(idx, 'for-of', 'for..of loop is ES6+ syntax');
        }
      }
    } else if (word === 'function') {
      // Check parameter list for default parameters (=) or destructuring ({ or [)
      let openParenIdx = -1;
      if (next.ch === '(') {
        openParenIdx = next.index;
      } else if (isIdentStart(next.ch)) {
        const afterName = stripped.slice(next.index).match(/^[A-Za-z_$][A-Za-z0-9_$]*\s*\(/);
        if (afterName) {
          openParenIdx = next.index + afterName[0].length - 1;
        }
      }
      if (openParenIdx !== -1) {
        const closeParenIdx = findMatchingParen(stripped, openParenIdx);
        if (closeParenIdx !== -1) {
          const params = stripped.slice(openParenIdx + 1, closeParenIdx);
          for (let p = 0; p < params.length; p++) {
            const pc = params[p];
            if (pc === '{' || pc === '[') {
              addViolation(openParenIdx + 1 + p, 'destructuring-param', 'Destructuring parameter is ES6+ syntax');
              break;
            }
            if (pc === '=') {
              addViolation(openParenIdx + 1 + p, 'default-param', 'Default parameter (=) is ES6+ syntax');
              break;
            }
          }
        }
      }
    }
  }

  // 3. Destructuring declarations: var/let/const { ... } or [ ... ]
  const declDestructRe = /\b(?:var|let|const)\s*([{\[])/g;
  while ((m = declDestructRe.exec(stripped)) !== null) {
    addViolation(m.index, 'destructuring-decl', 'Destructuring declaration is ES6+ syntax');
  }

  // 4. Destructuring assignments: [a, b] = ... or ({ a, b } = ...)
  for (let i = 0; i < stripped.length; i++) {
    if (stripped[i] === '[') {
      const prev = prevNonWsChar(stripped, i);
      const isExprBracket =
        prev.ch === '' ||
        prev.ch === ';' ||
        prev.ch === '{' ||
        prev.ch === '}' ||
        prev.ch === '(' ||
        prev.ch === ',' ||
        prev.ch === '=' ||
        prev.ch === '?' ||
        prev.ch === ':';
      if (isExprBracket) {
        const closeIdx = findMatchingBracket(stripped, i);
        if (closeIdx !== -1) {
          const after = nextNonWsChar(stripped, closeIdx + 1);
          if (after.ch === '=' && stripped[after.index + 1] !== '=') {
            addViolation(i, 'destructuring-assign', 'Array destructuring assignment is ES6+ syntax');
          }
        }
      }
    }
  }

  const objDestructAssignRe = /\(\s*\{[^}]*\}\s*=(?!=)/g;
  while ((m = objDestructAssignRe.exec(stripped)) !== null) {
    addViolation(m.index, 'destructuring-assign', 'Object destructuring assignment is ES6+ syntax');
  }

  return violations;
}

export function checkEs5Source(source, filePath = '<input>') {
  const lineStarts = buildLineStarts(source);
  const violations = [];

  try {
    new vm.Script(source, { filename: filePath });
  } catch (err) {
    violations.push({
      line: 1,
      col: 1,
      rule: 'vm-syntax-error',
      message: `JavaScript syntax error: ${err && err.message ? err.message : String(err)}`
    });
  }

  const { stripped, templateViolations } = stripNonCode(source, lineStarts);
  violations.push(...templateViolations);
  violations.push(...checkStrippedEs6(stripped, lineStarts));

  violations.sort((a, b) => (a.line - b.line) || (a.col - b.col));
  return violations;
}

function collectJsFiles(targets) {
  const files = [];
  for (const target of targets) {
    const resolved = path.resolve(target);
    if (!fs.existsSync(resolved)) {
      throw new Error(`Target path does not exist: ${target}`);
    }
    const stat = fs.statSync(resolved);
    if (stat.isFile()) {
      files.push(resolved);
    } else if (stat.isDirectory()) {
      const entries = fs.readdirSync(resolved, { withFileTypes: true })
        .sort((a, b) => a.name.localeCompare(b.name));
      for (const entry of entries) {
        const full = path.join(resolved, entry.name);
        if (entry.isDirectory()) {
          files.push(...collectJsFiles([full]));
        } else if (entry.isFile() && entry.name.endsWith('.js')) {
          files.push(full);
        }
      }
    }
  }
  return files;
}

function runCli(argv) {
  const args = [];
  let runSelfTest = false;

  for (const arg of argv) {
    if (arg === '--self-test') {
      runSelfTest = true;
    } else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node check_es5.mjs [--self-test] [file-or-dir ...]');
      return 0;
    } else {
      args.push(arg);
    }
  }

  if (runSelfTest) {
    const negativeCases = [
      { name: 'let', code: 'let x = 1;' },
      { name: 'const', code: 'const y = 2;' },
      { name: 'class', code: 'class Foo {}' },
      { name: 'arrow', code: 'var fn = function() {}; var f2 = (a) => a + 1;' },
      { name: 'async-await', code: 'async function f() { await g(); }' },
      { name: 'import-export', code: 'import x from "y"; export default x;' },
      { name: 'template', code: 'var s = `hello ${x}`;' },
      { name: 'optional-chaining', code: 'var v = a?.b;' },
      { name: 'nullish', code: 'var v = a ?? b;' },
      { name: 'spread', code: 'var a = [1].concat([2]); var b = [...a];' },
      { name: 'for-of', code: 'for (var item of list) {}' },
      { name: 'default-param', code: 'function f(a, b = 1) { return a + b; }' },
      { name: 'destructuring', code: 'var { a } = obj; [x, y] = pair;' },
      { name: 'exponentiation', code: 'var p = 2 ** 3;' }
    ];
    let failedSelfTest = false;
    for (const tc of negativeCases) {
      const res = checkEs5Source(tc.code, `self-test:${tc.name}`);
      if (res.length === 0) {
        console.error(`[SELF-TEST FAIL] Expected ES6+ rejection for ${tc.name}, got PASS`);
        failedSelfTest = true;
      }
    }
    const positiveCases = [
      'var x = \'<div class="btn">let const => `tmpl`</div>\';',
      '/* class Foo {} => async await */ var re = /let|const|=>/g; var obj = { class: "a", default: 1 };',
      'var y = cond ? .5 : 1.0; for (var k in obj) { if (obj.hasOwnProperty(k)) {} }'
    ];
    for (let i = 0; i < positiveCases.length; i++) {
      const res = checkEs5Source(positiveCases[i], `self-test:es5-${i}`);
      if (res.length > 0) {
        console.error(`[SELF-TEST FAIL] False positive on valid ES5 #${i}:`, res);
        failedSelfTest = true;
      }
    }
    if (failedSelfTest) return 1;
    console.log(`[SELF-TEST PASS] ${negativeCases.length} ES6+ negative cases rejected, ${positiveCases.length} ES5 edge cases passed.`);
    if (args.length === 0) return 0;
  }

  const targets = args.length > 0 ? args : [DEFAULT_JS_DIR];
  let files;
  try {
    files = collectJsFiles(targets);
  } catch (err) {
    console.error(`[ERROR] ${err.message}`);
    return 1;
  }

  if (files.length === 0) {
    console.error(`[ERROR] No .js files found in: ${targets.join(', ')}`);
    return 1;
  }

  let totalErrors = 0;
  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    const violations = checkEs5Source(source, file);
    const rel = path.relative(process.cwd(), file) || file;
    if (violations.length === 0) {
      console.log(`[PASS] ${rel} (ES5 OK)`);
    } else {
      totalErrors += violations.length;
      console.error(`[FAIL] ${rel} (${violations.length} ES5 violation(s)):`);
      for (const v of violations) {
        console.error(`  ${rel}:${v.line}:${v.col} [${v.rule}] ${v.message}`);
      }
    }
  }

  if (totalErrors > 0) {
    console.error(`\nES5 check FAILED: ${totalErrors} violation(s) across ${files.length} file(s).`);
    return 1;
  }
  console.log(`\nES5 check PASSED: ${files.length} file(s), 0 errors.`);
  return 0;
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  process.exit(runCli(process.argv.slice(2)));
}
