import os
import time

logos_dir = 'assets/logos'
if os.path.exists(logos_dir):
    files = [os.path.join(logos_dir, f) for f in os.listdir(logos_dir)]
    # sort by modification time descending
    files_with_time = [(f, os.path.getmtime(f)) for f in files if os.path.isfile(f)]
    files_with_time.sort(key=lambda x: x[1], reverse=True)
    
    print("Most recently modified files:")
    now = time.time()
    for f, t in files_with_time[:15]:
        age_seconds = now - t
        print(f"  {os.path.basename(f)}: modified {age_seconds:.1f} seconds ago (size: {os.path.getsize(f)} bytes)")
else:
    print("logos directory does not exist!")
