/system/script add name=KubeAPILB source={
  :local node [/ip/dns/static/get [/ip/dns/static/find name~"kube-" address=$host] name];

  :if ($status="up") do={
    /ip/dns/static/enable [find name=kube address=$host]
    /ip/firewall/nat/enable [/ip/firewall/nat/find to-addresses=$host comment="KubeAPI"]
  } else={
    /ip/dns/static/disable [find name=kube address=$host]
    /ip/firewall/nat/disable [/ip/firewall/nat/find to-addresses=$host comment="KubeAPI"]
  }
} dont-require-permissions=yes policy=read,write,test

:foreach i in=[/ip/dns/static/find name~"kube-"] do={
  :local addr [/ip/dns/static/get $i address];

  :if ([/ip/dns/static/find address=$addr name=kube]="") do={
    /ip/dns/static/add address=$addr name=kube ttl=00:00:01
  }

  :if ([/ip/firewall/nat/find to-addresses=$addr comment="KubeAPI"]="") do={
    /ip/firewall/nat/add chain=dstnat action=dst-nat to-addresses=$addr dst-address=10.69.4.254 \
      comment="KubeAPI"
  }

  :if ([/tool/netwatch find host=$addr comment="KubeAPI"]="") do={
    /tool/netwatch/add host=$addr type=http-get timeout=20 comment="KubeAPI" \
      interval=5 down-script=KubeAPILB up-script=KubeAPILB port=6443 http-codes=400
  }
}
