require 'test_helper'

class CreditDebitNotificationTest < Minitest::Test
  def test_returns_bank_account_iban
    iban = 'GB33BUKB20201555555555'

    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.054.001.02">
        <BkToCstmrDbtCdtNtfctn>
          <Ntfctn>
            <Acct>
              <Id>
                <IBAN>#{iban}</IBAN>
              </Id>
            </Acct>
          </Ntfctn>
        </BkToCstmrDbtCdtNtfctn>
      </Document>
    XML

    message = Lhv::ConnectApi::Messages::CreditDebitNotification.new(Nokogiri::XML(xml))

    assert_equal iban, message.bank_account_iban
  end

  def test_credit_transactions_returns_credit_transactions
    payment_reference_number = 'payment reference number'
    payment_description = 'payment description'

    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.054.001.02">
        <BkToCstmrDbtCdtNtfctn>
          <Ntfctn>
            <Ntry>
              <Amt Ccy="EUR">10.00</Amt>
              <CdtDbtInd>CRDT</CdtDbtInd>
              <BookgDt>
                <Dt>2010-07-05</Dt>
              </BookgDt>
              <NtryDtls>
                <TxDtls>
                  <RmtInf>
                    <Strd>
                      <CdtrRefInf>
                        <Ref>#{payment_reference_number}</Ref>
                      </CdtrRefInf>
                    </Strd>
                    <Ustrd>#{payment_description}</Ustrd>
                  </RmtInf>
                </TxDtls>
              </NtryDtls>
            </Ntry>
          </Ntfctn>
        </BkToCstmrDbtCdtNtfctn>
      </Document>
    XML

    message = Lhv::ConnectApi::Messages::CreditDebitNotification.new(Nokogiri::XML(xml))

    assert_equal 1, message.credit_transactions.size
    transaction = message.credit_transactions.first
    assert_equal 10, transaction.amount
    assert_equal 'EUR', transaction.currency
    assert_equal Date.parse('2010-07-05'), transaction.date
    assert_equal payment_reference_number, transaction.payment_reference_number
    assert_equal payment_description, transaction.payment_description
  end

  def test_credit_transactions_skips_debit_transactions
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.054.001.02">
        <BkToCstmrDbtCdtNtfctn>
          <Ntfctn>
            <Ntry>
              <CdtDbtInd>DBIT</CdtDbtInd>
            </Ntry>
          </Ntfctn>
        </BkToCstmrDbtCdtNtfctn>
      </Document>
    XML
    message = Lhv::ConnectApi::Messages::CreditDebitNotification.new(Nokogiri::XML(xml))
    assert_empty message.credit_transactions
  end
end
