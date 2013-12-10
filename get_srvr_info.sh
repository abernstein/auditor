################################################################################
#
# This Script is intended to be used in any server environmet via configuration
# A list of known services, user/groups, working directories will be leveraged
# by the application to audit the server.
#
# @category    Sysadmin
# @package     Audit
# @subpackage  Server
# @copyright   Copyright [c] 2012 GoDaddy.com
#
# @author Aaron Bernstein <abernstein@godaddy.com>
#
# @todo
#
# @depends srvr_config.sh   Configuration file with list of known users/services
# @depends listusers.sh     Script for listing users
################################################################################

#!/bin/bash

# Load Configuration Settings
config_file="srvr_config.sh"
source ./${config_file}

listusers_file="./includes/list_users.sh"


################################################################################
# Genral Functions
divider="################################################################################";
appender=${divider//#/+};

function create_header {
    echo -e "\n$divider\n$1\n$divider"
}

################################################################################
create_header "Server Audit"
echo -e "This is a general audit performed on the server to report on certain specifics\n"
echo "Hostname: `hostname`"
echo "Requested: `date`"

echo -e "\nEvaluate / against list of known users and services defined in the ${config_file}"
echo -e "${appender}\nUsers: ${known_users[@]}\n\nServices: ${known_services[@]}\n${appender}"

################################################################################
create_header "List Users"
source "${listusers_file}"

################################################################################
create_header "Certificates"
CERTS=`find / -xdev -noleaf -type f -name *.pem -or -name *.crt`
for i in $CERTS; do echo $i; done;

################################################################################
create_header "CronJobs"
ls -1t /etc/cron.*

################################################################################
create_header "Packages"
yum repolist

echo -e "\nList Installed Packages"
rpm -qa "${known_services[@]}" | sort

################################################################################
create_header "Other Installed Components Owned by Known Users"
for i in "${known_users[@]}"; do find /var -maxdepth 1 -user $i; done;

################################################################################
create_header "Running Services"
running_services=`/sbin/service --status-all | grep -i "running"`
echo -e "${running_services}"
#for k in $running_services; do echo -e "${k}\n"; done

echo -e "\nEvaluate services with chkconfig runlevel:3 against list of known services"
echo -e "${appender}\n${known_services[@]}\n${appender}";

runlvl3_services=`/sbin/chkconfig --list | grep 3:on | cut -f 1 | sort -f | tr "[:upper:]" "[:lower:]"`
for j in $runlvl3_services; do 
  for h in "${known_services[@]}"; do
    if echo $j | grep -q "$h"; then
      echo $j;
###############################################################################
      case $j in
        'httpd' )
          create_header "All Apache Configurations"
          ls -1t /etc/httpd/conf*

          create_header "Current Running Apache Configurations"
          /usr/sbin/httpd -S

          create_header "HTTPD Log Files"
          ls -1 /var/log/httpd/*_log | sort -u;

          create_header "Certificate Usage"
          grep -ir "crt" /etc/httpd/conf /etc/httpd/conf.d;
          ;;
      esac
    fi;
  done;
done;
