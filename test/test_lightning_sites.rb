require "minitest/autorun"
FIXTURES_DIR = File.expand_path('fixtures', File.dirname(__FILE__))

class LightningSitesTest < Minitest::Test
    def validate_bad_sitemap
        build_dir = "#{FIXTURES_DIR}/sitemap_broken"
        assert_output(/Premature end of data in tag urlset line 3/) do
            Rake::Task['html:validate_sitemap'].invoke(build_dir)
        end
    end
end