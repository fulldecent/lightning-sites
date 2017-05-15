require "spec_helper"

RSpec.describe LightningSites do
  it "has a version number" do
    expect(LightningSites::VERSION).not_to be nil
  end

  it "validate bad sitemap" do
    build_dir = "#{FIXTURES_DIR}/sitemap_broken"
    expect { Rake::Task['html:validate_sitemap'].invoke(build_dir) }
        .to output(%r{Premature end of data in tag urlset line 3}).to_stdout
  end
end
