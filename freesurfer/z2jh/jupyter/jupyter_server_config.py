# Copy the shared FreeSurfer tutorial data to the user's home once, in the
# background, when their server starts (see fs-tutorial-data). This must never
# delay or break the server start.
import subprocess
import threading

try:
    _p = subprocess.Popen(
        ["/usr/local/bin/fs-tutorial-data", "setup", "--auto", "--background"],
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True)
    threading.Thread(target=_p.wait, daemon=True).start()  # reap it, no zombie
except Exception:
    pass
