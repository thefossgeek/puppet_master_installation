puppet_master_installation
Bash Script to Install and Configure Puppet Master.

1). Clone the repo
#git clone https://github.com/thefossgeek/puppet_master_installation.git 

2). Copy the puppet_master_installation repo to your puppet master server.
#scp -r /<your_path>/puppet_master_installation user@your_puppet_master_ip:

3). Now login to your puppet master server
#ssh user@your_puppet_master_ip

4). Go to the directory where you have puppet_master_installation 
#cd /<your_path>/puppet_master_installation

5). Modify the install.conf file. You have to edit puppet master ip address, hostname and aliases.
#vim install.conf 
puppet_master_ip=10.209.224.129 
canonical_hostname=puppetmastersg.sgosbc.com
aliases=puppetmastersg

6), 
