class DisbursementsGrid

  def initialize(user, params)
    @tenant = user.tenant
    @port_ids = user.authorized_ports.pluck :id
    joins_and_includes(params)
  end

  def relation
    Disbursement.where(tenant_id: @tenant.id, port_id: @port_ids)
  end

  def options
    {
      joins: @grid_joins,
      include: @grid_includes,
      order: 'disbursement_revisions.updated_at',
      order_direction: 'desc',
      custom_order: {
        'disbursements.current_revision_id' => 'current_revision.updated_at',
        'disbursements.port_id' => 'port.name',
        'disbursements.company_id' => 'company.name'
      },
      per_page: 10
    }
  end

  private
  def joins_and_includes(params)
    joins = []
    includes = [:port, :current_revision]
    ((params["grid"]["f"]["companies.name"] rescue false) ? joins : includes) << :company
    ((params["grid"]["f"]["vessels.name"] rescue false) ? joins : includes) << :vessel
    @grid_joins = joins
    @grid_includes = includes
  end
end
