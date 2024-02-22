# -e says exit immediately when a command fails
# -o sets pipefail, meaning if it exits with a failing command, the exit code should be of the failing command
# -u fails a bash script immediately if a variable is unset
ENVIRONMENT := test
PGHOST := localhost
PGPORT := 5432
PGUSER := myuser
PGPASSWORD := mypassword
SHELL = /bin/bash -eu -o pipefail

define is_installed
if ! command -v $(1) &> /dev/null; \
then \
	echo "$(1) not installed, please install it. 'brew install $(1)'"; \
	exit; \
fi;
endef

.PHONY : help
help : # Display help
	@awk -F ':|##' \
		'/^[^\t].+?:.*?##/ {\
			printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
		}' $(MAKEFILE_LIST)

.PHONY : ruby_installed
ruby_installed: ## check if ruby is installed
	@$(call is_installed,ruby)

.PHONY : bundle
bundle: ruby_installed ## install gems
	@bundle install --gemfile spec/Gemfile && cd spec/dummy && bundle install

.PHONY : setup_db
setup_db: ruby_installed postgres ## setup database
	@echo "setting up database"
	@cd spec/dummy && bundle exec rake db:create db:migrate --trace RAILS_ENV=${ENVIRONMENT}

.PHONY : initialize_profiling
initialize_profiling: ruby_installed ## initialize rspec_profiling
	@echo "initializing rspec_profiling"
	@cd spec/dummy && bundle exec rake rspec_profiling:install RAILS_ENV=${ENVIRONMENT}

.PHONY : spec
spec : bundle setup_db initialize_profiling ## run specs
	@echo "running specs"
	@bundle exec --gemfile=spec/dummy/Gemfile rspec

.PHONY : test
test: spec ## run specs
	@echo "running specs"

.PHONY : docker_installed
docker_installed: ## check if docker and docker-compose are installed
	@$(call is_installed,docker)
	@$(call is_installed,docker-compose)

.PHONY : postgres
postgres: docker_installed ## start postgres in docker container
	@docker-compose up -d || true
