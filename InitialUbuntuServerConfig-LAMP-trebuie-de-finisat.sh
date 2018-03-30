#!/bin/bash
# Made with love to be executed on an Ubuntu 16.04 LTS droplet

# Checking if the script is running as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

# VARIABLES SECTION
# -----------------------------------

# Sources.list file
slist=/etc/apt/sources.list
# SSH port
sshp=7539
# Installation log
rlog=~/installation.log
# Backup extension
bckp=bckp;
# Shortenned /dev/null
dn=/dev/null 2>&1

# Echoes that there is no X file
nofile_echo () {
	echo -e "\e[31mThere is no file named:\e[0m \e[1m\e[31m$@\e[0m";
}

# Echoes a standard message
std_echo () {
	echo -e "\e[32mPlease check it manually.\e[0m";
	echo -e "\e[1m\e[31mThis step stops here.\e[0m";
}

blnk_echo() {
	echo "" >> $rlog
}

# Echoes activation of a specific application option ($@)
enbl_echo () {
  echo -e "Activating \e[1m\e[34m$@\e[0m ...";
}

# Echoes that a specific application ($@) is being updated
upd_echo () {
  echo -e "Updating \e[1m\e[34m$@\e[0m application ...";
}

scn_echo () {
  echo -e "\e[1m\e[34m$@\e[0m is scanning the OS ..." >> $rlog
}

sctn_echo () {
	echo -e "\e[1m\e[33m$@\e[0m\n==================================================================================================" >> $rlog
}

# Echoes that a specific application ($@) is being installed
inst_echo () {
  echo -e "Installing \e[1m\e[34m$@\e[0m" >> $rlog
}

# Backing up a given ($@) file/directory
bckup () {
	echo -e "Backing up: \e[1m\e[34m$@\e[0m ..." >> $rlog
	cp -r $@ $@_$(date +"%m-%d-%Y-%M")."$bckp";
}

# Updates/upgrades the system
up () {
  sctn_echo UPDATES
  upvar="update upgrade dist-upgrade";
  for upup in $upvar; do
    echo -e "Executing \e[1m\e[34m$upup\e[0m" >> $rlog
    #apt-get -yqq $upup > /dev/null 2>&1 >> $rlog
    DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" $upup >> $rlog
  done
  blnk_echo
}

# Installation
inst () {
	apt-get -yqqf install $@ > /dev/null >> $rlog
	blnk_echo
}

# ------------------------------------------
# END VARIABLES SECTION


## UFW
sctn_echo FIREWALL "(UFW)"

bckup /etc/ufw/ufw.conf;





















(ufw limit $sshp/tcp && ufw --force enable) >> $rlog

blnk_echo


# END: UFW configuration section


## Updating/upgrading
up;


## Installing necessary CLI apps
sctn_echo INSTALLATION

# The list of the apps
appcli="arp-scan clamav clamav-daemon clamav-freshclam curl git glances htop iptraf mc ntp ntpdate rcconf rig screen shellcheck sysbench sysv-rc-conf tmux unattended-upgrades whois"

# The main multi-loop for installing apps/libs
for a in $appcli; do
	inst_echo $a;
	inst $a;
done

blnk_echo


# ClamAV section: configuration and the first scan
sctn_echo ANTIVIRUS "(Clam-AV)" >> $rlog

clmcnf=/etc/clamav/freshclam.conf
rprtfldr=~/ClamAV-Reports

bckup $clmcnf;
mkdir -p $rprtfldr;

# Enabling "SafeBrowsing true" mode
enbl_echo SafeBrowsing >> $rlog
echo "SafeBrowsing true" >> $clmcnf;

# Restarting CLAMAV Daemons
/etc/init.d/clamav-daemon restart && /etc/init.d/clamav-freshclam restart;
# clamdscan -V s

# Scanning the whole system and palcing all the infected files list on a particular file
scn_echo ClamAv >> $rlog
# This one throws any kind of warnings and errors: clamscan -r / | grep FOUND >> $rprtfldr/clamscan_first_scan.txt >> $rlog
clamscan --recursive --no-summary --infected / 2>/dev/null | grep FOUND >> $rprtfldr/clamscan_first_scan.txt;

# Crontab: The daily scan
# This way, Anacron ensures that if the computer is off during the time interval when it is supposed to be scanned by the daemon, it will be scanned next time it is turned on, no matter today or another day.
echo -e "Creating a \e[1m\e[34mcronjob\e[0m for the ClamAV ..." >> $rlog
echo -e '#!/bin/bash\n\n/usr/bin/freshclam --quiet;\n/usr/bin/clamscan --recursive --exclude-dir=/media/ --no-summary --infected / 2>/dev/null >> '$rprtfldr'/clamscan_daily_$(date +"%m-%d-%Y").txt;' >> /etc/cron.daily/clamscan.sh && chmod 755 /etc/cron.daily/clamscan.sh;

blnk_echo

# # END: ClamAV section: configuration and the first scan
zz

echo "Everything finished!!!" >> $rlog
blnk_echo

exit 0;
