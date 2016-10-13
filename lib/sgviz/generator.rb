require "gviz"
require "aws-sdk-resources"

class Sgviz::Generator < Gviz
  def initialize name = :G, type = :digraph, options = {}
    @options = options
    super(name, type)
  end

  def subgraph(name=:"cluster#{subgraphs.size}", &blk)
    self.class.new(name, :subgraph, options).tap do |graph|
      subgraphs << graph
      graph.instance_eval &blk
    end
  end

  def generate
    global(
      layout:    "dot",
      label:     options.global_label,
      labelloc:  "b",
      fontsize:  options.fontsize,
      fontname:  options.fontname,
      fontcolor: "#54523F",
      margin:    20,
    )

    nodes(
      fontsize: options.fontsize,
      fontname: options.fontname,
    )

    vpc_security_groups.each do |vpc_id, security_groups|
      security_groups.each do |security_group|
        subgraph :clusterAWS do
          global(
            label:     aws_configuration[:region],
            labelloc:  "b",
            style:     "rounded",
            color:     "#999999",
            fontsize:  options.fontsize,
            fontname:  options.fontname,
            fontcolor: "#54523F",
            margin:    20,
          )

          node :aws,
            label:       "",
            image:       "#{__dir__}/images/aws.png",
            peripheries: 0,
            fixedsize:   true,
            imagescale:  true,
            shape:       "circle",
            width:       1.5

          subgraph :"cluster#{vpc_id ? vpc_id[4..-1] : 'ec2_classic'}" do
            global(
              label:     vpc_id ? vpc_id : 'EC2-Classic',
              labelloc:  "b",
              style:     "rounded",
              color:     "#999999",
              fontsize:  options.fontsize,
              fontname:  options.fontname,
              fontcolor: "#54523F",
              margin:    20,
            )

            node vpc_id.to_id,
              label:       "",
              image:       "#{__dir__}/images/vpc.png",
              peripheries: 0,
              fixedsize:   true,
              imagescale:  true,
              shape:       "circle",
              width:       1.5

            name_tag = security_group.tags.find {|tag| tag.key == "Name"}

            node security_group.id.to_id,
              shape:     "note",
              style:     "filled",
              color:     "#EDEAD2",
              fillcolor: "#EDEAD2",
              label:     "#{name_tag ? name_tag.value : security_group.group_name}\n(#{security_group.id})",
              fontsize:  options.fontsize,
              fontname:  options.fontname,
              fontcolor: "#54523F",
              margin:    0.2
          end
        end

        security_group.ip_permissions.each do |ip_permission|
          to = security_group.id.to_id

          ip_permission.ip_ranges.each do |ip_range|
            from = ip_range.cidr_ip.to_id

            node from,
              shape:     "ellipse",
              style:     "filled",
              color:     "#E7FAFF",
              fillcolor: "#E7FAFF",
              label:     ip_range.cidr_ip,
              fontsize:  options.fontsize,
              fontname:  options.fontname,
              fontcolor: "#003E2F"

            add_route :inbound, from, to, ip_permission
          end

          ip_permission.user_id_group_pairs.each do |user_id_group_pair|
            from = if user_id_group_pair.user_id == security_group.owner_id
              user_id_group_pair.group_id.to_id
            else
              node xaccount_sg(user_id_group_pair).to_id, xaccount_sg(user_id_group_pair)
              xaccount_sg(user_id_group_pair).to_id
            end

            add_route :inbound, from, to, ip_permission
          end
        end

        unless options.inbound_only
          security_group.ip_permissions_egress.each do |ip_permission|
            from = security_group.id.to_id

            ip_permission.ip_ranges.each do |ip_range|
              to = ip_range.cidr_ip.to_id

              node to,
                shape:     "ellipse",
                style:     "filled",
                color:     "#E7FAFF",
                fillcolor: "#E7FAFF",
                label:     ip_range.cidr_ip,
                fontsize:  options.fontsize,
                fontname:  options.fontname,
                fontcolor: "#003E2F"

              add_route :outbound, from, to, ip_permission
            end

            ip_permission.user_id_group_pairs.each do |user_id_group_pair|
              to = if user_id_group_pair.user_id == security_group.owner_id
                user_id_group_pair.group_id.to_id
              else
                node xaccount_sg(user_id_group_pair).to_id, xaccount_sg(user_id_group_pair)
                xaccount_sg(user_id_group_pair).to_id
              end

              add_route :outbound, from, to, ip_permission
            end
          end
        end
      end
    end

    node "0.0.0.0/0".to_id,
      label:       "",
      image:       "#{__dir__}/images/internet.png",
      peripheries: 0,
      fixedsize:   true,
      imagescale:  true,
      shape:       "circle",
      width:       1.67

    save options.output_path, options.format
  end

  private

  def options
    @options
  end

  def aws_configuration
    hash = {}

    [:profile, :access_key_id, :secret_access_key, :region].each do |option|
      hash.update(option => options[option]) if options[option]
    end

    hash.update(region: own_region) if hash[:region].nil?
    hash
  end

  def own_region
    @own_region ||= begin
      require "net/http"

      timeout 3 do
        Net::HTTP.get("169.254.169.254", "/latest/meta-data/placement/availability-zone").chop
      end
    rescue
      nil
    end
  end

  def ec2
    @ec2 ||= Aws::EC2::Resource.new aws_configuration
  end

  # returns Hash like `{"vpc-1111111" => [sg1, sg2, ...], "vpc-11111112" => [sg3, sg4, ...], ...}`
  def vpc_security_groups
    ec2.security_groups.group_by(&:vpc_id).select do |vpc_id|
      if options.vpc_ids
        options.vpc_ids.include? vpc_id
      else
        true
      end
    end
  end

  def xaccount_sg user_id_group_pair
    "#{user_id_group_pair.user_id}/#{user_id_group_pair.group_id}"
  end

  def add_route in_or_out = :inbound, from, to, ip_permission
    id    = :"#{from}_#{to}"
    color = (in_or_out == :inbound ? "#003E2F" : "#045280")

    traffic_map[id] = if traffic_map[id]
      [traffic_map[id], route_label(ip_permission)].join("\\n")
    else
      route_label(ip_permission)
    end

    edge id,
      label:     traffic_map[id],
      style:     "bold",
      arrowhead: (in_or_out == :inbound ? "normal" : "onormal"),
      color:     color,
      fontname:  options.fontname,
      fontsize:  (options.fontsize * 0.75),
      fontcolor: color
  end

  def traffic_map
    @traffic_map ||= {}
  end

  def route_label ip_permission
    if ip_permission.ip_protocol == "-1"
      "All Traffic"
    elsif ip_permission.from_port == ip_permission.to_port
      "#{ip_permission.ip_protocol.upcase}:#{ip_permission.to_port}"
    else
      "#{ip_permission.ip_protocol.upcase}:#{ip_permission.from_port}-#{ip_permission.to_port}"
    end
  end
end
