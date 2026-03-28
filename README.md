Script Overview

This script is designed to install the latest PowerShell 7 on a fresh Windows 11 system, including pre-OOBE deployments (before the first user login). It is fully offline-safe, automated, and cleans up after itself.

It is ideal for IT departments, system imaging, automated deployments, or lab setups where you want a consistent PowerShell 7 environment without manual intervention.

⸻

High-Level Features
	1.	Self-bypasses PowerShell execution policy so it can run on systems where script execution is restricted.
	2.	Detects Internet connectivity and chooses whether to download the latest MSI or use a cached MSI file in %TEMP%.
	3.	Deletes old cached MSI files if outdated.
	4.	Cleans old PowerShell 7 installations to ensure a fresh install.
	5.	Removes temp files, module caches, and MSI logs to prevent leftover clutter.
	6.	Performs silent installation of PowerShell 7 using msiexec.
	7.	Verifies installation by checking the installed PowerShell 7 version.
	8.	Provides a console-only summary of actions taken and the installed version.
	9.	Cleans the PowerShell session at the end (variables, functions, aliases, history, console), leaving a clean environment.

⸻

Step-by-Step Behavior

1. Execution Policy Self-Bypass
	•	On systems where script execution is restricted, the script relaunches itself with -ExecutionPolicy Bypass.
	•	This ensures it can run pre-OOBE or on locked-down environments without permanently changing the system policy.

⸻

2. Internet and Cached MSI Check
	•	Checks if the system has Internet access by attempting a quick request to https://github.com.
	•	Checks %TEMP% for an existing PowerShell 7 MSI file.
	•	Handles all scenarios:
	1.	Internet + no cached MSI → downloads the latest MSI.
	2.	Internet + cached MSI exists → compares version:
	•	If cached MSI is older, deletes and downloads the latest.
	•	If cached MSI is up-to-date, uses it.
	3.	No Internet + cached MSI exists → uses cached MSI.
	4.	No Internet + no cached MSI → displays Check Internet, waits 3 seconds, and exits.

⸻

3. Clean Old PowerShell 7 Installations
	•	Detects previous PS7 installations in C:\Program Files\PowerShell\7*.
	•	Deletes old folders recursively to prevent conflicts with the new installation.

⸻

4. Clear Module Caches and Temp Logs
	•	Deletes user-level PowerShell module caches at %LOCALAPPDATA%\Microsoft\PowerShell.
	•	Deletes system-level modules at %ProgramData%\Microsoft\PowerShell\Modules.
	•	Removes temporary MSI log files in %TEMP%.

This prevents old or conflicting modules, logs, or temp files from interfering with the new installation.

⸻

5. Silent Installation of PowerShell 7
	•	Uses msiexec.exe /i <MSI> /qn /norestart to install silently without user interaction.
	•	Deletes the downloaded MSI afterward to save space.

⸻

6. Installation Verification
	•	After installation, the script checks the installed PowerShell version using $PSVersionTable.PSVersion.
	•	This ensures that the intended version was successfully installed.

⸻

7. Console Summary

At the end, the script prints a clear plain-text summary:

Field
Description
Action Taken
Shows what the script did: used cached MSI, deleted old MSI, downloaded new MSI, etc.
Installed Version
Displays the PowerShell 7 version installed, or Failed if installation did not succeed.

No files are written, and no emojis or extra output are displayed.

⸻

8. Final Session Cleanup
	•	Removes all variables, functions, aliases, and command history created during script execution.
	•	Clears the PowerShell console (Clear-Host).
	•	After this, the session is completely clean, leaving only the newly installed PowerShell 7 environment.

⸻

Key Advantages
	1.	Pre-OOBE Ready: Runs before any user logs in.
	2.	Offline-Safe: Can install from cached MSI if no Internet is available.
	3.	Always Up-to-Date: Automatically downloads latest release if available.
	4.	Clean Environment: Removes old installations, temp files, module caches, and leaves no trace in the session.
	5.	Silent & Automated: No user interaction required; suitable for bulk deployment.
	6.	Console Summary Only: Easy to read for deployment logs without creating extra files.

⸻

Intended Use Cases
	•	Corporate imaging or deployment scripts for new Windows 11 machines.
	•	Pre-OOBE customization for OEM or IT provisioning.
	•	Ensuring consistent PowerShell 7 versions across labs or test environments.
	•	Automated setup in WinPE, unattend scripts, or first-boot tasks.
