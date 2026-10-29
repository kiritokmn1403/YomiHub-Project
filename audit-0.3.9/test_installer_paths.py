from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
script = (root.parent / 'make_installer_exe.ps1').read_text(encoding='utf-8-sig')
method = script.split('        private static string SafeDestination', 1)[1].split('        private static void CreateShortcut', 1)[0]
source = '''using System; using System.IO;
class InstallerPathTests {
private static string SafeDestination''' + method + r'''
static void Main() {
  string root = Path.Combine(Path.GetTempPath(), "yomihub-path-test");
  string expected = Path.Combine(root, "data", "app.so");
  if (SafeDestination(root, @"data\app.so") != expected) throw new Exception("Valid entry rejected");
  foreach (string path in new[] { @"..\escape.txt", @"data\..\..\escape.txt", @"C:\escape.txt" }) {
    bool rejected = false;
    try { SafeDestination(root, path); } catch (IOException) { rejected = true; }
    if (!rejected) throw new Exception("Unsafe entry accepted: " + path);
  }
  Console.WriteLine("4 installer destination path checks passed.");
}
}'''
cs = root / 'InstallerPathTests.cs'
exe = root / 'InstallerPathTests.exe'
cs.write_text(source, encoding='utf-8-sig')
subprocess.run([
    r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
    '/nologo', f'/out:{exe}', str(cs),
], check=True)
subprocess.run([str(exe)], check=True)
