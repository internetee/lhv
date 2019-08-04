module Lhv
  class ConnectApi
    def initialize(uri:, cert: nil, key: nil)
      @http = init_http(uri: uri, cert: cert, key: key)
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

    attr_reader :http

    def init_http(uri:, cert:, key:)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.kind_of?(URI::HTTPS)
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
