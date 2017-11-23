####################
# Autoscaling group
####################
data "template_file" "tags" {
  count = "${length(var.tags)}"

  template = <<JSON
    {
      "Key": "$${ key }",
      "Value": "$${ value }",
      "PropagateAtLaunch": $${ propagate_at_launch }
    }
JSON

  vars {
    key                 = "${lookup(var.tags[count.index], "key")}"
    value               = "${lookup(var.tags[count.index], "value")}"
    propagate_at_launch = "${lookup(var.tags[count.index], "propagate_at_launch")}"
  }
}

resource "aws_cloudformation_stack" "autoscaling_group" {
  name       = "${var.name}"
  on_failure = "DELETE"

  template_body = <<EOF
{
  "Resources": {
    "AutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "LaunchConfigurationName": "${var.launch_configuration}",
        "MaxSize": "${var.max_size}",
        "MinSize": "${var.min_size}",
        "MetricsCollection": [
          {
            "Granularity": "${var.metrics_granularity}",
            "Metrics": ${jsonencode(var.enabled_metrics)}
          }
        ],
        "TerminationPolicies": ${jsonencode(var.termination_policies)},
        "VPCZoneIdentifier": ${jsonencode(var.vpc_zone_identifier)},

        "DesiredCapacity": "${var.desired_capacity}",
        "LoadBalancerNames": ${jsonencode(var.load_balancers)},
        "HealthCheckGracePeriod": "${var.health_check_grace_period}",
        "HealthCheckType": "${var.health_check_type}",

        "TargetGroupARNs": ${jsonencode(var.target_group_arns)},
        "Cooldown": "${var.default_cooldown}",
        "TerminationPolicies": ${jsonencode(var.termination_policies)},
        "PlacementGroup": ${var.placement_group != "" ? "${var.placement_group}" : jsonencode(var.no_value) },
        "Tags": [
           ${join(",", data.template_file.tags.*.rendered)}
        ]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "${var.min_size}",
          "MaxBatchSize": "${var.max_batch_size}",
          "PauseTime": "${var.pause_time}",
          "WaitOnResourceSignals": ${var.wait_on_resource_signals ? true : false}
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "The name of the auto scaling group",
      "Value": {
        "Ref": "AutoScalingGroup"
      }
    }
  }
}
EOF
}