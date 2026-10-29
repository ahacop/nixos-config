# Networking: DHCP through systemd-networkd on the bridged interface, DNS
# through systemd-resolved, and mDNS through Avahi for .local names.
{
  flake.modules.nixos.networking = {
    networking = {
      # networkd runs DHCP only on enp2s0, set below.
      useDHCP = false;

      # DHCP is done by systemd-networkd, not by dhcpcd, so that resolved below
      # gets every DNS server a network hands out. networkd keeps one list per
      # link holding the servers from all protocols, and resolved reads it
      # directly.
      #
      # dhcpcd instead reports to resolved one protocol at a time (enp2s0.dhcp,
      # enp2s0.ra), and resolved reads each report as the link's whole list, so
      # only the protocol that renewed last survives. A router handing out both
      # an IPv4 and an IPv6 resolver keeps just one of them. Drop the IPv4 one
      # and containers can resolve nothing, since they have no IPv6 address, and
      # `docker build` fails. The machine keeps working, because it has IPv6 and
      # FallbackDNS.
      #
      # Setting this turns dhcpcd off on its own.
      useNetworkd = true;

      # Interface is this on M1
      interfaces.enp2s0.useDHCP = true;

      # The firewall is off so anything listening in the VM is reachable without
      # opening ports one at a time. The VM is bridged onto the local network, so
      # that means every host on that network, not just the Mac running it.
      firewall.enable = false;
    };

    # Don't block boot or a rebuild waiting for a DHCP lease.
    systemd.network.wait-online.enable = false;

    # DNS. This VM roams between networks, so resolution goes through
    # systemd-resolved rather than a plain resolv.conf written from DHCP.
    #
    # - networkd hands every DHCP-provided resolver to resolved as this link's
    #   DNS. The VM is bridged, so those are the resolvers the local router hands
    #   out, and names that only the local network knows still resolve.
    # - Those resolvers vary in quality. A forwarder that answers an EDNS0 query
    #   with a broken packet takes glibc down with it, because glibc reads the
    #   broken answer as "no such name" and never tries another server. resolved
    #   probes each server and turns EDNS0 off per-server by itself, so one bad
    #   resolver does not cost us the others, and we do not have to disable EDNS0
    #   for the whole system.
    # - FallbackDNS is only used when a network hands out no DNS at all, so a
    #   network with no resolver still resolves names instead of going dark.
    # - resolv.conf points at the local stub at 127.0.0.53, which is always up, so
    #   the machine can always rebuild even when a network's DNS is misbehaving.
    #
    # We do not set networking.nameservers on purpose. Under resolved that becomes
    # a global DNS server and would compete with the link's own resolvers.
    services.resolved = {
      enable = true;
      settings.Resolve = {
        FallbackDNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        # Router and hotspot forwarders often can't do DNSSEC. Leave validation
        # off so it does not break resolution behind them.
        DNSSEC = false;
      };
    };

    # mDNS/Bonjour so we can resolve the Mac host (and other peers) via *.local
    # without depending on the router's DNS or a fixed IP.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
  };
}
