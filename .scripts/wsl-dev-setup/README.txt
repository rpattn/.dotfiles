WSL Debian development setup
============================

Run these inside Debian, in order:

  chmod +x ./*.sh
  ./00-base-tools.sh
  ./10-git-and-ssh.sh "Robert Patton" "YOUR_GITHUB_EMAIL"
  ./20-language-runtimes.sh
  source ~/.bashrc
  ./30-check-setup.sh

The Git/SSH script will copy your public SSH key to the Windows clipboard when
clip.exe is available. Add it to GitHub under Settings -> SSH and GPG keys.

Keep Linux repositories under ~/src rather than /mnt/c for better performance.

Docker is not installed by these scripts. Install Docker Desktop on Windows and
enable Settings -> Resources -> WSL Integration -> Debian.
