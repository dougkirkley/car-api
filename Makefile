.PHONY: validate clean

validate: deploy
	terraform validate

clean:
	rm -f getCar/getCar addCars/addCars plan
	rm -rf out

destroy:
	terraform destroy

init:
	terraform init

plan:
	terraform plan -out=plan

deploy: init build plan
	terraform apply plan

build:
	mkdir out
	cd getCar && GOOS=linux GOARCH=amd64 go build && zip -r getCar.zip getCar && mv getCar.zip ../out
	cd addCars && GOOS=linux GOARCH=amd64 go build  && zip -r addCars.zip addCars && mv addCars.zip ../out
	aws s3 sync out/ s3://${S3_BUCKET}/

test:
	./test_api.sh
