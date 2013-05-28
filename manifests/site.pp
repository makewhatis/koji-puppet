
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

  firewall { "00022 ssh on port 22":
		proto => "tcp",
		dport => "22",
		action => "accept"
	}

  firewall { "00080 http on port 80":
    proto => "tcp",
    dport => "80",
    action => "accept"
  }

  firewall { "00443 http on port 443":
    proto => "tcp",
    dport => "443",
    action => "accept"
  }  

  firewall { "65536 drop incoming packets":
    action => 'drop'
  }

  # Dependencies for koji::hub
  class {'apache': }

  apache::mod{'ssl':}

  class {'krb5':
    autoupgrade => true,
    # Kerberos KDC.
    ensure => present,
  }

	krb5::realm{ 'MAKEWHATIS.COM':
		default_domain  => 'makewhatis.com',
		kdc             => ['localhost:88'],
		admin_server    => 'localhost',  
	}

	postgresql::pg_hba_rule { 'allow postgres user to access any database':
	    description => 'allow postgres user to access any database',
	    type => 'local',
	    database => 'all',
	    user => 'postgres',
	    auth_method => 'ident',
	    order => '000',
	}
	# Postgresql server.
	class { 'postgresql::server':
	  config_hash => {
	    'ip_mask_deny_postgres_user' => '0.0.0.0/32',
	    'ip_mask_allow_all_users'    => '0.0.0.0/0',
	    'listen_addresses'           => '*',
	    'manage_redhat_firewall'     => true,
	    'postgres_password'          => 'BiGM0n3y',
	  },
	}

	postgresql::db { 'koji':
	  user     => 'koji',
	  password => 'password',
	  require 		=> Postgresql::Role['koji'],
	}
	postgresql::database_user{'koji': 
		password_hash => postgresql_password('koji', 'password')
	}

	#postgresql::database_grant{'koji':
	#  privilege   => 'ALL',
	#  db          => 'koji',
	#  role 				=> 'koji',
	#  require 		=> Postgresql::Role['koji'], 
	#}
  class { 'openssl': }
  
  ssl_pkey { "/etc/pki/tls/private/koji.makewhatis.com.key": 
  	path => '/etc/pki/tls/private/koji.makewhatis.com.key',
  	ensure   => 'present',
	}
	x509_cert { '/etc/pki/tls/certs/koji.makewhatis.com.crt':
	  ensure      => 'present',
	  private_key => '/etc/pki/tls/private/koji.makewhatis.com.key',
	  days        => 4536,
	  force       => false,
	}
	# Koji-Hub software.
	#class {'koji::hub':
	#	auth 			=> 'ssl',
	#	db 				=> '127.0.0.1',
	#	web 			=> 'koji.makewhatis.com',
	#	realm 		=> 'MAKEWHATIS.COM',
	#}
}
