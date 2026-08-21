# src/core/model_collector.rb
module MaterialCostByTag
  class ModelCollector
    # ดึงรายชื่อ Tag ทั้งหมดใน Active Model
    def self.get_all_tags(model = Sketchup.active_model)
      return [] unless model && model.layers

      tags = model.layers.map do |layer|
        name = layer.respond_to?(:display_name) ? layer.display_name : layer.name
        name.nil? || name.strip.empty? ? 'Untagged' : name
      end
      tags.uniq.sort
    end

    # ไฮไลต์เลือกวัตถุใน SketchUp ตาม Tag
    def self.highlight_tag(tag_name, model = Sketchup.active_model)
      return unless model && model.selection

      selection = model.selection
      selection.clear

      target_entities = []
      model.entities.grep(Sketchup::Group).concat(model.entities.grep(Sketchup::ComponentInstance)).each do |entity|
        layer_name = entity.layer.respond_to?(:display_name) ? entity.layer.display_name : entity.layer.name
        target_entities << entity if layer_name == tag_name
      end

      selection.add(target_entities) unless target_entities.empty?
    end
  end
end