require 'test_helper'

class ConnectApiTest < Minitest::Test
  def test_credit_debit_notification_messages_endpoint_returns_credit_debit_notification_messages
    config = OpenStruct.new(api_base_url_production: 'http://lhv.test/connect-api')
    http_request = stub_request(:get, 'http://lhv.test/connect-api/messages/next')
                     .and_return({ status: 200,
                                   headers: {
                                     'message-response-type' => 'CREDIT_DEBIT_NOTIFICATION',
                                   } },
                                 { status: 404 })
    stub_request(:delete, /messages/)

    api = Lhv::ConnectApi.new(config: config)
    messages = api.credit_debit_notification_messages

    assert_requested http_request, times: 2
    assert_kind_of Lhv::ConnectApi::Messages::CreditDebitNotification, messages.first
  end

  def test_credit_debit_notification_messages_endpoint_acknowledges_response
    config = OpenStruct.new(api_base_url_production: 'http://lhv.test/connect-api')
    response_id = 'test'
    stub_request(:get, 'http://lhv.test/connect-api/messages/next')
      .and_return({ status: 200,
                    headers: {
                      'message-response-id' => response_id,
                    } },
                  { status: 404 })
    http_request = stub_request(:delete, "http://lhv.test/connect-api/messages/#{response_id}")

    api = Lhv::ConnectApi.new(config: config)
    api.credit_debit_notification_messages

    assert_requested http_request
  end

  def test_credit_debit_notification_messages_endpoint_skips_other_messages
    config = OpenStruct.new(api_base_url_production: 'http://lhv.test')
    stub_request(:get, 'http://lhv.test/messages/next')
      .and_return({ status: 200,
                    headers: {
                      'message-response-type' => 'NOT_CREDIT_DEBIT_NOTIFICATION',
                    } },
                  { status: 404 })
    stub_request(:delete, /messages/)

    api = Lhv::ConnectApi.new(config: config)
    messages = api.credit_debit_notification_messages

    assert_empty messages
  end

  def test_production_mode
    config = OpenStruct.new(api_base_url_production: 'https://production.test')

    api = Lhv::ConnectApi.new(config: config)
    api.dev_mode = false

    assert_equal URI('https://production.test'), api.api_base_uri
  end

  def test_development_mode
    config = OpenStruct.new(api_base_url_development: 'https://development.test')

    api = Lhv::ConnectApi.new(config: config)
    api.dev_mode = true

    assert_equal URI('https://development.test'), api.api_base_uri
  end
end
