namespace :monson do
  namespace :import do
    desc "Import raw CSV cargo types"
    task :cargo_types => :environment do
      file = ENV['file'] || 'cargo_types.csv'
      if not File::exists? file
        puts "Couln't open #{file}"
      else
        require 'csv'
        CargoType.delete_all
        CSV.read(file).each do |r|
          next if r[0] == "id"
          ct = CargoType.new({
            remote_id: r[0],
            maintype: r[1],
            subtype: r[2],
            subsubtype: r[3],
            subsubsubtype: r[4]
          })
          ct.save
        end
        puts "#{CargoType.count} cargo types imported"
      end
    end
  end
end
