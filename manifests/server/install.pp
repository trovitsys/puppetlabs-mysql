#
class mysql::server::install {

  package { 'mysql-server':
    ensure          => $mysql::server::package_ensure,
    install_options => $mysql::server::install_options,
    name            => $mysql::server::package_name,
  }

  # Build the initial databases.
  $mysqluser      = $mysql::server::options['mysqld']['user']
  $datadir        = $mysql::server::options['mysqld']['datadir']
  $basedir        = $mysql::server::options['mysqld']['basedir']
  $log_error      = $mysql::server::options['mysqld']['log_error']
  $innodb_log_dir = $mysql::server::options['mysqld']['innodb_log_group_home_dir']

  $config_file = $mysql::server::config_file

  if $mysql::server::manage_config_file {
    $install_db_args = "--basedir=${basedir} --defaults-extra-file=${config_file} --datadir=${datadir} --user=${mysqluser}"
  } else {
    $install_db_args = "--basedir=${basedir} --datadir=${datadir} --user=${mysqluser}"
  }

  ####
  # This block was added to "simulate" part of the work done by the debian
  # postinst scripts, that we removed because we need to customize innodb data
  # directory already on the first install. It's not nice and it's even uglier
  # to have to modify pupeptlabs mysql module, but it's really needed

  exec { 'mysql grp':
    command => 'groupadd -r mysql',
    unless  => 'grep -q mysql /etc/group'
  }

  exec { 'mysql usr':
    command => 'useradd -r -s /bin/false -g mysql -d /var/lib/mysql mysql',
    unless  => 'grep -q mysql /etc/passwd',
    require => Exec['mysql grp']
  }

  file { '/var/lib/mysql':
    ensure  => directory,
    owner   => $mysqluser,
    mode    => '0755',
    require => [Package['mysql-server'], Exec['mysql usr']]
  }

  if ( $innodb_log_dir != $datadir ) {
    file { $innodb_log_dir:
      ensure  => directory,
      owner   => $mysqluser,
      mode    => '0755',
      before  => Exec['mysql_install_db'],
      require => File['/var/lib/mysql']
    }
  }

  exec { 'replace init':
    command => "/bin/sed -i 's_MYADMIN=.*_MYADMIN=/usr/bin/mysqladmin_; s_export HOME=.*_export HOME=/root_'  /etc/init.d/mysql",
    onlyif  => '/bin/grep -q debian.cnf /etc/init.d/mysql',
    before  => Exec['mysql_install_db'],
    require => Package['mysql-server']
  }


  $log_error_dir = regsubst($log_error, '/[^/]{1,}$', '')
  if $log_error {
    $log_error_dir = mysql_dirname($log_error)
    file { $log_error_dir:
      ensure  => directory,
      owner   => $mysqluser,
      group   => 'adm',
      mode    => '0755',
      before  => Exec['mysql_install_db'],
      require => Package['mysql-server']
    }
  }


  ####

  exec { 'mysql_install_db':
    command   => "mysql_install_db ${install_db_args}",
    creates   => "${datadir}/mysql",
    logoutput => on_failure,
    path      => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    require   => Package['mysql-server'],
  }

  if $mysql::server::restart {
    Exec['mysql_install_db'] {
      notify => Class['mysql::server::service'],
    }
  }

}
