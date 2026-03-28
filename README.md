This script is designed for fresh deployments of Windows 11 (pre-OOBE) to ensure that the latest PowerShell 7 is installed cleanly and silently. It handles online and offline scenarios, automatically cleans up old installations and caches, and provides a clear console summary of what was done.

It is fully pre-OOBE friendly, meaning it can be run before the first user logs in, making it ideal for IT imaging, automated setups, or controlled deployments.

⸻

Detailed Functionality

1. Internet & Cached MSI Pre-Check
	•	The script first checks if there is an active Internet connection by attempting a request to https://github.com.
	•	It also checks the %TEMP% folder for a cached PowerShell 7 MSI file.
	•	Three possible scenarios are handled:
	1.	Internet available, no cached MSI → downloads the latest MSI.
	2.	Internet available, cached MSI exists → compares cached version to latest release:
	•	If cached MSI is older, deletes it and downloads the new one.
	•	If cached MSI is up-to-date, uses it.
	3.	No Internet, cached MSI exists → uses cached MSI for installation.
	4.	No Internet, no cached MSI → displays "Check Internet", waits 3 seconds, and exits.

This ensures the script works offline if a cached installer exists while always keeping installations up-to-date when Internet is available.

⸻

2. Clean Removal of Old PowerShell 7 Versions
	•	Detects any existing PowerShell 7 installations in C:\Program Files\PowerShell\7*.
	•	Deletes old installations recursively to avoid conflicts with the new installation.
	•	Ensures a fresh installation environment without leftover files or settings.

⸻

3. Clearing Local and System PowerShell Caches
	•	Removes user-level module caches at %LOCALAPPDATA%\Microsoft\PowerShell.
	•	Removes system-level modules at %ProgramData%\Microsoft\PowerShell\Modules.
	•	Deletes temporary log files in %TEMP%.

This prevents old modules, logs, or temp files from causing conflicts or unnecessary disk usage.

⸻

4. MSI Download and Installation
	•	If required, the script downloads the latest PowerShell 7 MSI from the official GitHub release page.
	•	Installs PowerShell silently using msiexec /i /qn /norestart — no user interaction is needed.
	•	After installation, any newly downloaded MSI is deleted to save space.

⸻

5. Version Verification
	•	After installation, the script checks the installed PowerShell version using $PSVersionTable.PSVersion.
	•	This ensures that the intended version is installed correctly.

⸻

6. Console Summary

At the end, the script prints a plain-text summary showing:

Field	Meaning
Action Taken	What the script did, e.g.:- "Used cached MSI (latest)"- "Deleted old cached MSI and downloaded latest"- "Used cached MSI (offline, version X.X.X)"- "Downloaded latest MSI"
Installed Version	The actual PowerShell version installed, or "Failed" if installation did not complete

No files are written, no logs or emojis — everything is console-only, making it ideal for deployment logs or watching progress in real-time.

⸻

Key Advantages
	1.	Pre-OOBE Ready: Runs before first user login.
	2.	Online & Offline Capable: Automatically chooses between cached MSI and online download.
	3.	Always Up-to-Date: Deletes outdated cached MSIs and fetches the latest release when Internet is available.
	4.	Clean Install: Removes old versions, clears caches and temp files.
	5.	Silent & Automated: No user interaction required.
	6.	Clear Feedback: Console summary provides an instant report of actions and installed version.

⸻

Use Case Examples
	•	IT departments preparing Windows 11 images for deployment.
	•	Automated setup scripts for new machines in a corporate or lab environment.
	•	Pre-OOBE customization scripts for OEM or IT provisioning.
	•	Ensuring consistent PowerShell 7 versions across multiple systems.
