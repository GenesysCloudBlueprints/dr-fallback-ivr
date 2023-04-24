terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
  backend "remote" {
    organization = "thoughtmechanix"

    workspaces {
      prefix = "ivr_"
    }
  }
}

provider "genesyscloud" {

}

data "genesyscloud_user" "admin_user" {
  email = "john.carnell@genesys.com"
}

resource "genesyscloud_routing_queue" "general_help_queue" {
  name                              = "General Help"
  description                       = "General Help Queue"
  acw_wrapup_prompt                 = "MANDATORY_TIMEOUT"
  acw_timeout_ms                    = 300000
  skill_evaluation_method           = "BEST"
  auto_answer_only                  = true
  enable_transcription              = true
  enable_manual_assignment          = true

  media_settings_call {
    alerting_timeout_sec      = 30
    service_level_percentage  = 0.7
    service_level_duration_ms = 10000
  }
  routing_rules {
    operator     = "MEETS_THRESHOLD"
    threshold    = 9
    wait_seconds = 300
  }

   groups= [genesyscloud_group.emergency_group.id]
}

resource "genesyscloud_flow" "deploy_ivr_flow" {
  depends_on = [
    genesyscloud_routing_queue.general_help_queue
  ]

    filepath          = "./DR-Fallback-Ivr.yaml"
    file_content_hash = filesha256( "./DR-Fallback-Ivr.yaml")
    substitutions = {
      ivr_failure = "${var.ivr_failure}"
      ivr_callback = "${var.ivr_callback}"
    }
}


resource "genesyscloud_architect_emergencygroup" "site_evac_emergency_group" {
  name        = "Organization Evacuation Emergency Group"
  description = "Emergency Group to activate emergency ivr"
  enabled = var.ivr_emergency_group_enabled
}


resource "genesyscloud_telephony_providers_edges_did_pool" "ivr_phone_number" {
  start_phone_number = "${var.ivr_phone_number}"
  end_phone_number   ="${var.ivr_phone_number}"
  description        = "DID pool for the  the IVR"
  depends_on = [
    genesyscloud_flow.deploy_ivr_flow
  ]
}


resource "genesyscloud_architect_ivr" "ivr_config" {
  name               = "Configuration IVR"
  description        = "An example fallback IVR"
  dnis               = ["${var.ivr_phone_number}","${var.ivr_phone_number}"]
  open_hours_flow_id = genesyscloud_flow.deploy_ivr_flow.id
  depends_on         = [genesyscloud_telephony_providers_edges_did_pool.ivr_phone_number]
}

resource "genesyscloud_group" "emergency_group" {
  name          = "Emergency Group"
  description   = "Emergency Group for supervisors to answer calls in an emergency"
  type          = "official"
  visibility    = "public"
  member_ids= [data.genesyscloud_user.admin_user.id ]
}


