class RemoveNormacTenant < ActiveRecord::Migration
  def change
    def change
      ActiveRecord::Base.transaction do
        t = Tenant.find_by(name: "normac")
        if t != nil
            Service.where(tenant_id: t.id).destroy_all
            ActivityCode.where(tenant_id: t.id).destroy_all
            CargoType.where(tenant_id: t.id).destroy_all
            Company.where(tenant_id: t.id).destroy_all
            Configuration.where(tenant_id: t.id).destroy_all
            DisbursementRevision.where(tenant_id: t.id).destroy_all
            Disbursement.where(tenant_id: t.id).destroy_all
            Office.where(tenant_id: t.id).destroy_all
            OfficesPort.where(tenant_id: t.id).destroy_all
            PfdaView.where(tenant_id: t.id).destroy_all
            Port.where(tenant_id: t.id).destroy_all
            ServiceUpdate.where(tenant_id: t.id).destroy_all
            Tariff.where(tenant_id: t.id).destroy_all
            Terminal.where(tenant_id: t.id).destroy_all
            User.where(tenant_id: t.id).destroy_all
            Vessel.where(tenant_id: t.id).destroy_all
            Tenant.find_by(id: t.id).delete
        end
    end
  end
end
