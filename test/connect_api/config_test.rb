require 'test_helper'

class ConfigTest < Minitest::Test
  def test_reads_config_file
    config = Lhv::Config.new(filename: 'test/fixtures/config.yml')
    assert_equal 'bar', config.foo
  end
end
