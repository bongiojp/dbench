#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <getopt.h>
#include <sys/time.h>
#include <math.h>

//#include "dbench.h"
#include "nfs.h"
#include "mount.h"
#include "libnfs.h"

#include "comm.h"

int main(int argc, char **argv) {
  char *hostname, *directory, *filename;
  char *inputfile;
  nfsstat3 nfs_status;
  struct nfsio * nfsio;
  unsigned long long offset;
  int len, stable, fd;
  int count;

  /* hostname directory pathname */
  if (argc != 8) {
    printf("Not enough arguments to %s\n", argv[0]);
    printf("Usage: %s hostname exportdir filename offset length stable inputfile\n", argv[0]);
    exit(1);
  }

  hostname = argv[1];
  directory = argv[2];
  filename = argv[3];
  offset = atoll(argv[4]);
  len = atoi(argv[5]);
  stable = atoi(argv[6]);
  inputfile = argv[7];  

  /* Connect */
  nfsio = nfs_connect(hostname, directory);
  if (nfsio == NULL) {
    printf("FAIL: Could not connect to server\n");
    return -1;
  }

  /* prepare buffer to write to remote file */
  char buf[len];
  fd = open(inputfile, "r");
  count = read(fd, buf, len);
  close(fd);
  if (count != len) {
    printf("FAIL: Could not read %d bytes from the file %s at offset %lld\n",
           len, inputfile, offset);
    exit(1);
  }

  /* write */
  nfs_status = nfsio_write(nfsio, filename, buf, offset, len, stable);
  if (nfs_status != NFS3_OK) {
    printf ("FAIL: Could not write to file: %d\n", nfs_status);
      print_nfs_status(nfs_status);
    return -1;
  }

  /* Disconnect */
  if (nfsio != NULL)
    nfsio_disconnect(nfsio);

  return 0;
}
