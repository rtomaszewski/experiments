#include <stdio.h>
#include <stdlib.h>
#include <execinfo.h>
#include <signal.h>
#include <string.h>
 
void try_core1(int n);
void try_core2(int n);
void try_core3(int n);
void generate_core(int n);
 
void generate_core( int n ) {
  if ( 1 == (n%10) ) { 
    try_core1(n);
    generate_core(n-1);
  } 
   
  if ( 2 == (n%10) ) { 
    try_core2(n);
    generate_core(n-1);
  } 
   
  if ( 3 == (n%10) ) { 
    try_core3(n);
    generate_core(n-1);
  } 
   
  generate_core(n-1);
}
 
void try_core1( int n ) {
  char *ptr=NULL;
   
  strcpy(ptr, "this is going to hurt ;)...");
}
 
void try_core2( int n ) {
  int *ptr=NULL;
   
  *ptr=n;
}
 
void try_core3( int n ) {
  int *ptr;
   
  *(ptr+n)=n; 
}
 
 
int main(int argc, char **argv) {
  generate_core( atoi( argv[1] ) );
}
 