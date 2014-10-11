COMPRESS=java -jar $(HOME)/lib/htmlcompressor-1.5.3.jar --compress-js --compress-css --remove-surrounding-spaces all -r -m '*.html' -o

all:
	cd po && make
	./icons.sh
	./generate.pl
	$(COMPRESS) app app
	cd app && zip -r ../app.zip .

clean:
	rm -rf app locale app.zip app-icons/icon-*.png
