SHELL := /bin/bash

.PHONY: test validate smoke package clean sync-schema

test: validate smoke

validate:
	bash scripts/validate-project.sh

smoke:
	bash tests/smoke.sh

sync-schema:
	bash scripts/sync-schema-assets.sh

package: validate
	bash scripts/package.sh

clean:
	rm -f humanize-flow.zip
	find . -name '*.tmp' -delete
