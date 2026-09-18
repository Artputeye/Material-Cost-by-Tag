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
          'Tag', 'Description', 'Quantity', 'Unit', 'Factor', 
          'Weight/Unit', 'Weight Total (kg)', 
          'Unit Cost', 'Waste%', 'Tax%', 'Cost'
        ].join(',')

        items.each do |item|
          unit_val = item['unit'] || item['input']
          row = [
            escape_csv(item['tag']),
            escape_csv(item['description']),
            item['quantity'].to_f,
            escape_csv(unit_val),
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

      model = Sketchup.active_model
      existing_data = PriceStore.load_all_prices(model)
      current_items = existing_data['items'] || []

      updated_count = 0
      added_count = 0

      # อ่านไฟล์และบังคับแปลง Encoding ภาษาไทยเป็น UTF-8 สมบูรณ์
      content = read_file_utf8(file_path)

      CSV.parse(content, headers: true, skip_blanks: true, liberal_parsing: true) do |raw_row|
        next if raw_row.to_h.values.all?(&:nil?)

        row = raw_row.to_h.transform_keys { |k| k.to_s.strip.downcase }

        csv_tag  = normalize_str(row['tag'])
        csv_desc = normalize_str(row['description'])

        next if csv_tag.empty? && csv_desc.empty?

        factor_val   = get_row_value(row, ['factor'])
        weight_u_val = get_row_value(row, ['weight/unit', 'weight unit', 'weight_unit', 'weight'])
        unit_cost_val= get_row_value(row, ['unit cost', 'unitcost', 'cost/unit', 'price'])
        waste_val    = get_row_value(row, ['waste%', 'waste', 'waste_percent'])
        tax_val      = get_row_value(row, ['tax%', 'tax', 'tax_percent'])

        matched_item = current_items.find do |item|
          item_tag  = normalize_str(item['tag'])
          item_desc = normalize_str(item['description'])

          item_tag.downcase == csv_tag.downcase && item_desc.downcase == csv_desc.downcase
        end

        if matched_item
          matched_item['factor']     = factor_val unless factor_val.nil?
          matched_item['weightUnit'] = weight_u_val unless weight_u_val.nil?
          matched_item['unitCost']   = unit_cost_val unless unit_cost_val.nil?
          matched_item['waste']      = waste_val unless waste_val.nil?
          matched_item['tax']        = tax_val unless tax_val.nil?

          qty      = matched_item['quantity'].to_f
          factor   = matched_item['factor'].to_f
          weight_u = matched_item['weightUnit'].to_f
          u_cost   = matched_item['unitCost'].to_f
          waste    = matched_item['waste'].to_f
          tax      = matched_item['tax'].to_f

          matched_item['weightTotal'] = (qty * factor * weight_u).round(2)
          base_cost = qty * factor * u_cost
          matched_item['cost'] = (base_cost * (1 + waste / 100.0) * (1 + tax / 100.0)).round(2)

          updated_count += 1
        else
          unit_val = get_row_text(row, ['unit', 'input']) || 'm2'
          qty      = get_row_value(row, ['quantity', 'qty']) || 0.0
          factor   = factor_val || 1.0
          weight_u = weight_u_val || 0.0
          u_cost   = unit_cost_val || 0.0
          waste    = waste_val || 0.0
          tax      = tax_val || 0.0

          weight_total = (qty * factor * weight_u).round(2)
          base_cost    = qty * factor * u_cost
          cost         = (base_cost * (1 + waste / 100.0) * (1 + tax / 100.0)).round(2)

          new_item = {
            'tag'         => csv_tag,
            'description' => csv_desc,
            'quantity'    => qty,
            'unit'        => unit_val,
            'input'       => unit_val,
            'factor'      => factor,
            'weightUnit'  => weight_u,
            'weightTotal' => weight_total,
            'unitCost'    => u_cost,
            'waste'       => waste,
            'tax'         => tax,
            'cost'        => cost
          }

          current_items << new_item
          added_count += 1
        end
      end

      updated_payload = { 'items' => current_items }
      PriceStore.save_prices(updated_payload, model)

      if dialog && dialog.is_a?(UI::HtmlDialog)
        json_data = JSON.generate(current_items)
        js_code = <<~JS
          if (typeof applyImportedCsvData === 'function') {
            applyImportedCsvData(#{json_data});
          } else if (typeof renderTable === 'function') {
            renderTable(#{json_data});
          } else if (typeof updateUI === 'function') {
            updateUI(#{json_data});
          } else {
            location.reload();
          }
        JS
        dialog.execute_script(js_code)
      end

      UI.messagebox("Import CSV เรียบร้อย!\n- อัปเดตรายการเดิม: #{updated_count} รายการ\n- เพิ่มรายการใหม่: #{added_count} รายการ")
      current_items
    rescue => e
      UI.messagebox("เกิดข้อผิดพลาดในการ Import CSV: #{e.message}")
      nil
    end

    private

    # อ่านไฟล์รองรับทั้ง UTF-8 และ Windows-874 / TIS-620 ภาษาไทย
    def self.read_file_utf8(file_path)
      raw = File.read(file_path, mode: 'rb')
      
      # ตัด BOM UTF-8 ถ้ามี
      raw = raw.byteslice(3..-1) if raw.start_with?("\xEF\xBB\xBF".b)

      # ตรวจสอบและแปลง Encoding
      if raw.valid_encoding? && raw.force_encoding('UTF-8').valid_encoding?
        raw.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      else
        # หากไม่ใช่ UTF-8 ให้ถอดรหัสจาก Windows-874 (ภาษาไทยใน Excel Windows)
        raw.force_encoding('Windows-874').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      end
    end

    def self.normalize_str(text)
      text.to_s.gsub("\u00A0", ' ').strip
    end

    def self.get_row_value(row, possible_keys)
      possible_keys.each do |k|
        if row.key?(k) && !row[k].nil? && row[k].to_s.strip != ''
          return row[k].to_s.gsub(',', '').to_f
        end
      end
      nil
    end

    def self.get_row_text(row, possible_keys)
      possible_keys.each do |k|
        if row.key?(k) && !row[k].nil? && row[k].to_s.strip != ''
          return row[k].to_s.strip
        end
      end
      nil
    end
  end
end