.PHONY: clean all install

all: clean install
	
install: 
	sudo gem install cocoapods
	pod install

clean: 
	rm -rf "${HOME}/Library/Caches/CocoaPods"
	rm -rf Pods/
	rm Comeet.xcworkspace
	pod install