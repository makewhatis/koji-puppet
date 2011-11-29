
# For simplicity, this one server will just do everything.
node 'koji.ktdreyer.com' {
	# System Kerberos configuration.
	class {'krb5':
		realm => 'KTDREYER.COM',
		# Kerberos KDC.
		admin_server => 'salt.ktdreyer.com',
	}

	# Postgresql server.
	class {'koji::db':
		# bootstrap this user.
		user => 'kdreyer',
		auth => 'kerberos', realm => 'KTDREYER.COM',
	}

	# Koji-Hub software.
	class {'koji::hub':
		auth => 'kerberos',
		db => '127.0.0.1',
		web => 'koji.ktdreyer.com',
		realm => 'KTDREYER.COM',
	}
	# Dependencies for koji::hub
	class {'httpd': }
	class {'iptables::webserver': }
	class {'cacert': }

	# Koji-Web software.
	class {'koji::web':
		auth => 'kerberos',
		hub => 'koji.ktdreyer.com',
		realm => 'KTDREYER.COM',
	}

	# Kojid software.
	class {'koji::builder':
		auth => 'kerberos',
		hub => 'koji.ktdreyer.com',
		allowed_scms => 'cvs.rpmfusion.org:/cvs/free:rpms',
		realm => 'KTDREYER.COM',
	}
	# SCM uses SSH
	class {'koji::builder::ssh': }

	# Kojira software.
	# Before activating this class, it is better to simply set up the user
	# with the koji cmdline client.
	#  $ koji add-user kojira --principal=kojira/kojiraserver.example.com@EXAMPLE.COM
	#  $ koji grant-permission repo kojira
	# (Otherwise, there will be an unprivileged kojira user automatically
	# created when the service starts for the first time.  With Kerberos
	# auth, you'll also end up with the UPN as the username, and you'll
	# have to manually edit the Postgres DB.)
	class {'koji::ra':
		auth => 'kerberos',
		hub => 'koji.ktdreyer.com',
		realm => 'KTDREYER.COM',
	}
}
