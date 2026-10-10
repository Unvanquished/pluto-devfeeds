## Fixing XML feed parsing with REXML

### Problem

Running `bundle exec pluto update planet.ini` may fail when parsing the `UnvanquishedAssets` Atom feed with:

```text
RSS::NotWellFormedError: This is not well formed XML
entity expansion has grown too large
```

The feeds are valid XML, the error originated from the system-provided REXML 3.2.3.1 parser.
It incorrectly hit its entity-expansion text limit while processing feed content containing many escaped HTML entities.

### Solution

The project now includes a newer REXML dependency:

```ruby
gem "rexml", "~> 3.3", ">= 3.3.5"
```

Bundler resolved REXML 3.4.4 and installed it in `vendor/bundle`.
But Ruby activated the system default REXML 3.2.3.1 before Bundler can select the bundled version.
To work around this, the Ruby load path must include the bundled REXML library before invoking Bundler:

```bash
export RUBYOPT="-I${PWD}/vendor/bundle/ruby/2.7.0/gems/rexml-3.4.4/lib"
```

Then we should run Pluto using the project's Bundler installation:

```bash
${HOME}/.gem/ruby/2.7.0/bin/bundle _2.4.22_ exec pluto update planet.ini
```

The load-path override ensures REXML 3.4.4 is loaded instead of the system version.
The fix does not require raising REXML's entity-expansion security limits.

### Verification

Test both feeds with the default REXML security settings:

```bash
RUBYOPT="-I${PWD}/vendor/bundle/ruby/2.7.0/gems/rexml-3.4.4/lib" \
  "${HOME}/.gem/ruby/2.7.0/bin/bundle _2.4.22_" exec ruby -rrss -e '
puts "REXML: #{REXML::VERSION}"

ARGV.each do |path|
  begin
    RSS::Parser.parse(File.read(path), false, false)
    puts "OK: #{path}"
  rescue => e
    warn "FAIL: #{path}: #{e.class}: #{e.message}"
  end
end
' /tmp/Unvanquished-live.xml /tmp/UnvanquishedAssets-live.xml
```

Both feeds should parse successfully.
Running `pluto update planet.ini` should then complete without the entity-expansion error.

### Notes

This keeps:

- `Gemfile.lock` committed to preserve the resolved dependencies.
-  REXML's default security limits enabled.
- the load-path override and Bundler executable path above are specific to this deployment.
   If the Ruby version, REXML version, or installation paths change,
   they should be updated accordingly.
