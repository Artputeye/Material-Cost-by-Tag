# src/core/calculator.rb
module MaterialCostByTag
  class Calculator
    # ค่าคงที่สำหรับการแปลงหน่วยจาก SketchUp Internal Units (Inches)
    INCH_TO_M      = 0.0254
    SQINCH_TO_M2   = 0.00064516
    CUINCH_TO_M3   = 0.000016387064

    INCH_TO_FT     = 1.0 / 12.0
    SQINCH_TO_FT2  = 1.0 / 144.0
    CUINCH_TO_FT3  = 1.0 / 1728.0
    CUINCH_TO_YD3  = 1.0 / 46656.0

    # แปลงค่าน้ำหนัก / ปริมาณเบื้องต้น
    def self.convert_quantity(raw_val, input_unit)
      val = raw_val.to_f
      case input_unit.to_s.downcase
      when 'm'     then val * INCH_TO_M
      when 'm2'    then val * SQINCH_TO_M2
      when 'm3'    then val * CUINCH_TO_M3
      when 'ft'    then val * INCH_TO_FT
      when 'ft2'   then val * SQINCH_TO_FT2
      when 'ft3'   then val * CUINCH_TO_FT3
      when 'yd3'   then val * CUINCH_TO_YD3
      else val
      end
    end

    # คำนวณราคารวมของรายการ (ปริมาณ x ราคาต่อหน่วย x Factor x Waste% x Tax%)
    def self.calculate_item_cost(quantity, unit_cost, factor, waste_pct, tax_pct)
      q = quantity.to_f
      c = unit_cost.to_f
      f = factor.to_f.zero? ? 1.0 : factor.to_f
      w = waste_pct.to_f / 100.0
      t = tax_pct.to_f / 100.0

      base_cost = q * (c * f)
      cost_with_waste = base_cost * (1.0 + w)
      total_cost = cost_with_waste * (1.0 + t)

      total_cost.round(2)
    end
  end
end