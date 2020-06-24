#!/bin/bash

# Remastered with sweat and love by Profor Ivan on 2020-06-24. It is based on a earlier version under the name InitialUbuntuServerConfig.sh, also made by me somewhere in early 2017.
# To be executed on an Ubuntu 16.04 guest machine

# Run the script as root!


## VARIABLES
## -----------------------------------

# Define the secondary user
usr=(iprofor)

# SSH port
sshp=28893

# SSHD config file
sshdc=/etc/ssh/sshd_config

# LoginGraceTime
sshlgt=1440m


blnk_echo() {
  echo ""
}

# Installation module
inst () {
  apt-get -yqqf install $@
  blnk_echo
}

sctn_echo () {
  echo -e "\e[1m\e[33m$@\e[0m\n=================================================================================================="
}

# Backing up a given ($@) file/directory
bckup () {
  echo -e "Backing up: \e[1m\e[34m$@\e[0m ..."
  cp -r $@ $@_$(date +"%m-%d-%Y").bckp
}

## ------------------------------------------
## END: VARIABLES



## THE SCRIPT


## UFW
blnk_echo;
sctn_echo FIREWALL "(UFW)";

bckup /etc/ufw/ufw.conf;

# Disabling IPV6 in UFW && Opening $sshp/tcp and Limiting incomming connections to the SSH port
(echo "IPV6=no" >> /etc/ufw/ufw.conf && ufw limit $sshp/tcp && ufw --force enable);
blnk_echo;


## SSHD CONFIG
sctn_echo SSHD CONFIG;
bckup $sshdc;
blnk_echo;

echo "Configuring SSHD Daemon ...";

# Switching default SSH port to $sshp && changing LoginGraceTime to 24h (1440m) && also enabling #Banner /etc/issue.net
sed -i -re 's/^(Port)([[:space:]]+)22/\1\2'$sshp'/' -e 's/^(LoginGraceTime)([[:space:]]+)120/\1\2'$sshlgt'/' -e 's/^(\#)(Banner)([[:space:]]+)(.*)/\2\3\4/' $sshdc;

systemctl restart ssh;


## Unattended-Upgrades configuration
blnk_echo
sctn_echo AUTOUPDATES "(Unattended-Upgrades)"

unat20=/etc/apt/apt.conf.d/20auto-upgrades;
unat50=/etc/apt/apt.conf.d/50unattended-upgrades;
unat10=/etc/apt/apt.conf.d/10periodic;

# Cheking the existence of the $unat20, $unat50, $unat10 configuration files
if [[ -f $unat20 ]] && [[ -f $unat50 ]] && [[ -f $unat10 ]]; then
  
  for i in $unat20 $unat50 $unat10; do
    bckup $i && mv $i*.bckp ~;
  done
  
  
  # Inserting the right values into it
  echo "APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
  APT::Periodic::Verbose "2";" > $unat20
  
  
  # Checking if line for security updates is uncommented, by default it is
  if [[ $(cat $unat50 | grep -wx '[[:space:]]"${distro_id}:${distro_codename}-security";') ]]; then
    
    chg_unat10;
  else
    echo "
// Automatically upgrade packages from these (origin:archive) pairs
Unattended-Upgrade::Allowed-Origins {
	"${distro_id}:${distro_codename}";
	"${distro_id}:${distro_codename}-security";
	// Extended Security Maintenance; doesn't necessarily exist for
	// every release and this system may not have it installed, but if
	// available, the policy for updates is such that unattended-upgrades
	// should also install from here by default.
	"${distro_id}ESM:${distro_codename}";
	//	"${distro_id}:${distro_codename}-updates";
	//	"${distro_id}:${distro_codename}-proposed";
	//	"${distro_id}:${distro_codename}-backports";
};

// List of packages to not update (regexp are supported)
Unattended-Upgrade::Package-Blacklist {
	//	"vim";
	//	"libc6";
	//	"libc6-dev";
	//	"libc6-i686";
};

// This option allows you to control if on a unclean dpkg exit
// unattended-upgrades will automatically run
//   dpkg --force-confold --configure -a
// The default is true, to ensure updates keep getting installed
//Unattended-Upgrade::AutoFixInterruptedDpkg "false";

// Split the upgrade into the smallest possible chunks so that
// they can be interrupted with SIGUSR1. This makes the upgrade
// a bit slower but it has the benefit that shutdown while a upgrade
// is running is possible (with a small delay)
//Unattended-Upgrade::MinimalSteps "true";

// Install all unattended-upgrades when the machine is shuting down
// instead of doing it in the background while the machine is running
// This will (obviously) make shutdown slower
//Unattended-Upgrade::InstallOnShutdown "true";

// Send email to this address for problems or packages upgrades
// If empty or unset then no email is sent, make sure that you
// have a working mail setup on your system. A package that provides
// 'mailx' must be installed. E.g. "user@example.com"
//Unattended-Upgrade::Mail "root";

// Set this value to "true" to get emails only on errors. Default
// is to always send a mail if Unattended-Upgrade::Mail is set
//Unattended-Upgrade::MailOnlyOnError "true";

// Do automatic removal of new unused dependencies after the upgrade
// (equivalent to apt-get autoremove)
//Unattended-Upgrade::Remove-Unused-Dependencies "false";

// Automatically reboot *WITHOUT CONFIRMATION*
//  if the file /var/run/reboot-required is found after the upgrade
//Unattended-Upgrade::Automatic-Reboot "false";

// If automatic reboot is enabled and needed, reboot at the specific
// time instead of immediately
//  Default: "now"
//Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Use apt bandwidth limit feature, this example limits the download
// speed to 70kb/sec
    //Acquire::http::Dl-Limit "70";" > $unat50
    
    chg_unat10;
  fi
  
  # The results of unattended-upgrades will be logged to /var/log/unattended-upgrades.
  # For more tweaks nano /etc/apt/apt.conf.d/50unattended-upgrades
  
  blnk_echo
  
else
  nofile_echo $unat20 or $unat50 or $unat10
  std_echo;
fi

blnk_echo

## END: Unattended-Upgrades configuration


