.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | \
	sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install dependencies
	@mix deps.get && \
	mix deps.compile

.PHONY: lint
lint: ## Lint code with Credo
	@mix credo --strict

.PHONY: create-docs
create-docs: ## Create the documentation
	@mix docs

.PHONY: analyze
analyze: ## Run a static analysis with Dialyzer
	@mix dialyzer

.PHONY: publish-package
publish-pakcage: ## Publish the package
	@mix hex.publish package

.PHONY: publish-docs
publish-docs: ## Publish the documentation
	@mix hex.publish docs
