AWSTemplateFormatVersion "2010-09-09"

Description <<-EOS.undent
  Sgviz example security group set template (Donburi version).
EOS

Resources do
  Vpc do
    Type "AWS::EC2::VPC"

    Properties do
      CidrBlock "10.0.0.0/16"
    end
  end

  ManageSecurityGroup do
    Type "AWS::EC2::SecurityGroup"

    Properties do
      GroupDescription "Security group for manage role EC2 instances."
      VpcId            {Ref "Vpc"}

      SecurityGroupIngress(
        ["123.45.67.89/32", "234.56.78.90/32", ].product([22, 80, 443]).map do |my_ip, port|
          _{
            CidrIp     my_ip
            IpProtocol "tcp"
            FromPort   port
            ToPort     port
          }
        end
      )

      Tags [
        _{
          Key   "Name"
          Value "manage"
        }
      ]
    end
  end

  AppLoadBalancerSecurityGroup do
    Type "AWS::EC2::SecurityGroup"

    Properties do
      GroupDescription "Security group for application load balancer."
      VpcId            {Ref "Vpc"}

      SecurityGroupIngress(
        [80, 443].map do |port|
          _{
            CidrIp     "0.0.0.0/0"
            IpProtocol "tcp"
            FromPort   port
            ToPort     port
          }
        end
      )

      Tags [
        _{
          Key   "Name"
          Value "app_load_balancer"
        }
      ]
    end
  end

  AppSecurityGroup do
    Type "AWS::EC2::SecurityGroup"

    Properties do
      GroupDescription "Security group for application EC2 instances."
      VpcId            {Ref "Vpc"}

      SecurityGroupIngress [
        _{
          SourceSecurityGroupId {Ref "AppLoadBalancerSecurityGroup"}
          IpProtocol            "tcp"
          FromPort              80
          ToPort                80
        },

        *[22, 10050].map do |port|
          _{
            SourceSecurityGroupId {Ref "ManageSecurityGroup"}
            IpProtocol            "tcp"
            FromPort              port
            ToPort                port
          }
        end
      ]

      Tags [
        _{
          Key   "Name"
          Value "app"
        }
      ]
    end
  end

  RedisSecurityGroup do
    Type "AWS::EC2::SecurityGroup"

    Properties do
      GroupDescription "Security group for ElastiCache Redis clusters."
      VpcId            {Ref "Vpc"}

      SecurityGroupIngress(
        ["Manage", "App"].map do |role|
          _{
            SourceSecurityGroupId {Ref "#{role}SecurityGroup"}
            IpProtocol            "tcp"
            FromPort              6379
            ToPort                6379
          }
        end
      )

      Tags [
        _{
          Key   "Name"
          Value "redis"
        }
      ]
    end
  end

  MysqlSecurityGroup do
    Type "AWS::EC2::SecurityGroup"

    Properties do
      GroupDescription "Security group for RDS MySQL DB instances."
      VpcId            {Ref "Vpc"}

      SecurityGroupIngress(
        ["Manage", "App"].map do |role|
          _{
            SourceSecurityGroupId {Ref "#{role}SecurityGroup"}
            IpProtocol            "tcp"
            FromPort              3306
            ToPort                3306
          }
        end
      )

      Tags [
        _{
          Key   "Name"
          Value "redis"
        }
      ]
    end
  end
end

Outputs do
  Vpc do
    Value do
      Ref "Vpc"
    end
  end
end
