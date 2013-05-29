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

  def mockup_context
    <<CTX
    var ctx = {
      vessel: {
        nrt: #{Random.rand(100000.0).round(2)},
        grt: #{Random.rand(100000.0).round(2)},
        dwt: #{Random.rand(100000.0).round(2)},
        loa: #{Random.rand(300.0).round(1)}
      },
      estimate: {
        eta: new Date(#{"\""}#{DateTime.now}#{"\""}),
        cargo_qty: #{Random.rand(50000.0).round(2)},
        tugs_in: #{Random.rand(10)},
        tugs_out: #{Random.rand(10)},
        loadtime: #{Random.rand(100)},
        days_alongside: #{Random.rand(3)}
      },
      cargo_type: {
        type: "",
        subtype: "",
        subsubtype: "",
        subsubsubtype: ""
      }
    };
CTX
  end

  def code_checks
    ctx = V8::Context.new
    ctx.eval(mockup_context)
    begin
      ctx.eval("var c = #{self.code};")
    rescue Exception => e
      errors.add(:code, "Syntax Error: #{e.message}")
      return
    end
    begin
      ctx.eval("c.compute(ctx)")
    rescue Exception => e
      errors.add(:code, "Runtime Error: #{e.message}")
    end
  end
end
