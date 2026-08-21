# src/main.rb
require 'sketchup.rb'

# โหลดไฟล์ฝั่ง core (อยู่ใน src/core)
require_relative 'core/calculator'
require_relative 'core/tag_measurer'
require_relative 'core/model_collector'
require_relative 'core/price_store'
require_relative 'core/csv_handler'

# โหลดไฟล์ฝั่ง ui (ถอยออกไปโฟลเดอร์ ui ด้านนอก)
require_relative '../ui/dialog_manager'

module MaterialCostByTag
  unless file_loaded?(__FILE__)
    cmd = UI::Command.new('Material Cost') do
      DialogManager.show_dialog
    end
    cmd.tooltip = 'เปิดหน้าต่างคำนวณ Material Cost'
    cmd.status_bar_text = 'เปิดระบบประเมินราคาวัสดุตาม Tag'

    icon_path = File.join(__dir__, '..', 'icons', 'material_cost_icon_32.png')
    cmd.small_icon = icon_path if File.exist?(icon_path)
    cmd.large_icon = icon_path if File.exist?(icon_path)

    menu = UI.menu('Plugins')
    menu.add_item(cmd)

    toolbar = UI::Toolbar.new('Material Cost')
    toolbar.add_item(cmd)
    toolbar.show

    file_loaded(__FILE__)
  end
end