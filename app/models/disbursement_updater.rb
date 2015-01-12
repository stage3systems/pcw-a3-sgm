class DisbursementUpdater
  attr_reader :disbursement

  def initialize(id, user)
    @disbursement = Disbursement.find(id)
    setup_revision
    @revision.user = user
    @ctx = V8::Context.new
  end

  def run(revision_params, all_params)
    @revision.assign_attributes(revision_params)
    @params = all_params
    update_status
    handle_agency_fees
    cleanup_extra_items
    reorder_and_reindex_field_keys
    add_new_items
    process_fields
    compute_and_save_revision
  end

  private
  def update_status
    status = @params[:disbursement][:status_cd] rescue nil
    return unless status
    @disbursement.status_cd = status
    @disbursement.save
    @revision.disbursement.reload
  end

  def fetch_agency_fees
    @fees = []
    return unless @disbursement.company
    return unless @revision.eta
    @fees = AosAgencyFees.find({
      companyId: @disbursement.company.remote_id,
      portId: @disbursement.port.remote_id,
      dateEffectiveEnd: @revision.eta,
      dateExpiresStart: @revision.eta
    })
  end

  def backup_local_agency_fees
    @fee_keys = @revision.fields.keys.select {|k| k.start_with? 'AGENCY-FEE-'}
    @fees_by_desc = @fee_keys.inject({}) do |acc, k|
      acc[@revision.descriptions[k]] = {
        key: k,
        comment: @revision.comments[k],
        overriden: @revision.overriden[k],
        disabled: @revision.disabled[k]
      }
      acc
    end
  end

  def add_fee(fee, key, index)
    @revision.fields[key] = index
    @revision.codes[key] = fee[:code]
    @revision.descriptions[key] = fee[:description]
    @revision.hints[key] = fee[:hint]
    @revision.compulsory[key] = false
  end

  def restore_fee_settings(key, fee)
    migrated = @fees_by_desc[fee[:description]]
    if migrated
      @revision.comments[key] = migrated[:comment]
      unless migrated[:overriden].nil?
        @revision.overriden[key] = migrated[:overriden]
      end
      @revision.disabled[key] = migrated[:disabled] ? "1" : "0"
    end
  end

  def merge_agency_fees
    index = @revision.fields.values.max+1 rescue 1
    @fees.each do |fee|
      key = "AGENCY-FEE-#{fee[:id]}"
      add_fee(fee, key, index)
      restore_fee_settings(key, fee)
      index += 1
    end
  end

  def cleanup_agency_fees
    @fee_keys.each {|k| @revision.delete_field(k) }
  end

  def handle_agency_fees
    fetch_agency_fees
    backup_local_agency_fees
    cleanup_agency_fees
    merge_agency_fees
  end

  def setup_revision
    if @disbursement.current_revision.number == 0
      @revision = @disbursement.current_revision
      @revision.number = 1
    else
      @revision = @disbursement.next_revision
    end
  end

  def cleanup_extra_items
    # handle extra items
    @old_extras = @revision.field_keys.select{|k| k.starts_with?("EXTRAITEM") }
    @extras = @params.keys.select {|k| k.starts_with?("value_EXTRAITEM") }
                          .map {|k| k.split('_')[1] }
    # remove keys that do not exist anymore
    (@old_extras-@extras).each {|k| @revision.delete_field(k)}
  end

  def group_charges_by_type
    @charges = {}
    @extraitems = {}
    @fees = {}
    @revision.field_keys.each_with_index do |k,i|
      if k.start_with? 'EXTRAITEM'
        @extraitems[k] = i
      elsif k.start_with? 'AGENCY-FEE-'
        @fees[k] = i
      else
        @charges[k] = i
      end
    end
  end

  def reorder_and_reindex_field_keys
    group_charges_by_type
    @fields = {}
    i = 0
    @charges.each {|k,j| @fields[k] = i; i += 1 }
    @fees.each {|k,j| @fields[k] = i; i += 1 }
    @extraitems.each {|k,j| @fields[k] = i; i += 1 }
  end

  def add_new_items
    index = @fields.values.max+1 rescue 1
    (@extras-@old_extras).each do |k|
      add_item(index, k)
      index += 1
    end
  end

  def add_item(index, k)
    @fields[k] = index
    @revision.compulsory[k] = "0"
    taxApplies = (ctx.eval("("+@params["code_#{k}"]+").taxApplies") ? "true" : "false") rescue "true"
    @revision.codes[k] = "{compute: function(c) {return 0;},taxApplies: #{taxApplies}}"
    @revision.descriptions[k] = @params["description_#{k}"]
  end

  def process_fields
    @revision.fields = @fields
    @fields.keys.each do |k|
      field_disabled(k)
      field_overriden(k)
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
