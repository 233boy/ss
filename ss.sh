#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

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
_ss_sh_ver="0.23"
_ss_sh_link="https://raw.githubusercontent.com/233boy/ss/master/ss.sh"
_ss_pid=$(pgrep -f $_ss_file)
backup='/usr/bin/shadowsocks-go/backup.conf'

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get || -f /usr/bin/yum ]] && [[ -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi

else

	echo -e "\n 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}\n" && exit 1

fi

if [[ ! -f $backup ]]; then
	echo
	echo -e "$red 哇哇哇哇...出错啦...请重装...$none"
	echo
	exit 1
else
	. $backup
fi

[[ -f /usr/local/sbin/ss ]] && {
	mv /usr/local/sbin/ss /usr/local/sbin/ssgo
	echo 
	echo -e " 由于更新的原因...请使用 ${green}ssgo ${none} 命令"
	echo
	exit 0
}

if [[ $_ss_pid ]]; then
	_ss_status="$green正在运行$none"
else
	_ss_status="$red未在运行$none"
fi

ciphers=(
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)
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
_change_ss_port() {
	echo
	while :; do
		# echo -e "请输入 "$yellow"Shadowsocks"$none" 端口 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "请输入$yellow Shadowsocks $none端口 [${magenta}1-65535$none]...(当前端口: ${cyan}${ssport}$none):") " new_ssport
		[ -z "$new_ssport" ] && error && continue
		case $new_ssport in
		$ssport)
			echo
			echo -e " 跟当前端口一毛一样...修改个蛋啊"
			echo
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow Shadowsocks 端口 = $cyan$new_ssport$none"
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
_change_ss_pass() {
	echo
	while :; do
		# echo -e "请输入 "$yellow"Shadowsocks"$none" 密码"
		read -p "$(echo -e "请输入$yellow Shadowsocks $none密码...(当前密码: ${cyan}$sspass$none)"): " new_sspass
		[ -z "$new_sspass" ] && error && continue
		case $new_sspass in
		$sspass)
			echo
			echo -e " 跟当前密码一毛一样...修改个蛋啊"
			echo
			error
			;;
		*[/$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks 密码 = $cyan$new_sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done
}
_change_ss_ciphers() {
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
		read -p "$(echo -e "(当前加密协议: ${cyan}${ssciphers}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && error && continue
		case $ssciphers_opt in
		[1-3])
			new_ssciphers=${ciphers[$ssciphers_opt - 1]}
			if [[ $new_ssciphers == $ssciphers ]]; then
				echo
				echo " 跟当前加密协议一毛一样....修改个蛋啊"
				error && continue
			fi
			echo
			echo
			echo -e "$yellow Shadowsocks 加密协议 = $cyan${new_ssciphers}$none"
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
_ss_config() {
	local _menu=(
		"修改 Shadowsocks 端口"
		"修改 Shadowsocks 密码"
		"修改 Shadowsocks 协议"
	)
	while :; do
		echo
		for ((i = 1; i <= ${#_menu[*]}; i++)); do
			echo -e "$yellow $i. $none${_menu[$i - 1]}"
			echo
		done
		read -p "$(echo -e "请选择 [${magenta}1-${#_menu[*]}$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				_change_ss_port
				pause
				# del_port $ssport
				# open_port $new_ssport
				backup ssport
				ssport=$new_ssport
				_ss_service
				clear
				_ss_info
				break
				;;
			2)
				_change_ss_pass
				pause
				backup sspass
				sspass=$new_sspass
				_ss_service
				clear
				_ss_info
				break
				;;
			3)
				_change_ss_ciphers
				pause
				backup ssciphers
				ssciphers=$new_ssciphers
				_ss_service
				clear
				_ss_info
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
_update_ss() {
	new_ver=$(curl -H 'Cache-Control: no-cache' -s https://api.github.com/repos/shadowsocks/go-shadowsocks2/releases | grep -m1 'tag_name' | cut -d\" -f4)
	if [[ ! $new_ver ]]; then
		echo
		echo -e " $red获取 Shadowsocks-Go 最新版本失败!!!$none"
		echo
		echo -e " 请尝试执行如下命令: $green echo 'nameserver 8.8.8.8' >/etc/resolv.conf $none"
		echo
		echo " 然后再重新运行脚本...."
		echo
		exit 1
	elif [[ $ver != $new_ver ]]; then
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo

		_link="https://github.com/shadowsocks/go-shadowsocks2/releases/download/$new_ver/shadowsocks2-linux.gz"

		[[ -d $_ss_tmp_dir ]] && rm -rf $_ss_tmp_dir
		mkdir -p $_ss_tmp_dir

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
		echo
		echo -e "$green 更新成功啦! $none"
		echo
		backup ver
		chmod +x $_ss_file
		systemctl restart shadowsocks-go
	else
		echo
		echo -e "$green 木有发现新版本! $none"
		echo
	fi

}

_update_ss_sh() {
	new_ver=$(curl -H 'Cache-Control: no-cache' -s -L "$_ss_sh_link" | grep '_ss_sh_ver' -m1 | cut -d\" -f2)
	_ss_sh_tmp="/tmp/_ss_sh_tmp"
	if [[ ! $new_ver ]]; then
		echo
		echo -e " $red获取新版本失败!!!$none"
		echo
		echo -e " 请尝试执行如下命令: $green echo 'nameserver 8.8.8.8' >/etc/resolv.conf $none"
		echo
		echo " 然后再重新运行脚本...."
		echo
		exit 1
	elif [[ $new_ver != $_ss_sh_ver ]]; then
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo

		if ! wget --no-check-certificate -O "$_ss_sh_tmp" $_ss_sh_link; then
			echo
			echo -e "$red 下载 Shadowsocks-Go 管理脚本失败！$none"
			echo
			exit 1
		fi

		echo
		echo -e "$green 更新成功啦! $none"
		echo
		mv -f $_ss_sh_tmp $_ss_sh
		chmod +x $_ss_sh
	else
		echo
		echo -e "$green 木有发现新版本! $none"
		echo
	fi
}

_ss_service() {
	systemctl stop shadowsocks-go
	systemctl disable shadowsocks-go >/dev/null 2>&1
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
	systemctl enable shadowsocks-go >/dev/null 2>&1
	systemctl restart shadowsocks-go
}
_ss_qr() {
	[[ -z $ip ]] && get_ip
	local ss_link="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#${author}_ss_${ip}"
	local link="https://233boy.github.io/tools/qr.html#${ss_link}"
	echo
	echo "---------- Shadowsocks 二维码链接 -------------"
	echo
	echo
	_cyan "$link"
	echo
	echo
	_yellow "没看到二维码啊???用浏览器打开上面的链接啊...."
	echo
	echo
	_red " 温馨提示... Shadowsocks Win 4.0.6 客户端可能无法识别该二维码"
	echo
	echo
}
backup() {
	for keys in $*; do
		case $keys in
		ver)
			sed -i "1s/=$ver/=$new_ver/" $backup
			;;
		ssport)
			sed -i "2s/=$ssport/=$new_ssport/" $backup
			;;
		sspass)
			sed -i "3s/=$sspass/=$new_sspass/" $backup
			;;
		ssciphers)
			sed -i "4s/=$ssciphers/=$new_ssciphers/" $backup
			;;
		esac
	done
}
_ss_manage() {
	case $1 in
	start)
		if [[ $_ss_pid ]]; then
			echo
			echo -e "$green 已经在运行啦...无须再启动...$none"
			echo
		else
			systemctl start shadowsocks-go
			sleep 1.5
			if [[ ! $(pgrep -f $_ss_file) ]]; then
				echo
				echo -e "${red} Shadowsocks 启动失败！$none"
				echo
			else
				echo
				echo -e "${green} Shadowsocks 已启动$none"
				echo
			fi
		fi
		;;
	stop)
		if [[ $_ss_pid ]]; then
			systemctl stop shadowsocks-go
			echo
			echo -e "$green Shadowsocks 已停止!$none"
			echo
		else
			echo
			echo -e "${red} Shadowsocks 没有在运行呢！$none"
			echo
		fi
		;;
	restart)
		systemctl restart shadowsocks-go
		sleep 1.5
		if [[ ! $(pgrep -f $_ss_file) ]]; then
			echo
			echo -e "${red} Shadowsocks 重启失败！$none"
			echo
		else
			echo
			echo -e "${green} Shadowsocks 重启成功$none"
			echo
		fi
		;;
	esac
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

uninstall() {
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
}
_help() {
	echo
	echo "........... Shadowsocks-Go 管理脚本 by $author .........."
	echo -e "
	${yellow}ssgo menu $none管理 Shadowsocks (同等于直接输入 ssgo)

	${yellow}ssgo info $none查看 Shadowsocks 配置信息

	${yellow}ssgo config $none更改 Shadowsocks 配置

	${yellow}ssgo qr $none生成 Shadowsocks 配置二维码链接

	${yellow}ssgo status $none查看 Shadowsocks 运行状态

	${yellow}ssgo start $none启动 Shadowsocks

	${yellow}ssgo stop $none停止 Shadowsocks

	${yellow}ssgo restart $none重启 Shadowsocks

	${yellow}ssgo update $none更新 Shadowsocks

	${yellow}ssgo update.sh $none更新 Shadowsocks 管理脚本

	${yellow}ssgo uninstall $none卸载 Shadowsocks
"
}
menu() {
	local _menu=(
		"查看 Shadowsocks 配置"
		"更改 Shadowsocks 配置"
		"启动 Shadowsocks"
		"停止 Shadowsocks"
		"重启 Shadowsocks"
		"更新 Shadowsocks"
		"更新 Shadowsocks 管理脚本"
		"卸载 Shadowsocks"
	)
	clear
	while :; do
		echo
		echo "........... Shadowsocks-Go 管理脚本 $_ss_sh_ver by $author .........."
		echo
		echo "帮助说明: https://233blog.com/post/36/"
		echo
		echo "TG 群组: https://t.me/blog233"
		echo
		echo -e "运行状态: $_ss_status"
		echo
		for ((i = 1; i <= ${#_menu[*]}; i++)); do
			echo -e "$yellow $i. $none${_menu[$i - 1]}"
			echo
		done
		echo
		echo -e "温馨提示...如果你不想执行选项...按$yellow Ctrl + C $none即可退出"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-${#_menu[*]}$none]:")" choose
		if [[ -z $choose ]]; then
			exit 1
		else
			case $choose in
			1)
				_ss_info
				break
				;;
			2)
				_ss_config
				break
				;;
			3)
				_ss_manage start
				break
				;;
			4)
				_ss_manage stop
				break
				;;
			5)
				_ss_manage restart
				break
				;;
			6)
				_update_ss
				break
				;;
			7)
				_update_ss_sh
				break
				;;
			8)
				uninstall
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
args=$1
[ -z $1 ] && args="menu"
case $args in
menu)
	menu
	;;
c | config)
	_ss_config
	;;
i | info)
	_ss_info
	;;
qr)
	_ss_qr
	;;
u | update)
	_update_ss
	;;
U | update.sh)
	_update_ss_sh
	;;
status)
	echo
	echo -e " Shadowsocks 运行状态: $_ss_status"
	echo
	;;
start)
	_ss_manage start
	;;
stop)
	_ss_manage stop
	;;
restart)
	_ss_manage restart
	;;
un | uninstall)
	uninstall
	;;
* | help)
	_help
	;;
esac
