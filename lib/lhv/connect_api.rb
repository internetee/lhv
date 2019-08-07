module Lhv
  class ConnectApi
    attr_reader :config
    attr_reader :cert
    attr_reader :key
    attr_accessor :dev_mode

    def initialize(config: Config.new(filename: File.expand_path('../../config/connect_api.yml', __dir__)))
      @config = config
    end

    def api_base_uri
      if dev_mode
        config.api_base_url_development
      else
        config.api_base_url_production
      end
    end

    def credit_debit_notification_messages
      messages = []

      http.start do |http|
        loop do
          response = http.get('/messages/next')

          message_pending = response.kind_of?(Net::HTTPOK)
          break unless message_pending

          message_type = response['message-response-type']
          next unless message_type == 'CREDIT_DEBIT_NOTIFICATION'

          messages << Messages::CreditDebitNotification.new(Nokogiri::XML(response.body))
          acknowledge_response(response)
        end
      end

      messages
    end

    private

    def http
      http = Net::HTTP.new(api_base_uri.host, api_base_uri.port)
      http.use_ssl = api_base_uri.kind_of?(URI::HTTPS)
      http.cert = cert
      http.key = key
      http
    end

    # Without this `/messages/next` endpoint continuously returns the same response
    def acknowledge_response(response)
      id = response['message-response-id']
      http.delete("/messages/#{id}")
    end
  end
end
