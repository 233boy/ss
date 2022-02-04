#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

# Root
[[ $(id -u) != 0 ]] && echo -e "\n 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none} \n" && exit 1

cmd="apt-get"
author=233boy
_ss_tmp_dir="/tmp/ss-tmp"
_ss_tmp_file="/tmp/ss-tmp/shadowsocks-go"
_ss_tmp_gz="/tmp/ss-tmp/shadowsocks-go.gz"
_ss_dir='/usr/bin/shadowsocks-go'
_ss_file='/usr/bin/shadowsocks-go/shadowsocks-go'
_ss_sh="/usr/local/sbin/ssgo"
_ss_sh_link="https://raw.githubusercontent.com/233boy/ss/master/ss.sh"
backup='/usr/bin/shadowsocks-go/backup.conf'

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get || -f /usr/bin/yum ]] && [[ -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi

else

	echo -e "\n 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}\n" && exit 1

fi

ciphers=(
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)

shadowsocks_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	echo
	while :; do
		# echo -e "请输入 "$yellow"Shadowsocks"$none" 端口 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "请输入$yellow Shadowsocks $none端口 [${magenta}1-65535$none]...(默认端口: ${cyan}${random}$none):") " ssport
		[ -z "$ssport" ] && ssport=$random
		case $ssport in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow Shadowsocks 端口 = $cyan$ssport$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
}
shadowsocks_password_config() {
	echo
	while :; do
		# echo -e "请输入 "$yellow"Shadowsocks"$none" 密码"
		read -p "$(echo -e "请输入$yellow Shadowsocks $none密码...(默认密码: ${cyan}233blog.com$none)"): " sspass
		[ -z "$sspass" ] && sspass="233blog.com"
		case $sspass in
		*[/$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks 密码 = $cyan$sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done
}
shadowsocks_ciphers_config() {
	echo
	while :; do
		echo -e "请选择 "$yellow"Shadowsocks"$none" 加密协议 [${magenta}1-${#ciphers[*]}$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			echo
			if [[ "$i" -le 9 ]]; then
				echo -e "$yellow  $i. $none${ciphers[$i - 1]}"
			else
				echo -e "$yellow $i. $none${ciphers[$i - 1]}"
			fi
		done
		echo
		read -p "$(echo -e "(默认加密协议: ${cyan}${ciphers[2]}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && ssciphers_opt=3
		case $ssciphers_opt in
		[1-3])
			ssciphers=${ciphers[$ssciphers_opt - 1]}
			echo
			echo
			echo -e "$yellow Shadowsocks 加密协议 = $cyan${ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
}
_install_info() {
	echo
	echo "---------- Shadowsocks 安装信息 -------------"
	echo
	echo -e "$yellow 端口 = $cyan$ssport$none"
	echo
	echo -e "$yellow 密码 = $cyan$sspass$none"
	echo
	echo -e "$yellow 加密协议 = $cyan${ssciphers}$none"
	echo
}
_update() {
	$cmd update -y
	$cmd install -y wget gzip
}
_download_ss() {
	ver=$(curl -H 'Cache-Control: no-cache' -s https://api.github.com/repos/shadowsocks/go-shadowsocks2/releases | grep -m1 'tag_name' | cut -d\" -f4)
	if [[ ! $ver ]]; then
		echo
		echo -e " $red获取 Shadowsocks-Go 最新版本失败!!!$none"
		echo
		echo -e " 请尝试执行如下命令: $green echo 'nameserver 8.8.8.8' >/etc/resolv.conf $none"
		echo
		echo " 然后再重新运行脚本...."
		echo
		exit 1
	fi

	_link="https://github.com/shadowsocks/go-shadowsocks2/releases/download/$ver/shadowsocks2-linux.gz"

	[[ -d $_ss_tmp_dir ]] && rm -rf $_ss_tmp_dir
	mkdir -p $_ss_tmp_dir
	mkdir -p $_ss_dir

	if ! wget --no-check-certificate -O "$_ss_tmp_gz" $_link; then
		echo
		echo -e "$red 下载 Shadowsocks-Go 失败！$none"
		echo
		exit 1
	fi

	gzip -df $_ss_tmp_gz
	cp -f $_ss_tmp_file $_ss_file

	if [[ ! -f $_ss_file ]]; then
		echo
		echo -e "$red 安装 Shadowsocks-Go 出错！$none"
		echo
		exit 1
	fi

	if ! wget --no-check-certificate -O "$_ss_sh" $_ss_sh_link; then
		echo
		echo -e "$red 下载 Shadowsocks-Go 管理脚本失败！$none"
		echo
		exit 1
	fi
	chmod +x $_ss_file
	chmod +x $_ss_sh
}
_install_service() {
	cat >/lib/systemd/system/shadowsocks-go.service <<-EOF
[Unit]
Description=Shadowsocks-Go Service
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/var/run/shadowsocks-go.pid
ExecStart=/usr/bin/shadowsocks-go/shadowsocks-go -s "ss://${ssciphers}:${sspass}@:${ssport}"
RestartSec=3
Restart=always
LimitNOFILE=1048576
LimitNPROC=512

[Install]
WantedBy=multi-user.target
EOF
	systemctl enable shadowsocks-go
	systemctl restart shadowsocks-go
}
backup() {
	cat >$backup <<-EOF
ver=${ver}
ssport=${ssport}
sspass=${sspass}
ssciphers=${ssciphers}
EOF
}
open_port() {
	if [[ $(command -v iptables) ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
	fi
}
del_port() {
	if [[ $(command -v iptables) ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
	fi
}

_ss_info() {
	[[ -z $ip ]] && get_ip
	local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#${author}_ss_${ip}"
	echo
	echo "---------- Shadowsocks 配置信息 -------------"
	echo
	echo -e "$yellow 服务器地址 = $cyan${ip}$none"
	echo
	echo -e "$yellow 服务器端口 = $cyan$ssport$none"
	echo
	echo -e "$yellow 密码 = $cyan$sspass$none"
	echo
	echo -e "$yellow 加密协议 = $cyan${ssciphers}$none"
	echo
	echo -e "$yellow SS 链接 = ${cyan}$ss$none"
	echo
	echo -e " 备注:$red Shadowsocks Win 4.0.6 $none客户端可能无法识别该 SS 链接"
	echo
	echo -e "提示: 输入$cyan ssgo qr $none可生成 Shadowsocks 二维码链接"
	echo
	echo -e "${yellow}[AD] 推荐使用JMS..不会被墙的机场: ${cyan}https://getjms.com${none}"
	echo

}

try_enable_bbr() {
	local _test1=$(uname -r | cut -d\. -f1)
	local _test2=$(uname -r | cut -d\. -f2)
	if [[ $_test1 -eq 4 && $_test2 -ge 9 ]] || [[ $_test1 -ge 5 ]]; then
		sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
		sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
		echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
		echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
		sysctl -p >/dev/null 2>&1
		echo
		echo -e  "$green..由于你的 VPS 内核支持开启 BBR ...已经为你启用 BBR 优化....$none"
		echo
	fi
}

get_ip() {
	ip=$(curl -s https://ipinfo.io/ip)
}

error() {
	echo -e "\n$red 输入错误！$none\n"
}

pause() {
	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'
	echo
}

install() {
	if [[ -f $backup ]]; then
		echo
		echo -e " 呀呀呀...你已经安装啦...输入$cyan ss $none即可管理"
		echo
		exit 1
	fi
	shadowsocks_port_config
	shadowsocks_password_config
	shadowsocks_ciphers_config
	pause
	# clear
	# _install_info
	# pause
	# try_enable_bbr
	_update
	_download_ss
	_install_service
	backup
	# open_port $ssport
	clear
	_ss_info
}
uninstall() {
	if [[ -f $backup ]]; then
		while :; do
			echo
			read -p "$(echo -e "是否卸载 ${yellow}Shadowsocks$none [${magenta}Y/N$none]:")" _ask
			if [[ -z $_ask ]]; then
				error
			else
				case $_ask in
				Y | y)
					is_uninstall=true
					echo
					echo -e "$yellow 卸载 Shadowsocks = ${cyan}是${none}"
					echo
					break
					;;
				N | n)
					echo
					echo -e "$red 卸载已取消...$none"
					echo
					break
					;;
				*)
					error
					;;
				esac
			fi
		done
		if [[ $is_uninstall ]]; then
			pause
			. $backup
			# del_port $ssport
			systemctl stop shadowsocks-go
			systemctl disable shadowsocks-go >/dev/null 2>&1
			rm -rf $_ss_dir
			rm -rf $_ss_sh
			rm -rf /lib/systemd/system/shadowsocks-go.service
			echo
			echo -e "$green 卸载成功啦...$none"
			echo
			echo "如果你觉得这个脚本有哪些地方不够好的话...请告诉我"
			echo
			echo "反馈问题: https://github.com/233boy/ss/issues"
			echo
		fi

	else
		echo
		echo -e "$red 然而...你并没有使用过本人的安装脚本...卸载个蛋$none"
		echo
	fi
}

clear
while :; do
	echo
	echo "........... Shadowsocks-Go 一键安装脚本 & 管理脚本 by $author .........."
	echo
	echo "帮助说明: https://233blog.com/post/36/"
	echo
	echo "搭建教程: https://233blog.com/post/3/"
	echo
	echo " 1. 安装"
	echo
	echo " 2. 卸载"
	echo
	read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" choose
	case $choose in
	1)
		install
		break
		;;
	2)
		uninstall
		break
		;;
	*)
		error
		;;
	esac
done
