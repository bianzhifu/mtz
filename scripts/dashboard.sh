#!/bin/bash
os_arch=""

pre_check() {
  command -v systemctl >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    echo "不支持此系统：未找到 systemctl 命令"
    exit 1
  fi
  # check root
  [[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

  ## os_arch
  if [[ $(uname -m | grep 'x86_64') != "" ]]; then
    os_arch="amd64"
  elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
    os_arch="arm64"
  else
    echo "只支持amd64/arm64"
    exit 1
  fi
}

install() {
  echo -e "> 安装DashBoard"

  mkdir -p /opt/mtzDashBoard/
  chmod 775 /opt/mtzDashBoard/

  echo -e "下载DashBoard"
  wget -O DashBoard_linux_${os_arch} https://github.com/bianzhifu/mtz/releases/download/v0.0.1/DashBoard_linux_${os_arch} >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    echo -e "${red}下载失败,https://github.com/bianzhifu/mtz/releases/download/v0.0.1/DashBoard_linux_${os_arch}"
    return 0
  fi
  mv DashBoard_linux_${os_arch} /opt/mtzDashBoard/DashBoard
  chmod +x /opt/mtzDashBoard/DashBoard

  #下载默认配置
  wget -O /opt/mtzDashBoard/settings.json https://raw.githubusercontent.com/bianzhifu/mtz/master/cmd/dashboard/settings.json
  wget -O /opt/mtzDashBoard/servers.json https://raw.githubusercontent.com/bianzhifu/mtz/master/cmd/dashboard/servers.json

  echo -e "> 修改配置"

  service_script=/etc/systemd/system/mtzDashBoard.service

  cat >$service_script <<EOFSCRIPT
[Unit]
Description=mtzDashBoard
After=syslog.target
#After=network.target

[Service]
LimitMEMLOCK=infinity
LimitNOFILE=65535
Type=simple
User=root
Group=root
WorkingDirectory=/opt/mtzDashBoard/
ExecStart=/opt/mtzDashBoard/DashBoard -port $1
Restart=always

[Install]
WantedBy=multi-user.target
EOFSCRIPT
  chmod +x $service_script

  echo -e "${green}修改成功，请稍等重启生效${plain}"
  systemctl daemon-reload
  systemctl enable mtzDashBoard.service
  systemctl restart mtzDashBoard.service

  echo -e "显示日志 ${plain}"
  journalctl -n10 -u mtzDashBoard.service
}

uninstall() {
  echo -e "> 卸载"
  while true
  do
      read -r -p '你是否备份好/opt/mtzDashBoard/目录下的servers.json和settings.json,确认继续请输入Y?' choice
      case "$choice" in
        n|N) break;;
        y|Y)
          systemctl disable mtzDashBoard.service
          systemctl stop mtzDashBoard.service
          rm -rf /etc/systemd/system/mtzDashBoard.service
          systemctl daemon-reload
          rm -rf /opt/mtzDashBoard/
          break
        ;;
        *) echo '输入错误';;
      esac
  done
}

restart() {
  echo -e "> 重启"
  systemctl daemon-reload
  systemctl restart mtzDashBoard.service
}

show_usage() {
  echo "使用方法: "
  echo "---------------------------------------"
  echo "./install.sh install 80        - 安装"
  echo "./install.sh uninstall         - 卸载"
  echo "./install.sh restart           - 重启"
  echo "---------------------------------------"
}
pre_check
case $1 in
"install")
  install $2
  ;;
"uninstall")
  uninstall
  ;;
"restart")
  restart
  ;;
*) show_usage ;;
esac
