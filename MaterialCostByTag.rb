require 'sketchup.rb'
require 'extensions.rb'

module MaterialCostByTag
  ext = SketchupExtension.new('Material Cost by Tag', File.join(__dir__, 'src', 'main.rb'))
  ext.creator     = 'ARTTECH'
  ext.version     = '1.0.0'
  ext.description = 'Calculate Material Cost by Tag'
  Sketchup.register_extension(ext, true)
end