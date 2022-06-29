class AddTenantToResources < ActiveRecord::Migration
  def change
    [:activity_codes, :cargo_types, :companies,
     :configurations, :disbursement_revisions,
     :disbursements, :offices, :offices_ports,
     :pfda_views, :ports, :services, :service_updates,
     :tariffs, :terminals, :users, :vessels].each do |t|
      add_column t, :tenant_id, :integer
     end
  end
end
