# vector-boshrelease

(unofficial) timberio/vector bosh release

>
>Vector is a lightweight, ultra-fast, open-source tool for building observability pipelines.
>see: https://vector.dev/docs/setup/configuration/
>see: https://vector.dev/docs/reference/
>

## deploying standalone

```sh
bosh -d vector-standalone deploy manifests/vector-standalone.yml \
  -l manifests/vars.yml \
  -l manifests/versions.yml
```

## vendoring vector

The primary binary in this repository is from upstream `timberio/vector`. It's retrieved using the [`k14s/vendir`](https://github.com/k14s/vendir) cli and `vendir.yml`. Just run `vendir sync` and it'll pull the vector binary from an upstream github release and move it into this repository locally.

If you need to update the version of `vector`, update it in `vendir.yml`, then `vendir sync`; git add updates, commit it.

It's a small binary, so instead of using a blobstore we're just going to bite the bullet and store it in plain `git` as a normal file.

## cutting releases

make sure you are all up-to-date:

```sh
cd vector-boshrelease
git checkout main
git pull origin main
```

now for actually creating the release:

```sh
git checkout -b release-x.y.z

# place the release tgz in your /tmp dir in order to calculate a shasum on it, and to upload to a github release
bosh create-release --final --version=x.y.z --tarball=/tmp/vector-boshrelease-x.y.z.tgz

# this will be used to update the versions.yml
shasum -a 1 /tmp/vector-boshrelease-x.y.z.tgz

# use that shasum value to update the manifests/versions.yml
vector_boshrelease_sha1: 582c112d4621361a031e530885f5653868f1bbd0
vector_boshrelease_version: x.y.z

# git commit all of this to the branch
git add -A
git commit -m "release-x.y.z"
git push origin release-x.y.z

# then from the PR you've opened for this release, squash 'n merge it into main
```

now for making the release available as an actual github release:

```sh
# after squashing and merging into main...
git checkout main
git pull origin main

# notice the lack of 'v' prefix. not a fan of it.
git tag x.y.z
git push origin --tags
```

then go to the github releases page, click on the release for the newly created tag, and configure the release with a title, release notes, and an asset copy of the tarball from `/tmp/vector-boshrelease-x.y.z.tgz`

voila, you're set.
