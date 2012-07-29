#!/usr/bin/perl -w 

#use XML::Simple;
#use Data::Dumper;
#use Date::Manip;
use Getopt::Long;
use strict;

my $MYVERSION="1.0";
my $MYVERSION_CVS='$Revision: 1.3 $';
my $MYNAME="db2-cfg-info";

my $SCC_OUTPUT_ENABLED="0";
my $DB2_INST_DIR="/opt/IBM/db2/V8.1";
my $DEBUG=0;

sub print_version {
        my @tmp=split(/\s/,$MYVERSION_CVS);
        my $tmp=$tmp[1];
        print "$MYNAME ver $MYVERSION ver_cvs $tmp\n"
}

sub print_debug {
        my ( $msg, $level ) = @_;
        
        if ( ! defined($level) ) {
                $level=0;
        }
        if ( $DEBUG != 0 ) {
                print_msg("debug$level $msg","debug");
        }
}

sub print_options {
        my ($tmp)=@_;

        if ( $tmp eq "short" ) {
                print "[ -h ] [ -s 1/0 ]";
        } elsif ( $tmp eq "desc" ) {
                        print "  -h  print this help message\n";
                        print "  -v  print version and exit\n";                 
                        print "  -s  enable or disable the scc output formating, defaul $SCC_OUTPUT_ENABLED\n";
                        print "  -i  db2 instalation directory, defaul $DB2_INST_DIR\n";
                        print "  -d  set the debug 1 (on) or 0 (off), defaul $DEBUG\n";
                        
                        print "\n  i.e .... \n";
        }
}

