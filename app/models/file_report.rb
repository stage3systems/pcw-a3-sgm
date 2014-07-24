module FileReport
  def set_context(d)
    @document = d
    @disbursement = d.disbursement
    @revision = d.revision
  end
end
