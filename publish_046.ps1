$code = @"
using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

public class GitHubPublisher {
    [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("Advapi32.dll", EntryPoint = "CredFree", SetLastError = true)]
    public static extern void CredFree([In] IntPtr cred);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public uint Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetToken() {
        IntPtr credPtr;
        bool success = CredRead("GitHub - https://api.github.com/kiritokmn1403", 1, 0, out credPtr);
        if (!success) throw new Exception("Credential not found");
        try {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            byte[] bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, (int)cred.CredentialBlobSize);
            return Encoding.UTF8.GetString(bytes);
        } finally {
            CredFree(credPtr);
        }
    }

    public static HttpClient CreateClient() {
        var client = new HttpClient();
        client.Timeout = TimeSpan.FromMinutes(30);
        client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("YomiHub-ReleaseAgent", "1.0"));
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", GetToken());
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
        return client;
    }

    public static string Send(string method, string url, string jsonBody = null) {
        using (var client = CreateClient()) {
            HttpRequestMessage req = new HttpRequestMessage(new HttpMethod(method), url);
            if (jsonBody != null) {
                req.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");
            }
            var res = client.SendAsync(req).GetAwaiter().GetResult();
            string body = res.Content.ReadAsStringAsync().GetAwaiter().GetResult();
            if (!res.IsSuccessStatusCode) {
                throw new Exception(string.Format("HTTP {0} {1}: {2}", (int)res.StatusCode, res.ReasonPhrase, body));
            }
            return body;
        }
    }

    public static string UploadAsset(string uploadUrlTemplate, string filePath) {
        string fileName = Path.GetFileName(filePath);
        string uploadUrl = uploadUrlTemplate.Replace("{?name,label}", "?name=" + Uri.EscapeDataString(fileName));
        
        using (var client = CreateClient()) {
            using (var fileStream = File.OpenRead(filePath)) {
                var content = new StreamContent(fileStream);
                content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
                content.Headers.ContentLength = fileStream.Length;
                
                var res = client.PostAsync(uploadUrl, content).GetAwaiter().GetResult();
                string body = res.Content.ReadAsStringAsync().GetAwaiter().GetResult();
                if (!res.IsSuccessStatusCode) {
                    throw new Exception(string.Format("Upload failed for {0}: HTTP {1} {2}: {3}", fileName, (int)res.StatusCode, res.ReasonPhrase, body));
                }
                return body;
            }
        }
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Net.Http" -Language CSharp

$repo = "kiritokmn1403/YomiHub-Project"
$tag = "v0.4.6"
$title = "YomiHub 0.4.6 (0.4.6+38)"
$changelogPath = "d:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\0.4.6\YomiHub-0.4.6-changelog.md"
$bodyText = [System.IO.File]::ReadAllText($changelogPath)

Write-Host "Checking if release $tag already exists..."
$releasesJson = [GitHubPublisher]::Send("GET", "https://api.github.com/repos/$repo/releases")
$releases = $releasesJson | ConvertFrom-Json
$existing = $releases | Where-Object { $_.tag_name -eq $tag }

if (-not $existing) {
    Write-Host "Creating draft release $tag..."
    $createPayload = @{
        tag_name = $tag
        target_commitish = "main"
        name = $title
        body = $bodyText
        draft = $true
        prerelease = $false
    } | ConvertTo-Json

    $releaseJson = [GitHubPublisher]::Send("POST", "https://api.github.com/repos/$repo/releases", $createPayload)
    $release = $releaseJson | ConvertFrom-Json
} else {
    Write-Host "Found existing release (ID: $($existing.id))."
    $release = $existing
}

Write-Host "Release ID: $($release.id)"
Write-Host "Upload URL: $($release.upload_url)"

# List existing assets
$existingAssetsUrl = "https://api.github.com/repos/$repo/releases/$($release.id)/assets"
$existingAssetsJson = [GitHubPublisher]::Send("GET", $existingAssetsUrl)
$existingAssets = $existingAssetsJson | ConvertFrom-Json

$outputDir = "d:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\0.4.6"
$files = Get-ChildItem $outputDir -File | Where-Object { $_.Name -ne "publish_046.ps1" }

# Also include TECHNICAL_UPDATE_NOTES.md
$notesPath = "d:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\TECHNICAL_UPDATE_NOTES.md"
$allFiles = @($files)
if (Test-Path $notesPath) {
    $allFiles += (Get-Item $notesPath)
}

foreach ($f in $allFiles) {
    $matchedAsset = $existingAssets | Where-Object { $_.name -eq $f.Name }
    if ($matchedAsset) {
        if ($matchedAsset.size -eq $f.Length) {
            Write-Host "Asset $($f.Name) already uploaded and size matches ($($f.Length) bytes). Skipping."
            continue
        } else {
            Write-Host "Asset $($f.Name) exists but size mismatch ($($matchedAsset.size) vs $($f.Length)). Deleting old asset..."
            [GitHubPublisher]::Send("DELETE", "https://api.github.com/repos/$repo/releases/assets/$($matchedAsset.id)") | Out-Null
        }
    }

    Write-Host "Uploading $($f.Name) ($([math]::Round($f.Length / 1MB, 2)) MB)..." -NoNewline
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $uploadRes = [GitHubPublisher]::UploadAsset($release.upload_url, $f.FullName)
    $sw.Stop()
    $mb = [math]::Round($f.Length / 1MB, 2)
    $sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    $speed = if ($sec -gt 0) { [math]::Round($mb / $sec, 2) } else { 0 }
    Write-Host " Done ($mb MB in $sec s, ~$speed MB/s)."
}

Write-Host "All assets uploaded. Publishing release (setting draft=false, make_latest=true)..."
$publishPayload = @{
    draft = $false
    make_latest = "true"
} | ConvertTo-Json

$finalJson = [GitHubPublisher]::Send("PATCH", "https://api.github.com/repos/$repo/releases/$($release.id)", $publishPayload)
$finalRelease = $finalJson | ConvertFrom-Json
Write-Host "Release published successfully!"
Write-Host "HTML URL: $($finalRelease.html_url)"

