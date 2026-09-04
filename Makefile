LINTER_VERSION := v2.13.2

.PHONY: check
check: lint test

.PHONY: get-deps
get-deps:
	go get -v -t -d ./...

.PHONY: lint
lint: ./bin/linter
	./bin/linter run ./...

.PHONY: test
test:
	go test -race -count=1 ./...

.PHONY: coverage
coverage:
	go test -race -v -coverprofile=profile.cov -covermode=atomic ./...

# Download the release tarball directly. The upstream install.sh checksum
# lookup matches both *.tar.gz and *.tar.gz.sbom.json in v2.13.x.
bin/linter: Makefile
	mkdir -p ./bin
	tmpdir=$$(mktemp -d) && \
	os=$$(go env GOOS) && \
	arch=$$(go env GOARCH) && \
	ver=$(LINTER_VERSION) && \
	vernum=$${ver#v} && \
	asset="golangci-lint-$${vernum}-$${os}-$${arch}.tar.gz" && \
	curl -sSfL "https://github.com/golangci/golangci-lint/releases/download/$${ver}/$${asset}" -o "$$tmpdir/$${asset}" && \
	curl -sSfL "https://github.com/golangci/golangci-lint/releases/download/$${ver}/golangci-lint-$${vernum}-checksums.txt" -o "$$tmpdir/checksums.txt" && \
	want=$$(grep " $${asset}$$" "$$tmpdir/checksums.txt" | awk '{print $$1}') && \
	got=$$(sha256sum "$$tmpdir/$${asset}" | awk '{print $$1}') && \
	test -n "$$want" && test "$$want" = "$$got" && \
	tar -xzf "$$tmpdir/$${asset}" -C "$$tmpdir" && \
	mv "$$tmpdir"/golangci-lint-*/golangci-lint ./bin/linter && \
	rm -rf "$$tmpdir"
