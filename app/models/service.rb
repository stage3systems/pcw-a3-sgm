class Service < ActiveRecord::Base
  include RankedModel
  attr_accessor :changelog
  attr_accessible :user_id, :code, :item, :key,
                  :port_id, :row_order, :terminal_id, :document, :compulsory
  validate :code_checks
  belongs_to :port
  belongs_to :terminal
  belongs_to :user
  has_many :service_updates
  mount_uploader :document, TariffUploader
  ranks :row_order, :with_same => [:port_id, :terminal_id]

  def code_checks
    ctx = V8::Context.new
    begin
      ctx.eval("var c = #{self.code};")
    rescue Exception => e
      errors.add(:code, "Syntax Error: #{e.message}")
      return
    end
    begin
      ctx.eval("c.compute({})")
    rescue Exception => e
      errors.add(:code, "Runtime Error: #{e.message}")
    end
  end
end
