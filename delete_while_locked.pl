#!/usr/bin/perl

use Fcntl qw/:seek :flock/;

if (@ARGV != 5) {
    print "Usage: $0 server exportdir /filename mountdir typeoflock\n";
    exit(0);
}

$server = $ARGV[0];
$exportdir = $ARGV[1];
$filename = $ARGV[2];
$mountdir = $ARGV[3];
$typeoflock = $ARGV[4];

$filecontents = "adsfuashdflaushflashfaslefhasfeasfea
asfrawetqwr2321351251nbktu3nfku3qnfrq@!46t!T!TqergeqrV@ yv32q%YV452
%C3q3t4QTQtcq3t4xq3TQt4cq\n\n\nasdasdsafsad\t\tadsfasdfawesd\n@%QTAQWFEAs\nsdasd";
$len = length($filecontents);

`echo \"${filecontents}\" > ./tempfile`;

# Create a new file with contents through dbench
if (! -d $mountdir) {
    `mkdir ${mountdir}`;
}
if (-e "$mountdir/$filename") {
    `rm -rf $mountdir/$filename`;
}

sleep(.5);
print "Creating file from dbench\n";
`./comm_create ${server} ${exportdir} ${filename}`;
sleep(.5);
`./comm_write ${server} ${exportdir} ${filename} 0 ${len} 0 ./tempfile`;
print "./comm_write ${server} ${exportdir} ${filename} 0 ${len} 0 ./tempfile\n";

# Mount through nfs kernel server and lock the new file
print "Mounting file\n";
`mount -o noac -t nfs ${server}:${exportdir} ${mountdir}`;
print "Opening and locking file\n";
open(my $FILE, "<", "$mountdir/$filename") or die "FAIL: Cannot open file: $mountdir/$filename\n";

if ($typeoflock eq "SHARED") {
    flock($FILE, LOCK_SH) or die "FAIL: Cannot share-lock file\n";
}
elsif ($typeoflock eq "EXCLUSIVE") {
    flock($FILE, LOCK_EX) or die "FAIL: Cannot exclusive-lock file\n";
}
else {
    print "FAIL: Lock type does not exist: $typeoflock\n";
    exit(1);
}

# Read
print "Reading from locked file\n";
$readcontents = "";
seek($FILE, 0, SEEK_SET);
while (<$FILE>) {
    $readcontents .= $_;
}

# Compare if contents are the same as earlier
if (! ($readcontents eq $filecontents)) {
    print "FAIL: Contents read from locked file are not the same as what was previously written.\n";
    exit(1);
}

if (-e "$mountdir/$filename") {
    print "File currently exists.\n";
}

# Remove the file through dbench
print "Removing file from dbench\n";
`./comm_remove ${server} ${exportdir} ${filename}`;

if (-e "$mountdir/$filename") {
    print "File still exists.\n";
} else {
    print "FAIL: File should not have been deleted!\n";
    exit(1);
}

# Make sure the file hasn't yet disappeared
print "Attempting to read from locked file which dbench tried to delete, this should succeed\n";
$readcontents = "";
seek($FILE, 0, SEEK_SET);
while (<$FILE>) {
    $readcontents .= $_;
}

# Compare if contents are the same as earlier
if (! ($readcontents eq $filecontents)) {
    print "FAIL: Contents read from locked file are not the same as what was previously written.\n";
    exit(1);
}

print "Unlocking file\n";
flock($FILE, LOCK_UN) or die "Cannot unlock file\n";

if (-e "$mountdir/$filename") {
    print "File still exists.\n";
} else {
    print "FAIL: File should not have been deleted after unlocking the file!\n";
    exit(1);
}

print "Attempting to read from unlocked file, this should fail\n";
$readcontents = "";
seek($FILE, 0, SEEK_SET);
while (<$FILE>) {
    $readcontents .= $_;
}

# Compare if contents are the same as earlier
if (! ($readcontents eq $filecontents)) {
    print "Contents read from unlocked file are not the same as what was previously written.\n";
    exit(1);
}

close($FILE);

if (-e "$mountdir/$filename") {
    print "FAIL: File still exists after closing the file!\n";
    exit(1);
} else {
    print "File was deleted after closing the file descriptor.\n";
}

`umount -l ${mountdir}`;
print "SUCCESS\n"
