{
  fetchFromGitHub,
  buildGoModule,
  mockgen,
  protobuf,
  protoc-gen-go,
  lib,
}:
buildGoModule (finalAttrs: {
  pname = "phenix";
  version = "2026.06.09";

  src = fetchFromGitHub {
    owner = "sandialabs";
    repo = "sceptre-phenix";
    rev = "v${finalAttrs.version}";
    hash = "sha256-fkX4sX98uxPf/r9IPC8S5JjW9Wtgj5bp5i6FsDzWlxU=";
  };

  vendorHash = lib.fakeHash;

  modRoot = "src/go";

  subPackages = [
    "main.go"
    "tunneler"
  ];

  nativeBuildInputs = [
    mockgen
    protobuf
    protoc-gen-go
  ];

  overrideModAttrs = (
    finalModAttrs: previousModAttrs: {
      postPatch = (previousModAttrs.postPatch or "") + ''
        pushd src/go
        HOME=$(pwd)
        go mod edit -require=go.uber.org/mock@v0.5.0
        go get go.uber.org/mock@v0.5.0
        go mod tidy
        go mod vendor
        popd
      '';
    }
  );

  ldflags = [
    "-X phenix/version.Commit=${finalAttrs.version}"
    "-X phenix/version.Tag=${finalAttrs.version}"
    "-X phenix/version.Date=$DATE"
  ];

  preBuild = ''
    HOME=$(pwd)
    DATE=$(date -u)
    mockgen -self_package phenix/store -destination store/mock.go -package store phenix/store Store
    protoc -I . -I web/proto --go_out=paths=source_relative:. ./web/proto/*
    go generate web/rbac/known_policy_gen.go
  '';

  postCheck = ''
    go test -v -race ./...
  '';
})
