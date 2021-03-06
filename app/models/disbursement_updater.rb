class DisbursementUpdater
  attr_reader :disbursement, :revision

  def initialize(id, user)
    @disbursement = Disbursement.find(id)
    setup_revision
    @revision.user = user
    @ctx = V8::Context.new
  end

  def run(revision_params, all_params)
    @revision.assign_attributes(revision_params)
    @revision.data.merge!(@revision.cargo_type.crystalize) if @revision.cargo_type
    @params = all_params
    update_status
    handle_required_inputs
    cleanup_extra_items
    cleanup_named_services
    reorder_field_keys
    add_new_items
    update_extra_and_named_items
    process_fields
    compute_and_save_revision
  end

  private
  def setup_revision
    if @disbursement.current_revision.number == 0
      @revision = @disbursement.current_revision
      @revision.number = 1
    else
      @revision = @disbursement.next_revision
    end
  end

  def update_status
    status = @params[:disbursement][:status_cd] rescue nil
    return unless status
    @revision.data['status'] = status
    @disbursement.status_cd = status
    @disbursement.save
    @revision.disbursement.reload
  end

  def handle_required_inputs
    @params.keys.select {|k| k.starts_with?("required_input_")}
      .each do |key|
        @revision.data.store(key, @params[key])
      end
  end

  def cleanup_extra_items
    # handle extra itemsa
    @old_extras = @revision.field_keys.select{|k| k.starts_with?("EXTRAITEM") }
    @extras = @params.keys.select {|k| k.starts_with?("value_EXTRAITEM") }
                          .map {|k| k.split('_')[1] }
    # remove keys that do not exist anymore
    (@old_extras-@extras).each {|k| @revision.delete_field(k)}
  end

  def cleanup_named_services
    @old_named_services = @revision.field_keys.select{|k| k.starts_with?("NAMED-SERVICE") }
    @named_services = @params.keys.select {|k| k.starts_with?("value_NAMED-SERVICE") }
                          .map {|k| k.split('_')[1] }
    # remove keys that do not exist anymore
    (@old_named_services-@named_services).each {|k| @revision.delete_field(k)}
  end

  def reorder_field_keys
    @fields = {}
    @revision.field_keys.each do |k|
      @fields[k] = @params["order_#{k}"]
    end
  end

  def add_new_items
    (@extras-@old_extras).each do |k|
      add_item(k)
    end
    (@named_services-@old_named_services).each do |k|
      add_item(k)
    end
  end

  def add_item(k)
    @fields[k] = @params["order_#{k}"]
    @revision.compulsory[k] = "0"
    @revision.descriptions[k] = @params["description_#{k}"]
  end

  def update_extra_and_named_items
    (@extras+@named_services).each {|k| update_tax_applies(k)}
  end

  def update_tax_applies(k)
    taxApplies = (@ctx.eval("("+@params["code_#{k}"]+").taxApplies") ? "true" : "false") rescue "true"
    @revision.codes[k] = "{compute: function(c) {return 0;},taxApplies: #{taxApplies}}"
  end

  def process_fields
    @revision.fields = @fields
    @fields.keys.each do |k|
      field_disabled(k)
      field_overriden(k)
      update_activity_code(k)
      @revision.comments[k] = @params["comment_#{k}"]
    end
  end

  def field_disabled(k)
    d = @params["disabled_#{k}"]
    if d and not @revision.compulsory?(k)
      @revision.disabled[k] = (d == "1" ? "1" : "0")
    end
  end

  def field_overriden(k)
    o = @params["overriden_#{k}"]
    if o and o != ""
      @revision.overriden[k] = o
    else
      @revision.overriden.delete(k)
    end
  end

  def update_activity_code(k)
    if k.start_with? 'AGENCY-FEE'
      @revision.activity_codes[k] = 'AFEE'
    elsif k.start_with? 'EXTRAITEM'
      @revision.activity_codes[k] = 'MISC'
    elsif k.start_with? 'NAMED-SERVICE'
      key = k.split('-')[2] || 'UNKNOWN'
      service = @disbursement.tenant.named_services.find_by(key: key)
      @revision.activity_codes[k] = (service.get_activity_code rescue 'MISC')
    else
      s = @disbursement.terminal.services.find_by(key: k) rescue nil
      s = @disbursement.port.services.find_by(key: k) if s.nil?
      @revision.activity_codes[k] = (s.get_activity_code rescue 'MISC')
    end
  end

  def compute_and_save_revision
    @revision.compute
    DisbursementRevision.hstore_fields.each do |f|
      @revision.send("#{f}_will_change!")
    end
    @revision.save
    @disbursement.current_revision = @revision
    @disbursement.save
  end
end
