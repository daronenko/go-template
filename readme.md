# Go Template

## Requirements

- [go](https://go.dev/doc/install)
- [goose](https://github.com/pressly/goose)
- [golangci-lint](https://golangci-lint.run/welcome/install/#local-installation)
- [make](https://www.gnu.org/software/make/)
- [docker](https://docs.docker.com/get-started/get-docker/)
- [docker compose](https://docs.docker.com/compose/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [minikube](https://kubernetes.io/ru/docs/tasks/tools/install-minikube/)

## Getting Started

1. Run `make help` to get documentation

```shell
make help
```

2. Try some commands inside microservice directory

```shell
cd service/hello

make lint
make format

make test
make view-coverage-html

make docker-build

make docker-postgres-migrate
make docker-start
make postgres-state

make docker-ash  # run `exit` to exit
make docker-psql  # run `\q` to exit

curl localhost:8080/health

make docker-stop
```

3. Try to deploy project to `minikube` cluster

```shell
cd ../..  # go to root of the project

make cluster

make deploy
make deploy-postgres-migrate service=hello

make port-forwarding

# add line `127.0.0.1 deploy.local` to the `/etc/hosts` file
echo '127.0.0.1 deploy.local' | sudo tee -a /etc/hosts >> /dev/null

curl -k https://deploy.local/api/hello/health

make delete-cluster
```
