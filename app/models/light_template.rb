class LightTemplate
  def initialize(path_elements, ctx)
    path = Rails.root.join(*(['app', 'views']+path_elements))
    @ctx = OpenStruct.new(ctx)
    @template = ERB.new(File.read(path.to_s))
  end

  def render
    @template.result(@ctx.instance_eval { binding })
  end
end
