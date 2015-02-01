require "thor"

class Sgviz::CLI < Thor
  class_option :profile,
    desc:    "Load credentials by profile name from shared credentials file (~/.aws/credentials).",
    aliases: [:p]

  class_option :access_key_id,
    desc:    "AWS access key id.",
    aliases: [:k]

  class_option :secret_access_key,
    desc:    "AWS secret access key.",
    aliases: [:s]

  class_option :region,
    desc:    "AWS region.",
    aliases: [:r]

  class_option :format,
    desc:    "Output file format",
    aliases: [:f],
    default: "png"

  class_option :output_path,
    desc:    "Output file path.",
    aliases: [:output, :o]

  class_option :vpc_ids,
    desc:    "AWS VPC IDs (If specified, graph will include security groups in the VPCs).",
    aliases: [:vpcs, :vpc, :v],
    type:    :array

  class_option :inbound_only,
    desc:    "If specified, graph will exclude outbound rules.",
    type:    :boolean,
    default: false

  class_option :global_label,
    desc:    "Label of the diagram.",
    default: ""

  class_option :security_group_label,
    desc:    "Label of each security groups.",
    default: %q("#{security_group.group_name}\n(#{security_group.id})")

  class_option :fontname,
    desc:    "Font name used on labels.",
    default: "Futura"

  class_option :fontsize,
    desc:    "Font size used on labels.",
    type:    :numeric,
    default: 15

  desc "version", "Puts sgviz version."
  def version
    puts Sgviz::VERSION
  end

  desc "open", "Generate and open a graph file."
  method_option :output_path, required: true
  def open
    unless system "which open > /dev/null"
      abort "`open` command not found."
    end

    generate
    system "open #{options.output_path}.#{options.format}"
  end

  desc "generate", "Generate a graph file."
  method_option :output_path, required: true
  def generate
    generator.generate
    puts "Graph generated to `#{options.output_path}.#{options.format}`."
  end

  private

  def generator
    @generator ||= Sgviz::Generator.new :G, :digraph, options
  end
end
