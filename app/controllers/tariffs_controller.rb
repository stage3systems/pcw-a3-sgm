class TariffsController < NestedCommonController

  private
  def model
    Tariff
  end

  def safe_params
    params.require(:tariff).permit(:name, :document,
                                   :validity_start, :validity_end)
  end
end