sub simple_program_name {
        my $name;
        my @ltmp;

        @ltmp=split(/\// ,$0); #get the clean program name
        $name=$ltmp[ $#ltmp ]; #last element
        return $name;
}

sub usage {
        my $name=simple_program_name();

        print "usage: $name ";
        print_options("short");
        print "\n";
        print_options("desc");
}


sub print_msg_nonl {
        my ( $msg, $prefix) = @_;
        my $default_prefix="fix:db2";
        
        if ( $SCC_OUTPUT_ENABLED ) {
                if ( ! defined( $prefix ) ) {
                        $prefix=$default_prefix;
                } else {
                        $prefix="$default_prefix:$prefix";
                }
                print $prefix . "::" . $msg;
        } else {
                print $msg;
        }
}

# arg = ref to list of string or a single string 
# arg2: prefix string in form: xxx:yyy:zzz ... 
sub print_msg {
        my ( $msg, $prefix) = @_;
        my $default_prefix="fix:db2";
        
        if ( $SCC_OUTPUT_ENABLED ) {
                if ( ! defined( $prefix ) ) {
                        $prefix=$default_prefix;
                } else {
                        $prefix="$default_prefix:$prefix";
                }
                print $prefix . "::" . $msg;
        } else {
                print $msg;
        }
        print "\n";
}

#the ref to list of instance users
# return 0 ok, -1 error
sub get_db2_das_info {
        my ($ref_list) = @_;
        my @users;
        my $cmd="$DB2_INST_DIR/instance/daslist";
        
        @users=`$cmd`;
        #todo: check the error if the cmd was wrong
        
        foreach my $i ( @users ) {
                chomp($i); #remove the \n from names
        }
        
        @$ref_list=@users;      
        return 0;
}

#the ref to list of instance users
# return 0 ok, -1 error
sub get_db2_instance_users {
        my ($ref_list) = @_;
        my @users;
        my $cmd="$DB2_INST_DIR/bin/db2ilist";
        
        @users=`$cmd`;
        #todo: check the error if the cmd was wrong
        
        foreach my $i ( @users ) {
                chomp($i); #remove the \n from names
        }
        
        @$ref_list=@users;      
        return 0;
}

# $1 - instance user name
sub get_environment_cfg {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($id, $ids); 
        my @passwd_entries;
        my $home_dir;
        my @files;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="environment";
        my $prefix_tmp;
        my $tmp;
        #my MYFILE;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        #id/gid
        $id= getpwnam("$user_name");
        @passwd_entries=getpwuid($id);
        $home_dir=$passwd_entries[7];
        
        $ids=`id $user_name`;
        chomp($ids);
        if ( ! defined($ids) ) { $ids="can't execute the command: id $user_name"; }
        
        print_msg("user name=$user_name", $local_prefix_general);
        print_msg("user ids=$ids", $local_prefix_general);
        print_msg("user home_dir=$home_dir", $local_prefix_general);
        
        #ls in home dir
        # is it relevant?
        
        #bash environment, when log in 
        # or it is eneaf to control: bash_profile, .bashrc, .profile 
        @files = qw /bash_profile .bash_profile bashrc .bashrc profile .profile/;
        
        foreach my $i (@files ) {
                $tmp="$home_dir/$i";
                $prefix_tmp=$local_prefix . ":$i" ; 
                if ( -e $tmp ) {
                        print_msg("found file $tmp in home dir", $local_prefix_general);
                        open(MYFILE , '<', "$tmp");
            while ( $tmp=<MYFILE> ) {
                                print_msg_nonl($tmp, $prefix_tmp);
                        }
                } else {
                        print_msg("file $tmp, don't exist in user $user_name home directory", $local_prefix_general);
                }
        }
}


sub get_dbs_for_instance_user {
        my ($reflocal_dbs, $refremote_dbs, $user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_all_db_cfg";
        my (@tmp, $tmp, $db_name);
        my $cmd;
        my $home_dir;
        my $id;
        my (@ldbs, @rdbs);
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="$home_dir/sqllib/bin/db2 list db directory";
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);

        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
                if ( $i =~ /Database alias\s+=\s+(\w+)/ ) {
                        $db_name=$1;
                } elsif ( $i =~ /Directory entry type\s+=\s+(\w+)/ ) {
                        $tmp=$1; #Remote or Indirect word
                        if ( $tmp eq "Indirect" ) {
                                push(@ldbs, $db_name);
                        } else {
                                push(@rdbs, $db_name);
                        }
                        $db_name=undef;
                }
        }
        
        print_msg("the user $user_name has folgende db configured:", $local_prefix_general);
        print_msg("local  db'es: @ldbs", $local_prefix_general);
        print_msg("remote db'es: @rdbs", $local_prefix_general);
        
        @$reflocal_dbs=@ldbs;
        @$refremote_dbs=@rdbs;
}

sub get_db_cfg {
        my ($user_name, $db_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_${db_name}_db_cfg";
        my @tmp;
        my $cmd;
        my $home_dir;
        my $id;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="$home_dir/sqllib/bin/db2 get db cfg for $db_name";
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                if ( $i =~ /(\s+First active log file\s+=\s)/ ) {
                        print_msg("$1 not monitored", $local_prefix);
                } else {
                        print_msg_nonl($i, $local_prefix);
                }
        }
}

sub get_crontab_info {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="crontab";
        my $prefix_tmp;
        my @tmp;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        @tmp=`crontab -u $user_name -l 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        print_msg("crontab info for the user $user_name:", $local_prefix);
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub get_locale_setings {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="bash_locale";
        my $prefix_tmp;
        my @tmp;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        @tmp=`sudo su - $user_name -c locale 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub get_bash_env_setings {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="bash_env";
        my $prefix_tmp;
        my @tmp;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        @tmp=`sudo su - $user_name -c set 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                if ( $i !~ /\wPID=/ ) { # this is changing every time, generate only 'false' logs/messages and provide anything interested 
                        print_msg_nonl($i, $local_prefix);
                }
        }
}

sub get_db_info {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_info";
        my @tmp;
        my $cmd;
        my $home_dir;
        my $id;
        
        print_debug("get_db_info function start");
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="$home_dir/sqllib/bin/db2level";
        
        print_debug("id=$id user=$user_name home=$home_dir cmd=$cmd");
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub get_db_variables_info {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_set_variables";
        my @tmp;
        my $cmd;
        my $home_dir;
        my $id;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="$home_dir/sqllib/adm/db2set -all";
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub get_dbm_cfg {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_dbm_cfg";
        my @tmp;
        my $cmd;
        my $home_dir;
        my $id;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="$home_dir/sqllib/bin/db2 get dbm cfg";
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub get_nodes_for_instance_user {
        my ($user_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_nodes_cfg";
        my @tmp;
        my $cmd;
        my $home_dir;
        my $id;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="$home_dir/sqllib/bin/db2 list node directory show detail";
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub get_list_of_tables_in_db {
        my ($user_name, $db_name, $prefix, $prefix_general) = @_;
        my ($local_prefix, $local_prefix_general);
        my $prefix_aux="db2_${db_name}_all_tables";
        my @tmp;
        my $cmd;
        my $home_dir;
        my $id;
        
        $local_prefix="$prefix:$user_name:$prefix_aux";
        $local_prefix_general="$prefix:$prefix_general";
        
        $id= getpwnam("$user_name");
        @tmp=getpwuid($id);
        $home_dir=$tmp[7];
        $cmd="db2 change isolation to ur; db2 connect to $db_name; db2 list tables for all show detail; db2 connect reset";
        
        @tmp=`sudo su - $user_name -c "$cmd" 2>&1`;
        # todo, if error then print a info on $local_prefix_general
        # print_msg("error ... ", $local_prefix_general);
        
        foreach my $i ( @tmp ) {
                print_msg_nonl($i, $local_prefix);
        }
}

sub inst_users_info {
        my @db2_users=undef;
        my (@local_dbs, @remote_dbs);
        my $prefix="db2_inst_user";
        my $prefix_aus="general_info";
        my $tmp;
                
        print_debug("inst_users_info function start");
        
        if ( -1 == get_db2_instance_users(\@db2_users) ) {
                print_msg("I didn't found any db2 instance user on the host", $prefix . ":$prefix_aus");
                exit 0;
        }
        
        $tmp=0;
        foreach my $i ( @db2_users ) {
                $tmp++;
                print_msg("Evaluating instance user: nr=$tmp name=$i", $prefix . ":$prefix_aus");
                get_environment_cfg($i, $prefix, $prefix_aus);
                
                get_crontab_info($i, $prefix, $prefix_aus);
                get_bash_env_setings ($i, $prefix, $prefix_aus);
                get_locale_setings($i, $prefix, $prefix_aus);
                
                get_db_info($i, $prefix, $prefix_aus);
                get_db_variables_info($i, $prefix, $prefix_aus);
                get_dbm_cfg($i, $prefix, $prefix_aus);
                get_nodes_for_instance_user($i, $prefix, $prefix_aus);
                
                if ( -1 == get_dbs_for_instance_user(\@local_dbs, \@remote_dbs, $i, $prefix, $prefix_aus ) ) {
                        print_msg("the user $i dont have any usable db'ses", $prefix . ":$prefix_aus");
                } else {
                        foreach my $k ( @local_dbs ) {
                                print_msg("evaluating db $k for the user $i", $prefix . ":$prefix_aus");
                                get_db_cfg($i, $k, $prefix, $prefix_aus);
                                get_list_of_tables_in_db($i, $k, $prefix, $prefix_aus);
                        }
                }
        }
}

#todo: more info like for db2 instance user 
sub das_users_info {
        my @das_users=undef;
        my $prefix="db2_das_user";
        my $prefix_aus="general_info";
        my $tmp;
        
        print_debug("das_users_info function start");
        if ( -1 == get_db2_das_info(\@das_users) ) {
                print_msg("I didn't found any db2 instance user on the host", $prefix . ":$prefix_aus");
                return -1;
        }
        
        $tmp=0;
        foreach my $i ( @das_users ) {
                $tmp++;
                print_msg("Evaluating db2 das user: nr=$tmp name=$i", $prefix . ":$prefix_aus");
                get_environment_cfg($i, $prefix, $prefix_aus);
        }
}

sub main {
        my ( $opt_help, $opt_version, $opt_isscc, $opt_inst_dir, $opt_is_debug);
        my @db2_users;
        my $tmp;
        
        Getopt::Long::Configure ("bundling");
        GetOptions("h"   => \$opt_help,
                           "v"   => \$opt_version,      
                           "s=s" => \$opt_isscc,
                           "i=s" => \$opt_inst_dir,
                           "d=s" => \$opt_is_debug,
    );

    if ( $opt_help ) {
                usage();
                exit 0;
        }
        
        if ( $opt_version ) {
                print_version();
                exit 0;
        }

        if ( defined($opt_is_debug) ) {
                $DEBUG=$opt_is_debug;
                print_debug("turning debuging on");
        }
#       if ( (! defined($opt_database)) or (! defined($opt_table)) or (! defined($opt_row)) ) {
#               print "missing parameter\n";
#               usage();
#               exit -1;
#       }       
        
        if ( defined($opt_inst_dir) ) {
                $DB2_INST_DIR=$opt_inst_dir;
                # todo: check if the dir is correct, exist, etc. ...
        }
        
        if ( defined($opt_isscc) ) {
                if ( $opt_isscc == 0 or $opt_isscc==1 ) {
                        $SCC_OUTPUT_ENABLED=$opt_isscc;
                } else {
                        print_msg("wrong -s option, see the help for the program with -h option");
                        exit -1;
                }
        }
        
        das_users_info();
        inst_users_info();
}

main();
