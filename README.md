# Blocking_Ip-s_With-AbuseIPDB---External-Feed-to-Fortigate
Here we fetch the Abuse Ip's from abuseIPDB using script.

# 1. Setup following in Wazuh Server or any as your convenience - 

    sudo systemctl status httpd #for Apache

    sudo systemctl start httpd

    sudo systemctl enable httpd

add our provided script inside /var/ossec/etc/list/(create folder)/fetching_script.sh

NOTE: This script will fetch 1000 iP's and every time it fetches new it removes dublicate Ip's and add only fresh new ip's. After reaching list to 10000 IP's, it will remove old once and adjust with latest 10000 IP's.

NOTE: Make sure to chnage the abuseIPDB api key in script.

then give it executable permission and run the script.

    chmod +x fetching_script.sh

**** Also set Crontab for this script to fetch new IP's on daily basis. ****

After run this script will generate a list of abuse ip's in list folder and one is /var/www/html/blocked_ips.txt

# 2. Firewall side. ( Fortigate )

1. Creating Feed and policy for deny traffic from malicious ip's.
2. Go to Security Fabric --> External Connectors --> Create new --> Threat Feeds --> IP Address

   Name : AbuseIPDBFEED

   URI of external Source: http://wazuh_ip/blocked_ips.txt

   disable http authentication

   Refresh Rate/interval: any of our choice ex. 5 Minutes

   status enable

   ok

3. Policy Creation :

   Name: Any of your choice
   Incoming: Wan1
   Outgoing internal
   source: AbuseIPDBFEED
   Destination: all
   Action: DENY
   Enable this policy

   ok.

   
