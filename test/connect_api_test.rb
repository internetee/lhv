require 'test_helper'

class ConnectApiTest < Minitest::Test
  def test_credit_debit_notification_messages_endpoint_returns_credit_debit_notification_messages
    api_base_uri = URI('http://lhv.test')
    config = OpenStruct.new(api_base_url_production: api_base_uri)
    http_request = stub_request(:get, api_base_uri + '/messages/next')
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
    api_base_uri = URI('http://lhv.test')
    config = OpenStruct.new(api_base_url_production: api_base_uri)
    response_id = 'test'
    stub_request(:get, api_base_uri + '/messages/next').and_return({ status: 200,
                                                                     headers: {
                                                                       'message-response-id' =>
                                                                         response_id,
                                                                       'message-response-type' =>
                                                                         'CREDIT_DEBIT_NOTIFICATION',
                                                                     } },
                                                                   { status: 404 })
    http_request = stub_request(:delete, api_base_uri + "/messages/#{response_id}")

    api = Lhv::ConnectApi.new(config: config)
    api.credit_debit_notification_messages

    assert_requested http_request
  end

  def test_credit_debit_notification_messages_endpoint_skips_other_messages
    api_base_uri = URI('http://lhv.test')
    config = OpenStruct.new(api_base_url_production: api_base_uri)
    stub_request(:get, api_base_uri + '/messages/next').and_return({ status: 200,
                                                                     headers: {
                                                                       'message-response-type' =>
                                                                         'NOT_CREDIT_DEBIT_NOTIFICATION',
                                                                     } },
                                                                   { status: 404 })

    api = Lhv::ConnectApi.new(config: config)
    messages = api.credit_debit_notification_messages

    assert_empty messages
  end

  def test_production_mode
    api_base_uri = URI('https://production.test')
    config = OpenStruct.new(api_base_url_production: api_base_uri)

    api = Lhv::ConnectApi.new(config: config)
    api.dev_mode = false

    assert_equal api_base_uri, api.api_base_uri
  end

  def test_development_mode
    api_base_uri = URI('https://development.test')
    config = OpenStruct.new(api_base_url_development: api_base_uri)

    api = Lhv::ConnectApi.new(config: config)
    api.dev_mode = true

    assert_equal api_base_uri, api.api_base_uri
  end
end