#!/bin/sh

echo "Perform -C tests."
# Test the read any, write litC case.
../bin/envutil -C ./litC/sample.svn -o ans.env
diff ans.env ./litC/sample.svn
../bin/envutil -C ./bigC/sample.svn -o ans.env
diff ans.env ./litC/sample.svn
../bin/envutil -C ./bigFort/sample.svn -o ans.env
diff ans.env ./litC/sample.svn

# Test the read any, write BigC case.
../bin/envutil -C ./litC/sample.svn -o ans.env -b
diff ans.env ./bigC/sample.svn
../bin/envutil -C ./bigC/sample.svn -o ans.env -b
diff ans.env ./bigC/sample.svn
../bin/envutil -C ./bigFort/sample.svn -o ans.env -b
diff ans.env ./bigC/sample.svn

# Test the read any, write BigC case.
../bin/envutil -C ./litC/sample.svn -o ans.env -bf
diff ans.env ./bigFort/sample.svn
../bin/envutil -C ./bigC/sample.svn -o ans.env -bf
diff ans.env ./bigFort/sample.svn
../bin/envutil -C ./bigFort/sample.svn -o ans.env -bf
diff ans.env ./bigFort/sample.svn

echo "Perform -D tests."
# Test the diff command
../bin/envutil -D ./litC/sample.svn ./bigC/sample.svn
../bin/envutil -D ./bigC/sample.svn ./bigFort/sample.svn
../bin/envutil -D ./bigFort/sample.svn ./litC/sample.svn

echo "Perform -S tests."
../bin/envutil -S1 ./litC/sample.svn > stat1.txt
diff -b stat1.txt ./ans/stat1.txt
../bin/envutil -S2 ./litC/sample.svn > stat2.txt
diff -b stat2.txt ./ans/stat2.txt
../bin/envutil -S3 ./litC/sample.svn > stat3.txt
diff -b stat3.txt ./ans/stat3.txt

