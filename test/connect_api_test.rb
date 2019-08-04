require 'test_helper'

class ConnectApiTest < Minitest::Test
  def test_credit_debit_notification_messages_endpoint_returns_credit_debit_notification_messages
    api_uri = URI('http://lhv.test')
    http_request = stub_request(:get, api_uri + '/messages/next')
                     .and_return({ status: 200,
                                   headers: {
                                     'message-response-type' => 'CREDIT_DEBIT_NOTIFICATION',
                                   } },
                                 { status: 404 })
    stub_request(:delete, /messages/)

    api = Lhv::ConnectApi.new(uri: api_uri)
    messages = api.credit_debit_notification_messages

    assert_requested http_request, times: 2
    assert_kind_of Lhv::ConnectApi::Messages::CreditDebitNotification, messages.first
  end

  def test_credit_debit_notification_messages_endpoint_acknowledges_response
    api_uri = URI('http://lhv.test')
    response_id = 'test'
    stub_request(:get, api_uri + '/messages/next').and_return({ status: 200,
                                                                headers: {
                                                                  'message-response-id' =>
                                                                    response_id,
                                                                  'message-response-type' =>
                                                                    'CREDIT_DEBIT_NOTIFICATION',
                                                                } },
                                                              { status: 404 })
    http_request = stub_request(:delete, api_uri + "/messages/#{response_id}")

    api = Lhv::ConnectApi.new(uri: api_uri)
    api.credit_debit_notification_messages

    assert_requested http_request
  end

  def test_credit_debit_notification_messages_endpoint_skips_other_messages
    api_uri = URI('http://lhv.test')
    stub_request(:get, api_uri + '/messages/next').and_return({ status: 200,
                                                                headers: {
                                                                  'message-response-type' =>
                                                                    'NOT_CREDIT_DEBIT_NOTIFICATION',
                                                                } },
                                                              { status: 404 })

    api = Lhv::ConnectApi.new(uri: api_uri)
    messages = api.credit_debit_notification_messages

    assert_empty messages
  end
end
