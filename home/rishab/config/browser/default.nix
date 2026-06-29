{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zen-browser = {
    enable = false;
    setAsDefaultBrowser = true;
  };

  home.packages = [
    pkgs.captive-browser
  ];
  xdg.configFile."captive-browser.toml".text = ''
    browser = ${
      lib.concatStringsSep " " [
        ''"""''
        ''open -n -W -a "Helium" --args''
        "--user-data-dir=${config.xdg.dataHome}/chromium-captive"
        ''--proxy-server="socks5://$PROXY"''
        ''--proxy-bypass-list="<-loopback>"''
        "--no-first-run"
        "--new-window"
        "--incognito"
        "--no-default-browser-check"
        "--no-crash-upload"
        "--disable-extensions"
        "--disable-sync"
        "--disable-background-networking"
        "--disable-client-side-phishing-detection"
        "--disable-component-update"
        "--disable-translate"
        "--disable-web-resources"
        "--safebrowsing-disable-auto-update"
        "http://detectportal.firefox.com/canonical.html"
        ''"""''
      ]
    } 
    dhcp-dns = "ipconfig getoption en0 domain_name_server"
    socks5-addr = "localhost:11666"
  '';
}
