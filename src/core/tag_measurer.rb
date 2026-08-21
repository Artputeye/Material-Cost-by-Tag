# src/core/tag_measurer.rb
module MaterialCostByTag
  class TagMeasurer
    def self.get_tag_measurements(tag_name, model = Sketchup.active_model)
      return {} unless model && model.valid?

      total_max_face_inch2 = 0.0
      total_max_edge_inch  = 0.0
      total_volume_inch3   = 0.0

      # ดึง Group และ ComponentInstance ในระดับ Top Level
      top_entities = model.entities.grep(Sketchup::Group) + model.entities.grep(Sketchup::ComponentInstance)

      top_entities.each do |entity|
        # ตรวจสอบ Tag/Layer
        entity_layer_name = entity.layer.respond_to?(:display_name) ? entity.layer.display_name : entity.layer.name
        next unless entity_layer_name == tag_name

        tr = entity.transformation
        scale_x = Math.sqrt(tr.xaxis.x**2 + tr.xaxis.y**2 + tr.xaxis.z**2)
        scale_y = Math.sqrt(tr.yaxis.x**2 + tr.yaxis.y**2 + tr.yaxis.z**2)
        scale_z = Math.sqrt(tr.zaxis.x**2 + tr.zaxis.y**2 + tr.zaxis.z**2)

        area_scale   = scale_x * scale_y
        volume_scale = scale_x * scale_y * scale_z

        # 1. m³: รวมปริมาตรของแต่ละวัตถุ
        if entity.respond_to?(:volume) && entity.volume > 0
          total_volume_inch3 += entity.volume * volume_scale
        end

        definition = entity.respond_to?(:definition) ? entity.definition : entity.group_definition
        next unless definition

        obj_max_face_inch2 = 0.0
        obj_max_edge_inch  = 0.0

        # ตรวจสอบขนาด Bounding Box ของวัตถุชิ้นนี้ไว้เป็นค่าเริ่มต้นความยาว
        bb = entity.bounds
        obj_max_edge_inch = [bb.width, bb.height, bb.depth].max

        definition.entities.grep(Sketchup::Face).each do |face|
          face_area = face.area * area_scale

          # หา Face ที่กว้าง/ใหญ่ที่สุดของวัตถุชิ้นนี้
          obj_max_face_inch2 = face_area if face_area > obj_max_face_inch2

          # หา Edge ที่ยาวที่สุดของวัตถุชิ้นนี้
          face.edges.each do |edge|
            edge_len = edge.length * [scale_x, scale_y, scale_z].max
            obj_max_edge_inch = edge_len if edge_len > obj_max_edge_inch
          end
        end

        # 2. m²: บวกสะสมพื้นที่ด้านที่กว้างที่สุดของวัตถุแต่ละชิ้น
        total_max_face_inch2 += obj_max_face_inch2

        # 3. m: บวกสะสมความยาวด้านที่ยาวที่สุดของวัตถุแต่ละชิ้น
        total_max_edge_inch += obj_max_edge_inch
      end

      # อัตราแปลงหน่วย
      inch_to_m     = 0.0254
      sq_inch_to_m2 = 0.00064516
      cu_inch_to_m3 = 0.000016387064

      total_length_m   = (total_max_edge_inch * inch_to_m).round(4)
      total_max_face_m2 = (total_max_face_inch2 * sq_inch_to_m2).round(4)
      total_m3         = (total_volume_inch3 * cu_inch_to_m3).round(4)

      {
        'm'   => total_length_m,    # รวมความยาวขอบที่ยาวที่สุดของทุกวัตถุ
        'm2'  => total_max_face_m2, # รวมพื้นที่ด้านที่กว้างที่สุดของทุกวัตถุ
        'm3'  => total_m3           # รวมปริมาตรของทุกวัตถุ
      }
    end
  end
end