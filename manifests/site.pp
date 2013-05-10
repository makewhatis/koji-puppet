
# For simplicity, this one server will just do everything.
node 'koji.makewhatis.com' {
  # System Kerberos configuration.

  class {'firewall': } 

  firewall { "00000 accept icmp":
    proto => "icmp",
    action => "accept"
  }

  firewall { "00001 accept established, related":
    state  => ['ESTABLISHED', 'RELATED'],
    proto  => 'all',
    action => 'accept',
  }

  firewall { "00002 accept localhost":
    source => '127.0.0.1',
    proto  => 'all',
    action => 'accept',
  }

  firewall { "00080 http on port 80":
    proto => "tcp",
    dport => "80",
    action => "accept"
  }

  firewall { "00080 http on port 80":
    proto => "tcp",
    dport => "80",
    action => "accept"
  }  

  firewall { "65536 drop incoming packets":
    action => 'drop'
  }

  # Dependencies for koji::hub
  class {'apache': }

  class {'krb5':
    realm => 'MAKEWHATIS.COM',
    # Kerberos KDC.
    admin_server => 'salt.makewhatis.com',
  }


}
