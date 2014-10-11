#!/bin/bash

fig2dev -j -L gif -b 5 -S 4 -m 40 -t yellow test-tube.fig test-tube.gif

convert test-tube.gif -gravity Center -crop 3250x3250+0-20 -define png:color-type=6 tt.png

rm test-tube.gif

for foo in 512 256 128 90 64 60 48 32 16
do
	convert tt.png -resize ${foo}x${foo} app-icons/icon-${foo}.png
done

rm tt.png
