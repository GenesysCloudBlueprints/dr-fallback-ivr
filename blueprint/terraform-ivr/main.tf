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

resource "genesyscloud_architect_emergencygroup" "site_evac_emergency_group" {
  name        = "Organization Evacuation Emergency Group"
  description = "Emergency Group to activate emergency ivr"
  enabled = var.ivr_emergency_group_enabled
}


resource "genesyscloud_telephony_providers_edges_did_pool" "ivr_phone_number" {
  start_phone_number = "${var.ivr_phone_number}"
  end_phone_number   ="${var.ivr_phone_number}"
  description        = "DID pool for the IVR"
  depends_on = [
    genesyscloud_flow.deploy_ivr_flow
  ]
}

resource "genesyscloud_architect_ivr" "ivr_config" {
  name               = "IVR with emergency group"
  description        = "A sample IVR configuration using an emergency group"
  dnis               = ["${var.ivr_phone_number}","${var.ivr_phone_number}"]
  open_hours_flow_id = genesyscloud_flow.deploy_ivr_flow.id
  depends_on         = [genesyscloud_telephony_providers_edges_did_pool.ivr_phone_number]
}

resource "genesyscloud_routing_queue" "life_insurance_queue" {
  name                              = "Life Insurance"
  description                       = "Life Insurance Queue"
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
}

resource "genesyscloud_routing_queue" "annuity_queue" {
  name                              = "Annuity"
  description                       = "Annuity Queue"
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
}

resource "genesyscloud_routing_queue" "mutual_fund_queue" {
  name                              = "Mutual Funds"
  description                       = "Mutual Funds Queue"
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
}

resource "genesyscloud_routing_queue" "brokerage_queue" {
  name                              = "Brokerage"
  description                       = "Brokerage Queue"
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
}


resource "genesyscloud_routing_queue" "health_insurance_queue" {
  name                              = "Health Insurance"
  description                       = "Health Insurance Queue"
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
}

resource "genesyscloud_flow" "deploy_ivr_flow" {
  depends_on = [
    genesyscloud_routing_queue.life_insurance_queue,
    genesyscloud_routing_queue.annuity_queue,
    genesyscloud_routing_queue.mutual_fund_queue,
    genesyscloud_routing_queue.brokerage_queue,
    genesyscloud_routing_queue.health_insurance_queue,
    genesyscloud_routing_queue.general_help_queue
  ]

    filepath          = "./DR-Emergency-IVR.yaml"
    file_content_hash = filesha256( "./DR-Emergency-IVR.yaml")
    substitutions = {
      ivr_initial_greeting = "${var.ivr_initial_greeting}"
      ivr_failure = "${var.ivr_failure}"
      ivr_callback = "${var.ivr_callback}"
    }
}