# you can define the filter and options in your bash variables
# example: 
# T_FILTER='arp or icmp or not ip ( net 10.0.0.0/8 )
# T_OPTIONS='-s0 -nn'
 
# ------------------------------------------
 
# arg1 - filter to the wireshark
# arg2 - options to wireshark
mytcpdump () {
 # parse args
  
 DEFAULT_OPT='-s0 -l -nn -w - -i any'
  
 if [ 'x-h' = x"$1" ] ; then
  echo
  echo "usage: mytcpdump [arg1] [arg2]"
  echo " arg1 - wireshark network filter, by example: 'arp and (net 10/8)'"
  echo " arg2 - wireshark options, default: '$DEFAULT_OPT'"
  echo ""
  echo " example:"
  echo "   mytcpdump"
  echo "   mytcpdump '(net 10.0.0.0/8 and not net 11.0.0.0/8) and port 22'"
  echo "   mytcpdump '(net 10.0.0.0/8 and not net 11.0.0.0/8) and port 22' '-s0 -l -nn -i eth0 -w -' "
  echo
   
  return
 fi
  
 # filters
 if [ '1' != 1"$1" ] ; then
  filter="$1"
 elif [ '2' != 2"$T_FILTER" ]; then
  filter=$T_FILTER
 else
  filter=""
 fi
 
 # options
 if [ '1' != 1"$2" ] ; then
  opts="$2"
 elif [ '2' != 2"$T_OPTIONS" ]; then
  opts=$T_OPTIONS
 else
  opts="$DEFAULT_OPT"
 fi
  
 t=`date +%s`;
 echo "[$t]: timestamp is $t"
 echo "[$t]: wireshark optoins are <$opts>"
 echo "[$t]: wireshark filter is <$filter>"
 
 cmd="tcpdump $opts $filter"
 echo "[$t]: tcpdump cmd is <$cmd>"
  
 f="/var/tmp/tcpdump.$t.pcap"
 echo "[$t]: tcpdump pcap file <$f>"
  
 chain="$cmd | tee $f | tcpdump -r- -nn"
 echo "[$t]: running the bash command chains <$chain>"
  
 $cmd | tee $f | tcpdump -r- -nn
}
 
alias myt='mytcpdump'
