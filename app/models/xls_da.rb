Spreadsheet.client_encoding = 'UTF-8'

class XlsDA < Spreadsheet::Workbook
  include FileReport
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  def initialize(disbursement, revision)
    super()
    @disbursement = disbursement
    @revision = revision

    shortcuts
    create_formats

    @sheet = create_worksheet
    @sheet.name = "Proforma DA"
    (0..3).each {|i| @sheet.column(i).width = 40}

    r = 0

    r = add_title(r)
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

  def add_vessel_info(r)
    @sheet.row(r).push "Vessel", @disbursement.vessel_name
    @sheet.row(r).set_format(0, @head_left_fmt)
    r += 1
    unless @revision.voyage_number.blank?
      @sheet.row(r).push "Voyage Number", @revision.voyage_number
      @sheet.row(r).set_format(0, @head_left_fmt)
      r += 1
    end
    @sheet.row(r).push "ETA", "#{I18n.l(@revision.eta) rescue "N/A"}"
    @sheet.row(r).set_format(0, @head_left_fmt)
    r += 1
    ["grt", "nrt", "dwt", "loa"].each do |n|
      @sheet.row(r).push n.upcase, @revision.data["vessel_#{n}"]
      @sheet.row(r).set_format(0, @head_left_fmt)
      r += 1
    end
    r+1
  end

  def add_services(r)
    # setup services
    @sheet.row(r).push "Item",
                       "Comment",
                       "Amount (#{@currency_code})"
    @sheet.row(r).push "Amount (#{@currency_code}) Including Taxes" unless @revision.tax_exempt?
    @sheet.row(r).default_format = @head_right_fmt
    (0..1).each {|i| @sheet.row(r).set_format(i, @head_left_fmt) }
    r += 1
    @revision.field_keys.each_with_index do |k, i|
      @sheet.row(r+i).push @revision.descriptions[k],
                           @revision.comments[k],
                           nan_to_zero(@revision.values[k])
      unless @revision.tax_exempt?
        @sheet.row(r+i).push nan_to_zero(@revision.values_with_tax[k])
      end
      @sheet.row(r+i).default_format = @right_fmt
      (0..1).each {|c| @sheet.row(r+i).set_format(c, @left_fmt) }
    end
    r+@revision.field_keys.length
  end

  def add_total(r)
    @sheet.row(r).push "ESTIMATED AMOUNT",
                       "",
                       "#{number_to_currency @total, unit: ""}"
    unless @revision.tax_exempt?
      @sheet.row(r).push "#{number_to_currency @total_with_tax, unit: ""}"
    end
    @sheet.row(r).default_format = @total_fmt
    @sheet.row(r).height = 20
    @sheet.merge_cells(r, 0, r, @revision.tax_exempt? ? 1 : 2)
    r
  end


end
