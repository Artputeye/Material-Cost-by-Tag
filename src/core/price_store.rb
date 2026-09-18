# price_store.rb
require 'json'

module MaterialCostByTag
  class PriceStore
    DICT_NAME    = 'MaterialCostByTag_Data'.freeze
    KEY_ALL_DATA = 'All_Table_Data'.freeze
    FILE_PATH    = File.join(__dir__, '..', '..', 'data', 'prices.json').freeze

    def self.save_prices(data, model = Sketchup.active_model)
      return false unless model && model.valid?

      sanitized_data = sanitize_data(data)

      dict = model.attribute_dictionary(DICT_NAME, true)
      dict[KEY_ALL_DATA] = JSON.generate(sanitized_data)

      save_to_json_file(sanitized_data)
      true
    rescue => e
      puts "Error saving prices: #{e.message}"
      false
    end

    def self.load_all_prices(model = Sketchup.active_model)
      if model && model.valid?
        dict = model.attribute_dictionary(DICT_NAME, false)
        return JSON.parse(dict[KEY_ALL_DATA]) if dict && dict[KEY_ALL_DATA]
      end
      load_from_json_file
    rescue => e
      puts "Error loading prices: #{e.message}"
      {}
    end

    def self.save_to_json_file(sanitized_data)
      dir = File.dirname(FILE_PATH)
      Dir.mkdir(dir) unless Dir.exist?(dir)
      File.write(FILE_PATH, JSON.pretty_generate(sanitized_data), encoding: 'UTF-8')
    end

    def self.load_from_json_file
      return {} unless File.exist?(FILE_PATH)
      content = File.read(FILE_PATH, encoding: 'UTF-8')
      parsed = JSON.parse(content)
      parsed.is_a?(Hash) ? parsed : {}
    rescue
      {}
    end

    def self.sanitize_data(data)
      return {} unless data.is_a?(Hash)

      {
        'items' => (data['items'] || []).map do |item|
          unit_val = (item['unit'] || item['input']).to_s
          {
            'tag'         => item['tag'].to_s,
            'description' => item['description'].to_s,
            'quantity'    => item['quantity'].to_f,
            'unit'        => unit_val,
            'input'       => unit_val,
            'factor'      => item['factor'].to_f,
            'weightUnit'  => item['weightUnit'].to_f,
            'weightTotal' => item['weightTotal'].to_f,
            'unitCost'    => item['unitCost'].to_f,
            'waste'       => item['waste'].to_f,
            'tax'         => item['tax'].to_f,
            'cost'        => item['cost'].to_f
          }
        end
      }
    end
  end
end