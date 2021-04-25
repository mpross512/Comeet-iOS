.PHONY: clean all install cleanWithoutInstall

all: cleanWithoutInstall install
	
install: 
	sudo gem install cocoapods
	pod install

clean: 
	rm -rf "${HOME}/Library/Caches/CocoaPods"
	rm -rf Pods/
	rm -rf Comeet.xcworkspace
	pod install

cleanWithoutInstall:
	rm -rf "${HOME}/Library/Caches/CocoaPods"
	rm -rf Pods/
	rm -rf Comeet.xcworkspace
