class koji::db($auth, $user = 'NONE', $realm = 'NONE') {
	package { 'postgresql-server':
		ensure => installed,
	}
	service { 'postgresql':
		ensure => running,
		enable => true,
		hasstatus => true,
		hasrestart => true,
		require => [
			Package['postgresql-server'],
			Exec['Init postgres db'],
		],
	}
	user { 'koji':
		ensure => present,
	}

	# Initialize the DB server
	exec { 'Init postgres db':
		command => '/usr/bin/initdb',
		environment => 'PGDATA=/var/lib/pgsql/data',
		user => 'postgres',
		unless => '/usr/bin/file $PGDATA/postgresql.conf',
		require => Package['postgresql-server'],
	}
	file { '/var/lib/pgsql/data/pg_hba.conf':
		source => 'puppet:///modules/koji/db/pg_hba.conf',
		notify => Service['postgresql'],
		require => Exec['Init postgres db'],
		owner => 'postgres', group => 'postgres',
		mode => '600',
	}

	# Set up the basic koji DB contents
	exec { 'Create koji postgres role':
		command => '/usr/bin/createuser --no-superuser --no-createdb --no-createrole koji',
		user => 'postgres',
		unless => "/usr/bin/psql -c '\\du' | grep '^ *koji *|'",
		require => Exec['Init postgres db'],
	}
	exec { 'Create koji postgres db':
		command => '/usr/bin/createdb -O koji koji',
		user => 'postgres',
		unless => "/usr/bin/psql -l | grep 'koji *|'",
		require => Exec['Create koji postgres role'],
	}
	exec { 'Populate koji postgres db':
		# the wiki says to omit "-1.6.0" here. We'll see.
		command => '/usr/bin/psql koji < /usr/share/doc/koji-1.6.0/docs/schema.sql',
		user => 'koji',
		# Check that a random table exists, eg. the "buildroot" table.
		unless => "/usr/bin/psql koji -c '\\d' | grep 'buildroot *|'",
		require => Exec['Create koji postgres db'],
	}
	
	# Conditionally bootstrap an admin user.
	if( $user != 'NONE' ) {
		# Set up a SQL statement, depending on SSL or Kerberos.
		case $auth {
			kerberos: {
				if( $realm == 'NONE' ) {
					fail('If you use Kerberos authentication, you must specify a $realm.')
				}
				$sql = "INSERT INTO users (name, krb_principal, status, usertype) VALUES ('${user}', '${user}@${realm}', 0, 0);"
			}
			ssl: {
				$sql = "INSERT INTO users (name, status, usertype) VALUES ('${user}', 0, 0);"
			}
			default: {
				fail('Unrecognized auth type for DB.')
			}
		}
		
		# Insert the $user into the DB using the $sql statement.
		exec { 'Bootstrap admin koji user':

			command => "/usr/bin/psql koji -c \"${sql}\"",
			user => 'koji',
			# Check that the user account exists.
			unless => "/usr/bin/psql koji -c 'SELECT name FROM users' | grep '${user}'",
			require => Exec['Create koji postgres db'],
		}
		
		# Give the $user admin privileges.
		# Note that this is pretty hacky. We just give admin privs to
		# UID "1" here, without checking that $user is really UID 1. If
		# it's truly a bootstrap from a completely fresh DB, it
		# shouldn't matter.
		exec { 'Bootstrap admin koji privs':

			command => "/usr/bin/psql koji -c \"INSERT INTO user_perms (user_id, perm_id, creator_id) VALUES (1, 1, 1);\"",
			user => 'koji',
			# Check that the user's privs exists.
			unless => "/usr/bin/psql koji -c 'SELECT user_id FROM user_perms' | grep '1'",
			require => Exec['Bootstrap admin koji user'],
		}
	}
}

