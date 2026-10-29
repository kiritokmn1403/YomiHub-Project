from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent
sys.path.insert(0, str(root / 'test-tools'))
import imageio_ffmpeg

target = root / 'fixtures' / 'YomiHub-039-video-test.mp4'
subprocess.run([
    imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-hide_banner', '-loglevel', 'error',
    '-f', 'lavfi', '-i', 'testsrc2=size=640x360:rate=10',
    '-t', '180', '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '30',
    '-threads', '2', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an', str(target),
], check=True)
subprocess.run([
    imageio_ffmpeg.get_ffmpeg_exe(), '-v', 'error', '-i', str(target),
    '-f', 'null', '-',
], check=True)
print(f'Created and decoded 180-second test video: {target.name} ({target.stat().st_size} bytes)')
