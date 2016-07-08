A few notes on the status wrt recent fedoras. 

Written in July 2016, right after my early attempts with fedora24.

# `/etc/resolv.conf`

A change was observed starting with fedora22, and from then on we have seen recurring issues with nodes ending up with an empty `/etc/resolv.conf`

## f22
My understanding is that at the beginning this issue was only with statically defined IPs; in that case having `DNS1` and `DNS2` defined in a `ifcfg-`*ifname* was not enough, so there was a need to populate `/etc/resolv.conf` manually

## f23
It looks like with this release, the DNS servers defined by DHCP don't make it to `/etc/resolv.conf` either

## Strategy

### 5.4

As of 5.4, the strategy here is to

 * check if the file is missing or empty
 * and if so, we populate it with
   * nameservers coming from `DNS1` and `DNS2` if set, 
   * and **in all cases** with `8.8.8.8`

### 5.3

Note that a 5.3 bootCD would **never** add `8.8.8.8`

This could result in a node **not being able to resolve its boot server IP address**. Observed first hand on `onelab1.pl.sophia.fr` and its sibling `onelab2` with a f23 bootCD.

# MAC address

Also with fedora23, we noticed that we sometimes have to specify the MAC address in the interface details, so that the right interface gets picked.

From a lot of reading I believe this has nothing to do with `biosdevname=0` which is something. It's just that on a multi-interfaces host, the bootCD environment may pick the wrong interface, so setting the MAC address allows to work around that issue.

I cannot see how to improve this for the time being.