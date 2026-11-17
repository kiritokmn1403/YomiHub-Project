# make_installer_exe.ps1: Compile the Windows GUI installer for the overlay version.
. "$PSScriptRoot\common.ps1"

$ver = ([regex]::Match((Get-Content "$KIT\overlay\pubspec.yaml" -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)')).Groups[1].Value
if (-not $ver) { throw 'Cannot read application version from overlay/pubspec.yaml' }
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$out = "$KIT\output"
$rel = "$YH\buildwin\mangayomi\build\windows\x64\runner\Release"
if (-not (Test-Path "$rel\YomiHub.exe")) {
    throw "Windows release build is missing: $rel\YomiHub.exe"
}
if ((Get-Item "$rel\YomiHub.exe").VersionInfo.ProductVersion -notlike "$ver*") {
    throw "Windows executable version does not match $ver"
}

Say "INSTALLER BUILD START: Compiling YomiHub $ver Setup (.exe)"

$srcCode = @"
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyVersion("$ver.0")]
[assembly: AssemblyFileVersion("$ver.0")]
[assembly: AssemblyProduct("YomiHub Setup")]

namespace YomiHubInstaller
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new InstallerForm());
        }
    }

    public class InstallerForm : Form
    {
        private ProgressBar progressBar;
        private Label lblStatus;
        private TextBox txtPath;
        private CheckBox chkDesktop;
        private CheckBox chkStartMenu;
        private CheckBox chkLaunch;
        private Button btnInstall;
        private Button btnBrowse;

        public InstallerForm()
        {
            this.Text = "YomiHub $ver Setup - Cài Đặt YomiHub";
            this.Size = new Size(540, 380);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;

            var banner = new Panel
            {
                Dock = DockStyle.Top,
                Height = 70,
                BackColor = Color.FromArgb(30, 30, 46)
            };
            var lblTitle = new Label
            {
                Text = "YomiHub v$ver",
                Font = new Font("Segoe UI", 16, FontStyle.Bold),
                ForeColor = Color.White,
                Location = new Point(20, 12),
                AutoSize = true
            };
            var lblSub = new Label
            {
                Text = "Trình cài đặt ứng dụng đọc truyện, xem phim và light novel đa năng",
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.FromArgb(200, 200, 220),
                Location = new Point(22, 42),
                AutoSize = true
            };
            banner.Controls.Add(lblTitle);
            banner.Controls.Add(lblSub);
            this.Controls.Add(banner);

            var lblDest = new Label
            {
                Text = "Thư mục cài đặt:",
                Location = new Point(24, 90),
                AutoSize = true,
                Font = new Font("Segoe UI", 9, FontStyle.Bold)
            };
            this.Controls.Add(lblDest);

            string defaultDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "YomiHub");
            txtPath = new TextBox
            {
                Text = defaultDir,
                Location = new Point(24, 112),
                Width = 380,
                Font = new Font("Segoe UI", 9)
            };
            this.Controls.Add(txtPath);

            btnBrowse = new Button
            {
                Text = "Duyệt...",
                Location = new Point(415, 110),
                Width = 85,
                Height = 26
            };
            btnBrowse.Click += (s, e) =>
            {
                using (var fbd = new FolderBrowserDialog())
                {
                    fbd.SelectedPath = txtPath.Text;
                    if (fbd.ShowDialog() == DialogResult.OK)
                    {
                        txtPath.Text = fbd.SelectedPath;
                    }
                }
            };
            this.Controls.Add(btnBrowse);

            chkDesktop = new CheckBox
            {
                Text = "Tạo lối tắt ngoài màn hình chính (Desktop Shortcut)",
                Checked = true,
                Location = new Point(24, 150),
                AutoSize = true
            };
            this.Controls.Add(chkDesktop);

            chkStartMenu = new CheckBox
            {
                Text = "Thêm vào danh sách Start Menu",
                Checked = true,
                Location = new Point(24, 175),
                AutoSize = true
            };
            this.Controls.Add(chkStartMenu);

            chkLaunch = new CheckBox
            {
                Text = "Khởi chạy YomiHub sau khi cài đặt xong",
                Checked = true,
                Location = new Point(24, 200),
                AutoSize = true
            };
            this.Controls.Add(chkLaunch);

            lblStatus = new Label
            {
                Text = "Sẵn sàng cài đặt.",
                Location = new Point(24, 235),
                Width = 475,
                ForeColor = Color.Gray
            };
            this.Controls.Add(lblStatus);

            progressBar = new ProgressBar
            {
                Location = new Point(24, 255),
                Width = 475,
                Height = 20
            };
            this.Controls.Add(progressBar);

            btnInstall = new Button
            {
                Text = "Cài Đặt Ngay",
                Location = new Point(380, 295),
                Width = 120,
                Height = 32,
                BackColor = Color.FromArgb(79, 163, 255),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9, FontStyle.Bold)
            };
            btnInstall.Click += DoInstall;
            this.Controls.Add(btnInstall);
        }

        private void DoInstall(object sender, EventArgs e)
        {
            btnInstall.Enabled = false;
            btnBrowse.Enabled = false;
            txtPath.Enabled = false;

            string targetDir = txtPath.Text.Trim();
            if (string.IsNullOrEmpty(targetDir))
            {
                MessageBox.Show("Vui lòng chọn thư mục cài đặt hợp lệ.", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                btnInstall.Enabled = true;
                return;
            }

            try
            {
                targetDir = Path.GetFullPath(targetDir);
                lblStatus.Text = "Đang kiểm tra và đóng các phiên bản YomiHub đang chạy...";
                foreach (var running in Process.GetProcessesByName("YomiHub"))
                {
                    using (running)
                    {
                        var installedExe = Path.Combine(targetDir, "YomiHub.exe");
                        if (!string.Equals(running.MainModule.FileName, installedExe, StringComparison.OrdinalIgnoreCase)) continue;
                        running.CloseMainWindow();
                        if (!running.WaitForExit(5000))
                            throw new IOException("Hãy đóng YomiHub trong thư mục cài đặt rồi thử lại.");
                    }
                }

                lblStatus.Text = "Đang chuẩn bị thư mục đích...";
                progressBar.Value = 10;
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                lblStatus.Text = "Đang sao chép các tệp YomiHub...";
                progressBar.Value = 25;

                string currentDir = AppDomain.CurrentDomain.BaseDirectory;
                string zipPath = Path.Combine(currentDir, "YomiHub-$ver-windows-x64.zip");
                if (!File.Exists(zipPath))
                {
                    zipPath = Path.Combine(currentDir, "app.zip");
                }

                var resStream = Assembly.GetExecutingAssembly().GetManifestResourceStream("AppZip");
                if (resStream != null)
                {
                    lblStatus.Text = "Đang giải nén gói ứng dụng tích hợp...";
                    using (var archive = new ZipArchive(resStream))
                    {
                        int total = archive.Entries.Count;
                        int cur = 0;
                        foreach (var entry in archive.Entries)
                        {
                            cur++;
                            string cleanName = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                            string destFile = SafeDestination(targetDir, cleanName);
                            if (cleanName.EndsWith(Path.DirectorySeparatorChar.ToString()) || string.IsNullOrEmpty(entry.Name))
                            {
                                Directory.CreateDirectory(destFile);
                            }
                            else
                            {
                                string parent = Path.GetDirectoryName(destFile);
                                if (!string.IsNullOrEmpty(parent)) Directory.CreateDirectory(parent);
                                entry.ExtractToFile(destFile, true);
                            }
                            if (cur % 25 == 0 || cur == total)
                            {
                                progressBar.Value = 25 + (int)((50.0 * cur) / total);
                                Application.DoEvents();
                            }
                        }
                    }
                }
                else if (File.Exists(zipPath))
                {
                    lblStatus.Text = "Đang giải nén gói ứng dụng từ tệp ZIP...";
                    using (var archive = ZipFile.OpenRead(zipPath))
                    {
                        int total = archive.Entries.Count;
                        int cur = 0;
                        foreach (var entry in archive.Entries)
                        {
                            cur++;
                            string cleanName = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                            string destFile = SafeDestination(targetDir, cleanName);
                            if (cleanName.EndsWith(Path.DirectorySeparatorChar.ToString()) || string.IsNullOrEmpty(entry.Name))
                            {
                                Directory.CreateDirectory(destFile);
                            }
                            else
                            {
                                string parent = Path.GetDirectoryName(destFile);
                                if (!string.IsNullOrEmpty(parent)) Directory.CreateDirectory(parent);
                                entry.ExtractToFile(destFile, true);
                            }
                            if (cur % 25 == 0 || cur == total)
                            {
                                progressBar.Value = 25 + (int)((50.0 * cur) / total);
                                Application.DoEvents();
                            }
                        }
                    }
                }
                else
                {
                    throw new FileNotFoundException("Không tìm thấy gói ứng dụng để cài đặt.");
                }

                progressBar.Value = 70;
                lblStatus.Text = "Đang tạo các lối tắt...";

                string exePath = Path.Combine(targetDir, "YomiHub.exe");
                if (!File.Exists(exePath))
                {
                    // Search subfolder
                    var exes = Directory.GetFiles(targetDir, "YomiHub.exe", SearchOption.AllDirectories);
                    if (exes.Length > 0) exePath = exes[0];
                }

                if (chkDesktop.Checked)
                {
                    CreateShortcut(
                        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "YomiHub.lnk"),
                        exePath,
                        "YomiHub - Free Open-Source Reader & Streamer"
                    );
                }

                if (chkStartMenu.Checked)
                {
                    string startDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "YomiHub");
                    if (!Directory.Exists(startDir)) Directory.CreateDirectory(startDir);
                    CreateShortcut(
                        Path.Combine(startDir, "YomiHub.lnk"),
                        exePath,
                        "YomiHub - Free Open-Source Reader & Streamer"
                    );
                }

                // Write uninstaller script
                string uninstallerCmd = Path.Combine(targetDir, "Uninstall.cmd");
                File.WriteAllText(uninstallerCmd, 
                    "@echo off\r\n" +
                    "echo Dang go cai dat YomiHub...\r\n" +
                    "taskkill /f /im YomiHub.exe >nul 2>&1\r\n" +
                    "del /q /f \"%USERPROFILE%\\Desktop\\YomiHub.lnk\" >nul 2>&1\r\n" +
                    "rmdir /s /q \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\YomiHub\" >nul 2>&1\r\n" +
                    "echo Xoa thanh cong cac loi tat YomiHub.\r\n" +
                    "pause\r\n"
                );

                progressBar.Value = 100;
                lblStatus.Text = "Cài đặt hoàn tất thành công!";

                if (chkLaunch.Checked && File.Exists(exePath))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = exePath,
                        WorkingDirectory = Path.GetDirectoryName(exePath)
                    });
                }

                MessageBox.Show("Cài đặt YomiHub v$ver thành công!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Information);
                this.Close();
            }
            catch (Exception ex)
            {
                lblStatus.Text = "Lỗi trong quá trình cài đặt!";
                MessageBox.Show("Lỗi: " + ex.Message, "Lỗi cài đặt", MessageBoxButtons.OK, MessageBoxIcon.Error);
                btnInstall.Enabled = true;
                btnBrowse.Enabled = true;
                txtPath.Enabled = true;
            }
        }

        private static string SafeDestination(string directory, string entryName)
        {
            string root = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            string destination = Path.GetFullPath(Path.Combine(root, entryName));
            if (!destination.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                throw new IOException("Gói cài đặt chứa đường dẫn nằm ngoài thư mục đích.");
            return destination;
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string description)
        {
            try
            {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath = targetPath;
                shortcut.WorkingDirectory = Path.GetDirectoryName(targetPath);
                shortcut.Description = description;
                shortcut.Save();
            }
            catch { }
        }
    }
}
"@

