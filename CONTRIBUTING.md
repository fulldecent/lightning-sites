# Releasing new versions

Documentation referred from http://guides.rubygems.org/publishing/ and https://bundler.io/v1.13/guides/creating_gem

1. Update version number manually (`gem bump --version minor` fails, I don't know why)
2. Build the gem with `rake build`
3. Publish with `gem push pkg/lightning_sites-*.gem`
4. Make tag and relesae in GitHub.
