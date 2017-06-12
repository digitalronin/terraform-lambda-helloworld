deploy: helloworld.zip
	terraform apply

helloworld.zip: helloWorld.js
	zip -r9 helloworld.zip helloWorld.js
