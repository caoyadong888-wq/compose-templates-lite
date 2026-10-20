.PHONY: demo demo-down test

demo:
	./demo.sh

demo-down:
	docker compose -f 01-nginx-https/docker-compose.yml down -v --remove-orphans

test:
	bash tests/run_tests.sh
