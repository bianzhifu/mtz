**liunx agent安装**     
一键安装   
`bash <(curl -s https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/install.sh) install_agent 服务器网址 秘钥`    
一键卸载   
`bash <(curl -s https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/install.sh) uninstall_agent`   
一键重启   
`bash <(curl -s https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/install.sh) restart_agent`   

**window agent安装**   
使用[nssm](https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip)   
`mtz-agent.exe -s 服务器网址 -p 秘钥`   

**说明**    
***服务器网址***：推荐使用https链接的网址，例如 http://www.example.com 或者 http://www.example.com   
***秘钥***：推荐使用uuid生成 例如 da1e8512-3fc1-4ba7-ab70-33a76ed9c685    

**DashBorad安装**   
一键安装   
`bash <(curl -s https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/dashboard.sh) install 80`   
一键卸载   
`bash <(curl -s https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/dashboard.sh) uninstall`   
一键重启    
`bash <(curl -s https://raw.githubusercontent.com/bianzhifu/mtz/master/scripts/dashboard.sh) restart`    

**其他**   
1、增加agent在/opt/mtzDashBoard目录下server.json    
2、如果使用Nginx反代DashBoard请添加一下配置   
```
location / {
    proxy_pass http://127.0.0.1:8008;
}
location /agent {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:8008;
}
location /client {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:8008;
}
```
