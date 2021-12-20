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
    elif [[ $(uname -m | grep 'i386\|i686') != "" ]]; then
        os_arch="386"
    elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
        os_arch="arm64"
    elif [[ $(uname -m | grep 'arm') != "" ]]; then
        os_arch="arm"
    fi
}

install_agent(){
  echo -e "> 安装监控Agent"
  echo -e "正在获取监控Agent版本号"
  local version=$(curl -m 10 -sL "https://api.github.com/repos/bianzhifu/mtz/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
  if [ ! -n "$version" ]; then
      echo -e "获取版本号失败，请检查本机能否链接 https://api.github.com/repos/bianzhifu/mtz/releases/latest"
      return 0
  else
      echo -e "当前最新版本为: ${version}"
  fi
  mkdir -p /opt/mtz/agent
  chmod 777 /opt/mtz/agent

  echo -e "正在下载监控端"
  wget -O mtz-agent_linux_${os_arch}.tar.gz https://github.com/bianzhifu/mtz/releases/download/${version}/mtz-agent_linux_${os_arch}.tar.gz >/dev/null 2>&1
  if [[ $? != 0 ]]; then
      echo -e "${red}Release 下载失败，请检查本机能否连接 https://github.com/bianzhifu/mtz/releases/download/${version}/mtz-agent_linux_${os_arch}.tar.gz"
      return 0
  fi
  tar xf mtz-agent_linux_${os_arch}.tar.gz &&
      mv mtz-agent /opt/mtz/agent &&
      rm -rf mtz-agent_linux_${os_arch}.tar.gz README.md

  echo -e "> 修改Agent配置"

  wget -O /etc/systemd/system/mtz-agent.service https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/mtz-agent.service >/dev/null 2>&1
  if [[ $? != 0 ]]; then
      echo -e "${red}文件下载失败，请检查本机能否连接 https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/mtz-agent.service"
      return 0
  fi

  mtzServerAddress=$1
  mtzServerSecret=$2
  sed -i "s@mtzServerAddress@${mtzServerAddress}@" /etc/systemd/system/mtz-agent.service
  sed -i "s@mtzServerSecret@${mtzServerSecret}@" /etc/systemd/system/mtz-agent.service

  echo -e "Agent配置 ${green}修改成功，请稍等重启生效${plain}"
  systemctl daemon-reload
  systemctl enable mtz-agent
  systemctl restart mtz-agent

  echo -e "Agent显示日志 ${plain}"
  journalctl -n10 -u mtz-agent.service
}

uninstall_agent() {
    echo -e "> 卸载Agent"
    systemctl disable mtz-agent.service
    systemctl stop mtz-agent.service
    rm -rf /etc/systemd/system/mtz-agent.service
    systemctl daemon-reload
    rm -rf /opt/mtz/
}

restart_agent() {
    echo -e "> 重启Agent"
    systemctl restart mtz-agent.service
}

show_usage() {
    echo "使用方法: "
    echo "--------------------------------------------------------"
    echo "./mtz.sh install_agent host secret          - 安装监控Agent"
    echo "./mtz.sh uninstall_agent                    - 卸载Agent"
    echo "./mtz.sh restart_agent                      - 重启Agent"
    echo "--------------------------------------------------------"
}
pre_check
case $1 in
"install_agent")
    install_agent $2 $3
    ;;
"uninstall_agent")
    uninstall_agent 0
    ;;
"restart_agent")
    restart_agent 0
    ;;
*) show_usage ;;
esac

