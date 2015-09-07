#!/bin/bash 

tmp_path="/tmp"

cur_dir=`pwd`

puppet_pkg_repo="puppetlabs-release-trusty.deb"

puppet_conf_file="/etc/puppet/puppet.conf"

conf_file="${cur_dir}/install.conf"

# Exit on any errors so that errors don't compound
function die_with_error {

    local line_num
    local err_msg

    line_num="$1"
    err_msg="$2"

    echo "ERROR:${line_num}:${err_msg}" >&2
    exit 1
}

cmd_apt_get=$(which apt-get)
if [ $? -ne 0 ]; then
    cmd_apt_get=/usr/bin/apt-get
fi

cmd_dpkg=$(which dpkg)
if [ $? -ne 0 ]; then
    cmd_dpkg=/usr/bin/dpkg
fi

cmd_wget=$(which wget)
if [ $? -ne 0 ]; then
    cmd_wget=/usr/bin/wget
fi

cmd_service=$(which service)
if [ $? -ne 0 ]; then
    cmd_service=/usr/sbin/service
fi

cmd_ln=$(which ln)
if [ $? -ne 0 ]; then
    cmd_ln=/bin/ln
fi

cmd_cp=$(which cp)
if [ $? -ne 0 ]; then
    cmd_cp=/bin/cp
fi

cmd_sed=$(which sed)
if [ $? -ne 0 ]; then
    cmd_sed=/bin/sed
fi

if [ ! -f "$conf_file" ]; then
	die_with_error "$LINENO" "$conf_file no such file or directory."
fi

puppet_master_ip=`/bin/cat $conf_file | /bin/grep 'puppet_master_ip=' | /usr/bin/cut -d '=' -f2 | /bin/sed 's/^ *//'`
if test -z $puppet_master_ip
then
	die_with_error "$LINENO" "puppet_master_ip not configured in $conf_file. Please configure $conf_file."
fi

canonical_hostname=`/bin/cat $conf_file | /bin/grep 'canonical_hostname=' | /usr/bin/cut -d '=' -f2 | /bin/sed 's/^ *//'`
if test -z $canonical_hostname
then
	die_with_error "$LINENO" "canonical_hostname not configured in $conf_file. Please configure $conf_file."
fi

aliases=`/bin/cat $conf_file | /bin/grep 'aliases=' | /usr/bin/cut -d '=' -f2 | /bin/sed 's/^ *//'`
if test -z $aliases
then
	die_with_error "$LINENO" "aliases not configured in $conf_file. Please configure $conf_file."
fi

$cmd_sed -i '/127.0.1.1/d' /etc/hosts

## Configure Puppetmaster host entry and hostname.
/bin/echo $puppet_master_ip $canonical_hostname $aliases >> /etc/hosts

/bin/echo $aliases > /etc/hostname

/sbin/sysctl kernel.hostname=${aliases}

function apt_get_update {
	
	DEBIAN_FRONTEND=noninteractive "${cmd_apt_get}" update --assume-yes
}

function dpkg_install {
	
	DEBIAN_FRONTEND=noninteractive "${cmd_dpkg}" --install "$@"
}

function apt_get_install {

	DEBIAN_FRONTEND=noninteractive "${cmd_apt_get}" install --assume-yes --force-yes "$@"
}
apt_get_update

${cmd_wget} -O ${tmp_path}/${puppet_pkg_repo} https://apt.puppetlabs.com/${puppet_pkg_repo}
if [ ! -f ${tmp_path}/${puppet_pkg_repo} ]; then
	echo "No Puppet Labs Package Repository found at ${tmp_path}/${puppet_pkg_repo}"
	exit 1
fi

dpkg_install "${tmp_path}/${puppet_pkg_repo}"

apt_get_update

apt_get_install "puppetmaster-passenger"

/etc/init.d/apache2 stop 

apt_get_install "crudini"

cmd_crudini=$(which crudini)
if [ $? -ne 0 ]; then
	die_with_error "$LINENO" "command not found, please install crudini"
fi

${cmd_crudini} --set "${puppet_conf_file}" main certname "${canonical_hostname}" 
${cmd_crudini} --set "${puppet_conf_file}" main dns_alt_names "${aliases},${canonical_hostname}"
${cmd_crudini} --set "${puppet_conf_file}" main autosign "true"

if [ -f "./hiera.yaml" ]; then
	rm -f /etc/hiera.yaml
	cp -rf ./hiera.yaml /etc/
fi

${cmd_ln} -s /etc/hiera.yaml /etc/puppet/hiera.yaml

if [ -d "./hieradata" ]; then
	cp -rf ./hieradata /etc/puppet/
fi

/etc/init.d/apache2 start

echo "###########################################################################"

echo "Puppet Master installation completed successfully....."

echo "###########################################################################"


