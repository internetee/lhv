require 'net/http'

require 'keystores'
require 'logger'
require 'nokogiri'

require "lhv/version"
require 'lhv/config'
require 'lhv/connect_api'
require 'lhv/connect_api/messages/credit_debit_notification'

module Lhv
  class Error < StandardError; end

  def self.root
    Pathname(File.expand_path('../', __dir__))
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @@logger = logger
  end
end
