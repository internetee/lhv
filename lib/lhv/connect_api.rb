module Lhv
  class ConnectApi
    attr_reader :config
    attr_accessor :ca_file
    attr_accessor :cert
    attr_accessor :key
    attr_accessor :dev_mode

    def initialize(config: Config.new(filename: 'config/connect_api.yml'))
      @config = config
    end

    def api_base_uri
      url = if dev_mode
              config.api_base_url_development
            else
              config.api_base_url_production
            end

      URI(url)
    end

    def credit_debit_notification_messages
      messages = []

      http.start do |http|
        loop do
          response = get_request(http: http, retries_left: 3)

          message_pending = response.kind_of?(Net::HTTPOK)
          break unless message_pending

          acknowledge_response(response)

          message_type = response['message-response-type']
          next unless message_type == 'CREDIT_DEBIT_NOTIFICATION'

          messages << Messages::CreditDebitNotification.new(Nokogiri::XML(response.body))
        end
      end
      Lhv.logger.info 'Got the following messages'
      Lhv.logger.info messages

      messages
    end

    private

    def get_request(http:, retries_left: 3)
      return if retries_left <= 0

      http.get(api_base_uri.path + '/messages/next')
    rescue Net::OpenTimeout => e
      Lhv.logger.warn "TRY #{4 - retries_left}/3. Timed out while trying to connect #{e}"
      if retries_left <= 1
        Lhv.logger.error "Net::OpenTimeout while trying to connect #{e}. Retries limit exceeded"
        raise e
      end
      get_request(http: http, retries_left: retries_left - 1)
    end

    def http
      http = Net::HTTP.new(api_base_uri.host, api_base_uri.port)
      http.use_ssl = api_base_uri.kind_of?(URI::HTTPS)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if dev_mode
      http.ca_file = ca_file
      http.cert = cert
      http.key = key
      http
    end

    # Without this `/messages/next` endpoint continuously returns the same response
    def acknowledge_response(response)
      id = response['message-response-id']
      http.delete(api_base_uri.path + "/messages/#{id}")
    end
  end
end
