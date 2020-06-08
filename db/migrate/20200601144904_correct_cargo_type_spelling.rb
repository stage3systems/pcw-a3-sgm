class CorrectCargoTypeSpelling < ActiveRecord::Migration
    def up
        CargoType.reset_column_information
        begin
            CargoType.all.each do |ct|
            if ct.maintype == 'FLOURSPAR'
                ct.maintype = 'FLUORSPAR'
            end
            if ct.subtype == 'FLOURSPAR'
                ct.subtype = 'FLUORSPAR'
            end
            if ct.subsubtype == 'FLOURSPAR'
                ct.subsubtype = 'FLUORSPAR'
            end
            if ct.subsubsubtype == 'FLOURSPAR'
                ct.subsubsubtype = 'FLUORSPAR'
            end
            ct.save!
            end
        end
    end
end
