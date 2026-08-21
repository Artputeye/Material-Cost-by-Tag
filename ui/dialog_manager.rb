# ui/dialog_manager.rb
module MaterialCostByTag
  class DialogManager
    @dialog = nil

    def self.show_dialog
      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      options = {
        dialog_title: 'Material Cost by Tag',
        preferences_key: 'MaterialCostByTag_Dialog',
        scrollable: true,
        resizable: true,
        width: 1000,
        height: 650,
        min_width: 800,
        min_height: 500
      }

      @dialog = UI::HtmlDialog.new(options)
      
      html_path = File.join(__dir__, 'index.html')
      @dialog.set_file(html_path)

      attach_callbacks
      @dialog.show
    end

    def self.attach_callbacks
      return unless @dialog

      # Callback เมื่อ JS ร้องขอรายการ Tags
      @dialog.add_action_callback('get_tags') do |action_context|
        tags = ModelCollector.get_all_tags
        js_code = "populateTags(#{tags.to_json});"
        @dialog.execute_script(js_code)
      end

      # Callback เมื่อ JS ร้องขอข้อมูลที่เคยบันทึกไว้
      @dialog.add_action_callback('get_all_saved_data') do |action_context|
        saved_data = PriceStore.load_all_prices if defined?(PriceStore)
        saved_data ||= {}
        js_code = "loadAllSavedRows(#{saved_data.to_json});"
        @dialog.execute_script(js_code)
      end

      # Callback คำนวณมิติพื้นที่
      @dialog.add_action_callback('get_tag_measurements') do |action_context, tag_name|
        measurements = TagMeasurer.get_tag_measurements(tag_name) if defined?(TagMeasurer)
        measurements ||= {}
        js_code = "updateTagMeasurements(#{tag_name.to_json}, #{measurements.to_json});"
        @dialog.execute_script(js_code)
      end

      # Callback บันทึกข้อมูล
      @dialog.add_action_callback('save_tag_cost_data') do |action_context, data|
        PriceStore.save_prices(data) if defined?(PriceStore)
        UI.messagebox('บันทึกข้อมูลเรียบร้อยแล้ว')
      end

      # Callback ส่งออก CSV
      @dialog.add_action_callback('export_csv_data') do |action_context, data|
        CsvExporter.export_to_csv(data) if defined?(CsvExporter)
      end

      # Callback นำเข้า CSV
      @dialog.add_action_callback('import_csv_data') do |action_context|
        if defined?(CsvImporter)
          imported_items = CsvImporter.import_from_csv
          if imported_items
            js_code = "applyImportedCsvData(#{imported_items.to_json});"
            @dialog.execute_script(js_code)
          end
        end
      end
    end
  end
end