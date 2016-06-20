#!/bin/sh
#########################################################################
#    Update PS1 like [root@192.168.1.113 /data]#    #
#########################################################################
#先判断网卡是否存在，我这边eth1是内网网卡
ifconfig eth1 >/dev/null 2>&1
if [[ $? != 0 ]]
then
 echo 'interface eth1 not exsit!';
 exit 1
fi
#Centos/Redhat 7 ifconfig显示的结果不是 inet addr: 而是 inet 直接加IP，所以这里需要判断下：
function Get_eth1IP()
{
 if [[ $1 -eq 7 ]]
 then
  #for centos 7
  eth1_IP=$(ifconfig eth1 |awk '/inet / {print $2}'|awk '{print $1}')
 else
  eth1_IP=$(ifconfig eth1 |awk -F":" '/inet addr:/ {print $2}'|awk '{print $1}')
 fi
}

#test -f /etc/redhat-release && grep 7 /etc/redhat-release >/dev/null 2>&1 && Get_eth1IP 7
test -f /etc/centos-release && grep 7 /etc/centos-release >/dev/null 2>&1 && Get_eth1IP 7 || Get_eth1IP

echo $eth1_IP | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" >/dev/null 2>&1

if [[ $? != 0 ]]
then
 echo 'eth1_IP is empty!'
 exit 1
fi

function Export()
{
 echo "export PS1='\[\e[32m\][\u@${eth1_IP}:\[\e[m\]\[\e[33m\]\w\[\e[m\]\[\e[32m\]]\[\e[m\]\\$ '">>${1} && \
 echo -e "\033[32m Update \033[0m \033[33m${1}\033[33m \033[32mSuccess! Please relogin your system for refresh... \033[0m"
}

function home_env()
{
 if [[ ! -z $1 ]]
 then
  home=$1
 else
  home=/root
 fi
 #有的用户可能会在家目录下自定义一些配置，即 .proflie这个隐藏文件，所以也需要更新
 test -f $home/.bash_profile && (
  sed -i '/export PS1=/d' $home/.bash_profile
  Export $home/.bash_profile
  )
}

#获取当前用户id，如果是root组的则可以操作/etc/profile
userid=$(id | awk '{print $1}' | sed -e 's/=/ /' -e 's/(/ /' -e 's/)/ /'|awk '{print $2}')
if [[ $userid = 0 ]]
then
 #for all
 sed -i '/export PS1=/d' /etc/profile
 Export /etc/profile

 #for root
 home_env

 #如果其他用户需要修改，只要开启一下三行，并将other修改成用户名
 #id other >/dev/null 2>&1 && (
 # home_env ~other
 #)
else
 #for userself
 home_env ~
fi
