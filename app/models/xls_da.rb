Spreadsheet.client_encoding = 'UTF-8'

class XlsDA < Spreadsheet::Workbook

  include FileReport

  def initialize(document)
    super()
    set_context(document)

    create_formats

    @sheet = create_worksheet
    @sheet.name = "Proforma DA"
    (0..3).each {|i| @sheet.column(i).width = 40}

    r = add_title(0)
    r = add_subtitle(r)
    r = add_vessel_info(r)
    r = add_services(r)
    add_total(r)
  end

  def create_formats
    @head_left_fmt = Spreadsheet::Format.new weight: :bold,
                                             horizontal_align: :left
    @head_right_fmt = Spreadsheet::Format.new weight: :bold,
                                              horizontal_align: :right
    @left_fmt = Spreadsheet::Format.new horizontal_align: :left
    @right_fmt = Spreadsheet::Format.new horizontal_align: :right
    @total_fmt = Spreadsheet::Format.new weight: :bold, size: 16,
                                         horizontal_align: :right
    @title_fmt = Spreadsheet::Format.new weight: :bold, size: 16,
                                         color: :red,
                                         horizontal_align: :center
    @subtitle_fmt = Spreadsheet::Format.new weight: :bold, size: 12,
                                            horizontal_align: :center
  end

  def add_title(r)
    @sheet.row(r).push ProformaDA::Application.config.tenant_full_name.upcase
    @sheet.row(r).default_format = @title_fmt
    @sheet.row(r).height = 20
    @sheet.merge_cells(r, 0, r, 3)
    r+2
  end

  def add_subtitle(r)
    @sheet.row(r).push "ESTIMATED DISBURSEMENTS FOR #{@disbursement.port.name.upcase}"
    @sheet.row(r).default_format = @subtitle_fmt
    @sheet.row(r).height = 18
    @sheet.merge_cells(r, 0, r, 3)
    r+2
  end

  def vessel_info_row(r, title, data)
    @sheet.row(r).push title, data
    @sheet.row(r).set_format(0, @head_left_fmt)
    r+1
  end

  def add_vessel_info(r)
    [
      ["Vessel", @revision.data['vessel_name']],
      ["Voyage Number", @revision.voyage_number],
      ["ETA", "#{I18n.l(@revision.eta) rescue "N/A"}"]
    ].each do |n,v|
      r = vessel_info_row(r, n, v)
    end
    ["grt", "nrt", "dwt", "loa"].each do |n|
      r = vessel_info_row(r, n, @revision.data["vessel_#{n}"])
    end
    r+1
  end

  def add_service_header(r)
    @sheet.row(r).push "Item",
                       "Comment",
                       "Amount (#{@currency_code})"
    @sheet.row(r).push "Amount (#{@currency_code}) Including Taxes" unless @revision.tax_exempt?
    @sheet.row(r).default_format = @head_right_fmt
    (0..1).each {|i| @sheet.row(r).set_format(i, @head_left_fmt) }
    r+1
  end

  def get_service_row(k)
    cols = [@document.description_for(k),
            @document.comment_for(k),
            @document.value_for(k)]
    cols << @document.value_with_tax_for(k) unless @revision.tax_exempt?
    cols
  end

  def add_services(r)
    # setup services
    r = add_service_header(r)
    @revision.field_keys.each_with_index do |k, i|
      row = @sheet.row(r+i)
      row.push *get_service_row(k)
      row.default_format = @right_fmt
      (0..1).each {|c| row.set_format(c, @left_fmt) }
    end
    r+@revision.field_keys.length
  end

  def add_total(r)
    @sheet.row(r).push "ESTIMATED AMOUNT",
                       "",
                       @document.total
    unless @revision.tax_exempt?
      @sheet.row(r).push @document.total_with_tax
    end
    @sheet.row(r).default_format = @total_fmt
    @sheet.row(r).height = 20
    @sheet.merge_cells(r, 0, r, @revision.tax_exempt? ? 1 : 2)
    r
  end

end
