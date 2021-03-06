
#
#	pvmake  --  make verifier component if necessary
#
#
#	pvmake	component sourcedir destdir
#
#	Go to source directory
echo "\`$1':"
DIR=`pwd`
cd $2
#	Get makefile if necessary
if test ! -r makefile
then
    get src/s.makefile
fi
#	Do the indicated make
if make $1
then 
    echo "\`$1' generated."
    cd $DIR
    rm -f $3/$1
    ln $2/$1 $3
else
    echo "\`$1' -- make FAILED."
    exit 1
fi
