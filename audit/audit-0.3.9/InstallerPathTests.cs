using System; using System.IO;
class InstallerPathTests {
private static string SafeDestination(string directory, string entryName)
        {
            string root = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            string destination = Path.GetFullPath(Path.Combine(root, entryName));
            if (!destination.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                throw new IOException("Gói cài đặt chứa đường dẫn nằm ngoài thư mục đích.");
            return destination;
        }


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
}