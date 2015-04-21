#
# This module install and configure MariaDB for cpanel
#

class cpanel::mariadb (
    $version = '10.0'
) {

    file {'/var/mysql_tmp':
        ensure  => directory,
        owner   => 'mysql',
    }

    file { '/tmp/mysql.sock':
        ensure  => link,
        target  => '/var/lib/mysql/mysql.sock',
    }

    exec { 'disable rpm for MySQL5.0':
        command => '/scripts/update_local_rpm_versions --edit target_settings.MySQL50 uninstalled',
        unless  => '/bin/grep "MySQL50: uninstalled" /var/cpanel/rpm.versions.d/local.versions',
    }

    exec { 'disable rpm for MySQL5.1':
        command => '/scripts/update_local_rpm_versions --edit target_settings.MySQL51 uninstalled',
        unless  => '/bin/grep "MySQL51: uninstalled" /var/cpanel/rpm.versions.d/local.versions',
    }

    exec { 'disable rpm for MySQL5.5':
        command => '/scripts/update_local_rpm_versions --edit target_settings.MySQL55 uninstalled',
        unless  => '/bin/grep "MySQL55: uninstalled" /var/cpanel/rpm.versions.d/local.versions',
    }

    exec { 'uninstall mysql rpms':
        command => '/scripts/check_cpanel_rpms --fix --targets=MySQL50,MySQL51,MySQL55',
        unless  => '/usr/bin/mysql --version | /bin/grep MariaDB',
        require => Exec['disable rpm for MySQL5.5',
                        'disable rpm for MySQL5.1',
                        'disable rpm for MySQL5.0'],
    }

    notify { 'MySQL is no longer present on the system':
        require => Exec['uninstall mysql rpms'],
    }

    exec { 'reconfigure alt-php for mariadb':
        command     => '/usr/bin/alt-php-mysql-reconfigure',
        refreshonly => true,
    }

    file { '/etc/yum.repos.d/MariaDB.repo':
        content => template('cpanel/mariadb/repository.erb'),
    }

    package { ['MariaDB-server', 'MariaDB-client', 'MariaDB-devel', 'MariaDB-shared', 'MariaDB-compat',]:
        require => [File['/etc/yum.repos.d/MariaDB.repo'], Exec['uninstall mysql rpms']],
        notify  => Exec['reconfigure alt-php for mariadb'],
    }

# The cpanel service will start mysql anyway...
#    service { 'mysql':
#      require => Package['MariaDB-server', 'MariaDB-client', 'MariaDB-devel'],
#    }

    file { '/etc/my.cnf':
        content => template('cpanel/mariadb/my.cnf.erb'),
        require => Package['MariaDB-server', 'MariaDB-client', 'MariaDB-devel'],
        notify  => Service['mysql'],
    }

    file { '/etc/my.cnf.d':
        ensure  => directory,
        require => File['/etc/my.cnf'],
    }

    file { '/etc/my.cnf.d/mysql-clients.cnf':
        content => template('cpanel/mariadb/my.cnf.d_mysql-clients.cnf.erb'),
        require => File['/etc/my.cnf.d'],
    }

    file { '/etc/my.cnf.d/server.cnf':
        content => template('cpanel/mariadb/my.cnf.d_server.cnf.erb'),
        require => File['/etc/my.cnf.d'],
        notify  => Service['mysql'],
    }

    file { '/etc/my.cnf.d/tokudb.cnf':
        content => template('cpanel/mariadb/my.cnf.d_tokudb.cnf.erb'),
        require => File['/etc/my.cnf.d'],
    }
}
