# csv_handler.rb
require 'csv'
require 'json'
require_relative 'price_store'

module MaterialCostByTag
  class CsvExporter
    def self.export_to_csv(data)
      file_path = UI.savepanel("Export Material Cost CSV", "", "material_cost.csv")
      return unless file_path

      file_path += ".csv" unless file_path.downcase.end_with?('.csv')
      items = data['items'] || []

      File.open(file_path, "w:UTF-8") do |file|
        file.write("\xEF\xBB\xBF") # UTF-8 BOM
        file.puts [
          'Tag', 'Description', 'Input', 'Factor', 
          'Weight/Unit', 'Weight Total (kg)', 
          'Unit Cost', 'Waste%', 'Tax%', 'Cost'
        ].join(',')

        items.each do |item|
          row = [
            escape_csv(item['tag']),
            escape_csv(item['description']),
            escape_csv(item['input']),
            item['factor'].to_f,
            item['weightUnit'].to_f,
            item['weightTotal'].to_f,
            item['unitCost'].to_f,
            item['waste'].to_f,
            item['tax'].to_f,
            item['cost'].to_f
          ]
          file.puts row.join(',')
        end
      end

      UI.messagebox("Export CSV สำเร็จเรียบร้อย!")
    rescue => e
      UI.messagebox("เกิดข้อผิดพลาดในการ Export CSV: #{e.message}")
    end

    def self.escape_csv(text)
      val = text.to_s
      if val.include?(',') || val.include?('"') || val.include?("\n")
        "\"#{val.gsub('"', '""')}\""
      else
        val
      end
    end
  end

  class CsvImporter
    def self.import_from_csv(dialog = nil)
      file_path = UI.openpanel("Import Material Cost CSV", "", "CSV Files|*.csv;||")
      return nil unless file_path && File.exist?(file_path)

      # ดึงข้อมูลปัจจุบันในเครื่อง/โมเดลมาตั้งต้น
      model = Sketchup.active_model
      existing_data = PriceStore.load_all_prices(model)
      current_items = existing_data['items'] || []

      updated_count = 0
      added_count = 0

      CSV.foreach(file_path, headers: true, encoding: 'bom|utf-8') do |row|
        next if row.to_h.values.all?(&:nil?)

        csv_tag  = (row['Tag'] || '').strip
        csv_desc = (row['Description'] || '').strip

        csv_item_data = {
          'tag'         => csv_tag,
          'description' => csv_desc,
          'input'       => row['Input'] || 'm2',
          'factor'      => (row['Factor'] || 1.0).to_f,
          'weightUnit'  => (row['Weight/Unit'] || row['Weight Unit'] || 0.0).to_f,
          'unitCost'    => (row['Unit Cost'] || 0.0).to_f,
          'waste'       => (row['Waste%'] || 0.0).to_f,
          'tax'         => (row['Tax%'] || 0.0).to_f
        }

        # ตรวจสอบว่า Tag และ Description ตรงกับที่มีอยู่ในเครื่องหรือไม่
        matched_item = current_items.find do |item|
          item['tag'].to_s.strip.downcase == csv_tag.downcase &&
          item['description'].to_s.strip.downcase == csv_desc.downcase
        end

        if matched_item
          # ถ้าตรงกัน ดึงค่าจาก CSV มาทับรายการเดิม
          matched_item['input']      = csv_item_data['input']
          matched_item['factor']     = csv_item_data['factor']
          matched_item['weightUnit'] = csv_item_data['weightUnit']
          matched_item['unitCost']   = csv_item_data['unitCost']
          matched_item['waste']      = csv_item_data['waste']
          matched_item['tax']        = csv_item_data['tax']
          updated_count += 1
        else
          # ถ้าไม่ตรง เพิ่มเป็นรายการใหม่
          current_items << csv_item_data
          added_count += 1
        end
      end

      # บันทึกข้อมูลที่แมตช์แล้วลง PriceStore
      updated_payload = { 'items' => current_items }
      PriceStore.save_prices(updated_payload, model)

      # แสดงผลใน UI ทันที
      if dialog && dialog.is_a?(UI::HtmlDialog)
        js_code = "applyImportedCsvData(#{JSON.generate(current_items)});"
        dialog.execute_script(js_code)
      end

      UI.messagebox("Import CSV เรียบร้อย!\n- อัปเดตรายการเดิม: #{updated_count} รายการ\n- เพิ่มรายการใหม่: #{added_count} รายการ")
      current_items
    rescue => e
      UI.messagebox("เกิดข้อผิดพลาดในการ Import CSV: #{e.message}")
      nil
    end
  end
end