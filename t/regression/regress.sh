#!/bin/bash

for TYPE in "alice alice" "minotaur minotaur" "plank plank" \
    "hex_plank plank/hex" "plank plank/sample" "numbers number_mazes" \
    "tilt_single tilt/single" "tilt_multi tilt/multi" "tilt_rb tilt/red_blue" \
    ; do
    maze_type=$(sh -c "echo \$0" $TYPE)
    dir=$(sh -c "echo \$1" $TYPE)
    if [ ! -e ./layouts/$dir ] ; then
        echo "$dir does not exist"
    fi
    mkdir -p checksums/$dir
    (cd ./layouts/$dir/; ls) | 
        (while read T ; do 
            if [ -f ./layouts/$dir/$T ] ; then
                (cd ../../ && ./lm-solve -g $maze_type --rtd --method brfs t/regression/layouts/$dir/$T) | md5sum > checksums/$dir/$T.brfs.md5.new
                (cd ../../ && ./lm-solve -g $maze_type --rtd --method dfs t/regression/layouts/$dir/$T) | md5sum > checksums/$dir/$T.dfs.md5.new
                if ! cmp checksums/$dir/$T.brfs.md5.new checksums/$dir/$T.brfs.md5 ; then
                    echo "Brfs solutions are not equal for $dir/$T"
                fi

                if ! cmp checksums/$dir/$T.dfs.md5.new checksums/$dir/$T.dfs.md5 ; then
                    echo "DFS solutions are not equal for $dir/$T"
                fi
            fi
        done
        )
done