$csFile = "$YH\buildwin\Installer.cs"
Set-Content -Path $csFile -Value $srcCode -Encoding UTF8

$exeOut = "$out\YomiHub-$ver-windows-x64-Setup.exe"
Say "Compiling $exeOut via csc.exe"
$icoPath = "$YH\buildwin\mangayomi\windows\runner\resources\app_icon.ico"
$zipFile = "$out\YomiHub-$ver-windows-x64.zip"
if (-not (Test-Path -LiteralPath $zipFile)) { throw "Application archive is missing: $zipFile" }

$cscArgs = [System.Collections.Generic.List[string]]::new()
$cscArgs.Add("/target:winexe")
$cscArgs.Add("/optimize+")
$cscArgs.Add("/platform:x64")
$cscArgs.Add("/reference:System.Windows.Forms.dll")
$cscArgs.Add("/reference:System.Drawing.dll")
$cscArgs.Add("/reference:System.IO.Compression.dll")
$cscArgs.Add("/reference:System.IO.Compression.FileSystem.dll")

if (Test-Path $icoPath) {
    $cscArgs.Add("/win32icon:$icoPath")
}
if (Test-Path $zipFile) {
    Say "Embedding application archive ($zipFile) into installer..."
    $cscArgs.Add("/resource:$zipFile,AppZip")
}
$cscArgs.Add("/out:$exeOut")
$cscArgs.Add($csFile)

& $csc $cscArgs

if ($LASTEXITCODE -eq 0 -and (Test-Path $exeOut)) {
    Say ("INSTALLER EXE DONE: {0} ({1:N1} MB)" -f (Split-Path $exeOut -Leaf), ((Get-Item $exeOut).Length/1MB))
} else {
    throw "csc compile failed with exit code $LASTEXITCODE"
}
