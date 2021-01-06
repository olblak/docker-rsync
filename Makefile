.PHONY: build
DOCKER_IMAGE="olblak/rsyncd"
DOCKER_TAG="latest"

build: ## Build rsyncd Docker Image
	docker build --tag $(DOCKER_IMAGE):$(DOCKER_TAG) . 

help: ## Show this Makefile's help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

run: build ## Run rsyncd docker image on port 873
	docker run --interactive --tty --rm -p 873:873 --name rsyncd $(DOCKER_IMAGE):$(DOCKER_TAG) 

bash: ## Launch a shell inside the container rsyncd
	docker exec -i -t rsyncd bash

test: ## Run various tests. It requires "make run" from a different terminal
	@touch /tmp/fake

	@docker exec -i -t rsyncd /bin/bash -c "echo \"data\" > /srv/releases/jenkins/data"
	@/bin/bash -c "echo \"### Ensure we can't upload data ###\""
	@rsync -avz /tmp/fake rsync://localhost/jenkins/fake ;\
		RC=$$? ; echo $$RC ; \
		if [ $$RC -ne 12 ]; then \
			echo \"Not a read-only rsync server\"; \
		else \
			echo \"Success - Read only server\" ;\
		fi; 
	@/bin/bash -c "echo \"### Ensure we can download data:###\""
	@rsync -avz rsync://localhost/jenkins/data /tmp/data ; \
		RC=$$? ; \
		echo $$RC ; \
		if [ $$RC -ne 0 ]; then \
			echo \"Failure - Can\'t download data from rsync server\"; \
		else \
			echo \"Success - Can download data\" ;\
		fi;
