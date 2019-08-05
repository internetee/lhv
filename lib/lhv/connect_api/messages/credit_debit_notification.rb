module Lhv
  class ConnectApi
    module Messages
      class CreditDebitNotification
        Transaction = Struct.new(:amount, :payment_reference_number, :payment_description)

        def initialize(xml_doc)
          @xml_doc = xml_doc
        end

        def bank_account_iban
          xml_doc.at_css('BkToCstmrDbtCdtNtfctn > Ntfctn > Acct > Id > IBAN').text
        end

        def credit_transactions
          transactions = []

          xml_doc.css('BkToCstmrDbtCdtNtfctn > Ntfctn > Ntry').each do |entry_xml_fragment|
            next unless entry_xml_fragment.at_css('CdtDbtInd').text == 'CRDT'

            amount_value = entry_xml_fragment.at_css('Amt').text.to_f
            currency = entry_xml_fragment.at_css('Amt')['Ccy']
            amount = Money.from_amount(amount_value, currency)

            payment_reference_number = entry_xml_fragment.at_css('NtryDtls > TxDtls > RmtInf >' \
              ' Strd > CdtrRefInf > Ref').text
            payment_description = entry_xml_fragment.at_css('NtryDtls > TxDtls > RmtInf' \
              ' > Ustrd').text

            transactions << Transaction.new(amount, payment_reference_number, payment_description)
          end

          transactions
        end

        private

        attr_reader :xml_doc
      end
    end
  end
end
