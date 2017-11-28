#!/bin/bash
#Batch scripts for Rails production environment install on Ubuntu Server and OS optimize
# It automatically completes the dependency installation of the rails environment
# Author: Jerry Zhu <jerry@whmall.com>
# License:GPLv3
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/bin:/sbin
export PATH

#Getting the codename of the system
CODENAME=$(lsb_release -c|awk '{print $NF}')

#Define Which Ruby version manager
read -p "Which Ruby version manager do you want to use?:(rbenv or rvm,Default:rvm) " RUBY_VM
    if [ "$RUBY_VM" = "" ]; then
        RUBY_VM="rvm"
    fi

#Define user for running application
read -p "Enter the user for running Ruby on Rails:(Default:webuser) " RUBY_USER
	if [ "$RUBY_USER" = "" ]; then
        RUBY_USER="webuser"
    fi

#Define user password for running applications
read -p "Enter the user password for running Ruby on Rails: " PASSWORD

#Define the Ruby version of the running application
read -p "Which RUBY version is what you want?: (Default:2.4.2)" RUBY_VERSION
    if [ "$RUBY_VERSION" = "" ]; then
        RUBY_VERSION="2.4.2"
    fi

useradd -m -N  -s /bin/bash $RUBY_USER
	
#Modify the password for running Ruby on Rails users
passwd $RUBY_USER<<EOF
$PASSWORD
$PASSWORD
EOF

echo "============================================="	
echo The user who runs Ruby on Rails is："$RUBY_USER" 

echo The Ruby version you specify is："$RUBY_VERSION" 
echo "============================================="

sleep 3

#Optimize the system kernel parameters
cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

cat >>/etc/sysctl.conf<<eof
fs.file-max=262140
vm.swappiness = 0
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_announce=2
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_synack_retries = 2
net.ipv4.conf.lo.arp_announce=2
vm.overcommit_memory = 1
net.core.somaxconn = 2000
net.ipv4.tcp_tw_reuse = 1
kernel.threads-max = 254737
eof
sysctl -p

#install Ubuntu packages
echo "install Ubuntu packages..."
mv -f /etc/apt/sources.list /etc/apt/sources.list.bak
if [ $CODENAME = 'xenial' ];then
cat>/etc/apt/sources.list<<EOF
deb http://mirrors.163.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ xenial-backports main restricted universe multiverse
EOF

elif [ $CODENAME = 'trusty' ];then
cat>/etc/apt/sources.list<<EOF
deb http://mirrors.163.com/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse
EOF
fi

apt update && apt -y upgrade
sleep 3
apt-get install -y software-properties-common wget unzip vim build-essential openssl libreadline6 libreadline6-dev libsqlite3-dev libmysqlclient-dev libpq-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev autoconf automake cmake libtool imagemagick libmagickwand-dev libpcre3-dev language-pack-zh-hans libevent-dev libgmp-dev libgmp3-dev redis-tools htop git clang make nodejs libcurl4-openssl-dev sqlite3 libgdbm-dev libncurses5-dev bison gnutls-bin libgdbm-dev pkg-config libffi-dev gnupg2 

echo "---------------------------------------------------------------------------"
echo ""
echo ""

#Ubuntu14 system features, New users need password free installation
if [ 'grep "trusty" /etc/lsb-release' ];then
	echo "$RUBY_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

fi


#Install Ruby Version Manager 

install_rvm() {
echo "Install Ruby Version Manager" 
echo "---------------------------------------------------------------------------" 

su -c "curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -" $RUBY_USER
cd /home/$RUBY_USER
su -c "curl -L https://get.rvm.io | bash -s stable" $RUBY_USER


if [ whoami = 'root' ];then
    source /etc/profile.d/rvm.sh
else
    su -c "source /home/$RUBY_USER/.rvm/scripts/rvm" $RUBY_USER
fi

#Replacement of RVM mirror from china
su -c 'echo "ruby_url=http://mirrors.ustc.edu.cn/ruby" > ~/.rvm/user/db' $RUBY_USER


su - $RUBY_USER -c "rvm requirements"

#Install ruby
su - $RUBY_USER -c "rvm install $RUBY_VERSION --disable-binary"
su - $RUBY_USER -c "rvm use $RUBY_VERSION --default"

#Replacement of gem mirror from china
su - $RUBY_USER -c "gem sources --add https://gems.ruby-china.org/ --remove https://        rubygems.org/"

su - $RUBY_USER -c "gem install bundler"
su - $RUBY_USER -c "gem install rails"
echo ""
echo  "The following components are installed:"
su - $RUBY_USER -c "rvm -v"
su - $RUBY_USER -c "ruby -v"
su - $RUBY_USER -c "gem -v"
su - $RUBY_USER -c "bundle -v"
su - $RUBY_USER -c "rails -v"
}

install_rbenv() {
    su - $RUBY_USER -c "git clone https://github.com/sstephenson/rbenv.git ~/.rbenv"
    su - $RUBY_USER -c "git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/     plugins/ruby-build"
    su - $RUBY_USER -c "git clone git://github.com/jamis/rbenv-gemset.git  ~/.rbenv/plugins/rbenv-gemset"
    su - $RUBY_USER -c "git clone git://github.com/sstephenson/rbenv-gem-rehash.git ~/.     rbenv/plugins/rbenv-gem-rehash"
    su - $RUBY_USER -c "git clone git://github.com/rkh/rbenv-update.git ~/.rbenv/plugins/   rbenv-update"
    su - $RUBY_USER -c "git clone git://github.com/AndorChen/rbenv-china-mirror.git ~/.     rbenv/plugins/rbenv-china-mirror"
    su - $RUBY_USER -c "echo 'export PATH="/home/$RUBY_USER/.rbenv/bin:$PATH"' >> ~/.bashrc"
    echo 'eval "$(rbenv init -)"' >> /home/$RUBY_USER/.bashrc

    echo ""
    echo  "Please do the following steps:"
    echo ""
    echo "1.su - $RUBY_USER"
    echo "2.rbenv installl $RUBY_VERSION"
    echo "3.rbenv global $RUBY_VERSION && rbenv rehash"
    echo "4.gem install bundle"
    echo "5.gem install rails"
}

if [ $RUBY_VM = 'rbenv' ];then
    install_rbenv
else
    install_rvm
fi

#To ensure the security of the system, remove sudo password free
sed -i "s@$RUBY_USER ALL=(ALL) NOPASSWD:ALL@@g" /etc/sudoers

echo "--------------------------- Install Successed -----------------------------" 
echo ""
echo "Rbenv and RVM are two in one update, but not perfect, and maybe ansible is a better choice." 
