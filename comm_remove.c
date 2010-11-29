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
  nfsstat3 nfs_status;
  struct nfsio * nfsio;
  
  /* hostname directory pathname */
  if (argc < 3) {
  }

  hostname = argv[1];
  directory = argv[2];
  filename = argv[3];

  /* Connect */
  nfsio = nfs_connect(hostname, directory);
  if (nfsio == NULL) {
    printf("FAIL: Could not connect to server\n");
    return -1;
  }

  nfs_status = nfsio_remove(nfsio, filename);
  if (nfs_status != NFS3_OK) {
    printf ("FAIL: Could not remove file: %d\n", nfs_status);
      print_nfs_status(nfs_status);
    return -1;
  }

  /* Disconnect */
  if (nfsio != NULL)
    nfsio_disconnect(nfsio);

  return 0;
}
