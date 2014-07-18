module FileReport
  def shortcuts
    @total = number_to_currency @revision.data['total'], unit: ""
    @total_with_tax = number_to_currency @revision.data['total_with_tax'],
                                         unit: ""
    @currency_code = @revision.data["currency_code"]
  end
end
