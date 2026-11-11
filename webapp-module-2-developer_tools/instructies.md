# Build the image
docker build -t webapp:1.0.0 .

#list the image
docker image list

#test the image local
docker run --rm -p 8080:8080 webapp:1.0.0
https://localhost:8080

#login to the stackit registry
# Je hebt je gewone STACKIT-wachtwoord gebruikt. Dat werkt hier niet. Je hebt de CLI secret nodig, een apart wachtwoord dat de registry voor je aanmaakt. Zo vind je die:
#
# 1) Ga naar het STACKIT Portal → Container Registry → Go to Container Registry.
# 2) Log in met je STACKIT-account.
# 3) Klik rechtsboven op je naam → User Profile.
# 4) Kopieer de waarde bij CLI secret. Dat is je wachtwoord voor docker login
docker login registry.onstackit.cloud -u remco.wildeboer@linkit.nl

# tag the local image
docker tag webapp:1.0.0 registry.onstackit.cloud/rw-fundamentals/webapp:1.0.0

# push the image to the stackit registry
docker push registry.onstackit.cloud/rw-fundamentals/webapp:1.0.0

