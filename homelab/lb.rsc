:foreach i in=[/ip/dns/static/find name~"kube-"] do={
  :local name [/ip/dns/static/get $i name];
  :local host [/ip/dns/static/get $i address];
  :local enabled [:len [/ip/dns/static/find name="kube" address=$host disabled=no]];

  :local enable do={
    :log info "$name - Enabling";
    /ip/dns/static/enable [find name=kube address=$host]
    /ip/firewall/nat/enable [/ip/firewall/nat/find to-addresses=$host comment="KubeAPI"]
    /tool/e-mail/send to=tim@tim.rip subject="$name ($host) is ready" body="Enabled NAT and DNS"
  }

  :local disable do={
    :log info "$name - Disabling";
    /ip/dns/static/disable [find name=kube address=$host]
    /ip/firewall/nat/disable [/ip/firewall/nat/find to-addresses=$host comment="KubeAPI"]
    /tool/e-mail/send to=tim@tim.rip subject="$name ($host) is $reason" body="Disabled NAT and DNS"
  }

  :retry command={
    :local ready [/tool/fetch url="https://$host:6443/readyz" as-value output=user]
    :if ($ready->"status" = "finished") do={
      :if ($ready->"data" != "ok") do={
        :if ($enabled = "1") do={ $disable name=$name host=$host reason="not ready" }
      } else={
        :if ($enabled = "0") do={ $enable name=$name host=$host }
      }
    }
  } delay=1 max=2 on-error={ :if ($enabled = "1") do={ $disable name=$name host=$host reason="readyz request failed" } }
}
